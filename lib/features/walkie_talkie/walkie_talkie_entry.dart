import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:walkie_talkie/screens/channels_screen.dart';
import 'package:walkie_talkie/screens/voice_recording_screen.dart';
import 'package:walkie_talkie/screens/audio_playback_screen.dart';
import 'package:walkie_talkie/screens/encrypted_messages_screen.dart';
import 'package:walkie_talkie/screens/channel_members_screen.dart';
import 'package:walkie_talkie/theme/app_theme.dart';
import 'package:walkie_talkie/services/api_service.dart';

class WalkieTalkieEntry extends StatefulWidget {
  const WalkieTalkieEntry({super.key});

  @override
  State<WalkieTalkieEntry> createState() => _WalkieTalkieEntryState();
}

class _WalkieTalkieEntryState extends State<WalkieTalkieEntry> {
  bool _ready = false;
  bool _authenticated = false;
  final GlobalKey<NavigatorState> _innerNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _bootstrap();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      // 1. Provide DefComm's backend URL to the walkie talkie via dotenv.
      //    dotenv.env is unmodifiable in v5+, so use testLoad to inject values.
      dotenv.testLoad(fileInput: 'API_BASE_URL=$baseUrl\n');

      // 2. Read DefComm's auth session from GetStorage
      final box = GetStorage();
      final token = box.read<String>('accessToken') ?? '';
      final name = box.read<String>('name') ?? '';
      final userEnId = box.read<String>('userEnId') ?? '';

      if (token.isNotEmpty) {
        // Inject directly into walkie talkie's in-memory token store
        AuthService().injectSession(
          accessToken: token,
          userEncrypt: userEnId,
          userName: name,
        );
        _authenticated = true;
      } else {
        // Fallback: try to load walkie talkie's own persisted session
        await AuthService.loadSession();
        _authenticated = AuthService().isAuthenticated;
      }
    } catch (_) {
      _authenticated = false;
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF030603),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8CC63F),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (!_authenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFF030603),
        appBar: AppBar(
          backgroundColor: const Color(0xFF030603),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Session unavailable.\nPlease log in to DefComm first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final inner = _innerNavKey.currentState;
        if (inner != null && inner.canPop()) {
          inner.pop();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: DefaultAssetBundle(
      bundle: _WalkieTalkieBundle(),
      child: MaterialApp(
        navigatorKey: _innerNavKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ChannelsScreen(),
        routes: {
          '/channels': (_) => const ChannelsScreen(),
          '/voice_recording': (_) => const VoiceRecordingScreen(),
          '/voice_recording_active': (_) => const VoiceRecordingScreen(),
          '/audio_playback': (_) => const AudioPlaybackScreen(),
          '/encrypted_messages': (_) => const EncryptedMessagesScreen(),
          '/channel_members': (_) => const ChannelMembersScreen(),
          '/broadcast_list': (ctx) {
            final args =
                ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
            if (args == null) return const SizedBox.shrink();
            final Channel ch;
            if (args['channel'] is Channel) {
              ch = args['channel'] as Channel;
            } else {
              ch = Channel(
                id: args['channelEncrypt']?.toString() ?? '',
                encryptId: args['channelEncrypt']?.toString(),
                name: args['channelName']?.toString() ?? 'Channel',
                accentColor: const Color(0xFF7AAF30),
              );
            }
            return BroadcastsScreen(
              channel: ch,
              channelKey: args['channelKey']?.toString() ??
                  args['channelEncrypt']?.toString() ?? '',
            );
          },
        },
      ),
    ));
  }
}

// Remaps asset paths used inside walkie_talkie code (e.g. "assets/images/x.png")
// to their bundled package path ("packages/walkie_talkie/assets/images/x.png").
class _WalkieTalkieBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    final remapped = (key.startsWith('assets/') || key == '.env')
        ? 'packages/walkie_talkie/$key'
        : key;
    return rootBundle.load(remapped);
  }
}
