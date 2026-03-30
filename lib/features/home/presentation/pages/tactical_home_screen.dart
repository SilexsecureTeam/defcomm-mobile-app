import 'dart:async';
import 'dart:convert';
import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/utils/format_call_time_stamp.dart';
import 'package:defcomm/features/recent_calls/domain/usecases/get_local_calls.dart';
import 'package:defcomm/features/recent_calls/domain/usecases/get_recent_calls.dart';
import 'package:defcomm/features/group_calling/presentation/bloc/group_call_events.dart';
import 'package:defcomm/features/groups/presentation/pages/groups_screen.dart';
import 'package:defcomm/features/recent_calls/presentation/cubit/calls_cubit.dart';
import 'package:defcomm/features/recent_calls/presentation/cubit/calls_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/features/walkie_talkie/walkie_talkie_entry.dart';
import 'package:intl/intl.dart';

const _sysChannel = MethodChannel('come.deffcom.chatapp/system_settings');

// ── Design palette ──────────────────────────────────────────────────────────
const _bg           = Color(0xFF0B0E06);
const _cardBg       = Color(0xFF36460A);   // clock card & side pills same bg
const _accentGreen  = Color(0xFF8CC63F);
const _accentBar    = Color(0xFF4A7020);
const _qaBtnBg      = Color(0xFF1D2710);
const _announceBg   = Color(0xFFC8DE7A);
const _announceText = Color(0xFF0B0E06);
const _bottomBarBg  = Color(0xFF111508);
const _dotActive    = Color(0xFF5B8C2A);
const _btnBg        = Color(0xFF1A2010);
const _modalBg      = Color(0xFF0D1106);
const _appIconBg    = Color(0xFF1A2410);

// ── App entries for ALL APPLICATIONS modal ───────────────────────────────────
class _AppEntry {
  final String label;
  final String? asset;
  final IconData? icon;
  final bool installed;
  final int? tabIndex;

  const _AppEntry({
    required this.label,
    this.asset,
    this.icon,
    this.installed = true,
    this.tabIndex,
  });
}

const _apps = [
  _AppEntry(label: 'Messaging',     asset: 'images/Messaging.png',   installed: true,  tabIndex: 1),
  _AppEntry(label: 'Phone',         asset: 'images/phone_call.png',  installed: true,  tabIndex: 2),
  _AppEntry(label: 'Walkie-Talkie', asset: 'images/walkie.png',      installed: true),
  _AppEntry(label: 'File Sharing',  asset: 'images/file_share.png',  installed: true),
  _AppEntry(label: 'Browser',       asset: 'images/Browser.png',     installed: false),
  _AppEntry(label: 'Store',         asset: 'images/store.png',       installed: false),
  _AppEntry(label: 'Drive',         asset: 'images/Drive.png',       installed: true),
  _AppEntry(label: 'Mail',          asset: 'images/Email.png',       installed: true),
];

class TacticalHomeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  const TacticalHomeScreen({super.key, this.onNavigateToTab});

  @override
  State<TacticalHomeScreen> createState() => _TacticalHomeScreenState();
}

class _TacticalHomeScreenState extends State<TacticalHomeScreen> {
  late Timer _timer;
  late CallsCubit _callsCubit;
  String _currentTime = '';
  String _currentDate = '';
  bool _secureMode = true;
  int _missedCallsBadge = 0;
  VoidCallback? _callBadgeSub;
  late final PageController _announcementController;
  int _currentAnnouncementPage = 0;

  List<Map<String, String>> _announcements = [];
  bool _announcementsLoading = true;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _announcementController = PageController();
    _fetchAnnouncements();
    _loadSecureMode();
    _callsCubit = CallsCubit(
      getRecentCalls: serviceLocator<GetRecentCalls>(),
      getLocalCalls:  serviceLocator<GetLocalCalls>(),
    )..load();
    _missedCallsBadge = GetStorage().read<int>('missed_calls_badge') ?? 0;
    _callBadgeSub = GetStorage().listenKey('missed_calls_badge', (val) {
      if (mounted) setState(() => _missedCallsBadge = (val as int?) ?? 0);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _announcementController.dispose();
    _callsCubit.close();
    _callBadgeSub?.call();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEE, dd MMMM yyyy').format(now);
    });
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final token = GetStorage().read<String>('accessToken');
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _announcementsLoading = false);
        return;
      }
      final res = await http.get(
        Uri.parse('$baseUrl/user/notification'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        dynamic raw = body['data'];
        if (raw is Map && raw.containsKey('data')) raw = raw['data'];
        final List items = raw is List ? raw : [];
        if (mounted) {
          setState(() {
            _announcements = items
                .map<Map<String, String>>((item) => {
                      'title': (item['label'] ?? '').toString(),
                      'body': (item['body_message'] ?? item['short_message'] ?? '').toString(),
                    })
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Announcements fetch error: $e');
    } finally {
      if (mounted) setState(() => _announcementsLoading = false);
    }
  }

  void _loadSecureMode() {
    final box = GetStorage();
    setState(() => _secureMode = box.read('secure_mode') ?? true);
  }

  void _toggleSecureMode() {
    final box = GetStorage();
    setState(() {
      _secureMode = !_secureMode;
      box.write('secure_mode', _secureMode);
    });
  }

  // ── Walkie-Talkie entry ────────────────────────────────────────────────
  void _openWalkieTalkie() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalkieTalkieEntry()),
    );
  }

  // ── ALL APPLICATIONS bottom-sheet modal ─────────────────────────────────
  void _showAllApplications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AllAppsSheet(
        onNavigate: widget.onNavigateToTab,
        onOpenWalkieTalkie: _openWalkieTalkie,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // White status bar icons/text so they're visible on the dark background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    return BlocProvider.value(
      value: _callsCubit,
      child: Scaffold(
      backgroundColor: _bg,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Clock + side pills ───────────────────────────────────
                  _buildClockRow(),

                  const SizedBox(height: 20),

                  // ── Secure Communications ────────────────────────────────
                  const Text(
                    'SECURE COMMUNICATIONS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSecureCommsRow(),

                  const SizedBox(height: 16),

                  // ── Recent Calls ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Calls',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.onNavigateToTab?.call(2),
                        child: const Text(
                          'Show All',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Expanded call list — takes all remaining space above
                  // the floating carousel + bottom bar.
                  Expanded(
                    child: BlocBuilder<CallsCubit, CallsState>(
                      builder: (_, state) {
                        if (state.isLoading && state.calls.isEmpty) {
                          return const Center(
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _accentGreen),
                            ),
                          );
                        }
                        final myId =
                            GetStorage().read<String>('userEnId') ?? '';
                        final calls = state.calls;
                        if (calls.isEmpty) {
                          return const Center(
                            child: Text('No recent calls',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 13)),
                          );
                        }
                        final recent = calls.take(4).toList();
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 230),
                          itemCount: recent.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final c = recent[i];
                            final isSender = c.sendUserId == myId;
                            final name = isSender
                                ? (c.receiveUserName?.isNotEmpty == true
                                    ? c.receiveUserName!
                                    : c.receiveUserPhone ?? 'Unknown')
                                : (c.sendUserName.isNotEmpty
                                    ? c.sendUserName
                                    : c.sendUserPhone);
                            return _callRow(
                              name,
                              formatCallFullDate(c.createdAtUtc),
                              isSender: isSender,
                              callState: c.callState,
                            );
                          },
                        );
                      },
                    ),
                  ),

                ],
              ),
            ),
          ),

          // ── Floating announcement carousel ─────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 126,
            child: Material(
              color: Colors.transparent,
              elevation: 10,
              shadowColor: Colors.black54,
              borderRadius: BorderRadius.circular(14),
              child: _buildAnnouncementCard(),
            ),
          ),

          // ── Bottom action bar (floating above nav) ────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 56,
            child: _buildBottomBar(),
          ),
        ],
      ),
      ),
    );
  }

  // ── Clock card + side pill container ────────────────────────────────────
  Widget _buildClockRow() {
    return SizedBox(
      height: 165,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clock card — uniform 28px radius (Figma: 27.86px)
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Thumbprint icon from asset
                      Image.asset(
                        'images/thumpprint_defcom.png',
                        width: 18,
                        height: 18,
                        color: _accentGreen,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'SECURE MODE ACTIVE',
                        style: TextStyle(
                          color: _accentGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 62,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ONE tall pill container — same #36460A bg, 4 dark circles inside
          Container(
            width: 52,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleBtn('images/wifi_defcom.png', isSvg: false,
                    onTap: () => _sysChannel.invokeMethod('openWifi')),
                const SizedBox(height: 3),
                _circleBtn('images/bluetooth defcom.png', isSvg: false,
                    onTap: () => _sysChannel.invokeMethod('openBluetooth')),
                const SizedBox(height: 3),
                _circleBtn('images/settings_defcom.svg', isSvg: true,
                    onTap: () => widget.onNavigateToTab?.call(5)),
                const SizedBox(height: 3),
                _circleBtn('images/camera_defcom.png', isSvg: false,
                    onTap: () => _sysChannel.invokeMethod('openCamera')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(String asset,
      {required bool isSvg, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xFF0D1008),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: isSvg
            ? SvgPicture.asset(asset,
                colorFilter: const ColorFilter.mode(
                    Colors.white, BlendMode.srcIn))
            : Image.asset(asset, color: Colors.white, fit: BoxFit.contain),
      ),
    );
  }

  // ── Secure Communications row ─────────────────────────────────────────────
  Widget _buildSecureCommsRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accent green left bar
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: _accentBar,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          // Messaging
          BlocBuilder<MessagingBloc, MessagingState>(
            builder: (context, state) {
              final total = state.threads.fold(0, (s, t) => s + (t.unRead ?? 0)) +
                  state.groups.fold(0, (s, g) => s + g.unreadCount);
              return _withDot(
                _qaImgBtn('images/Messaging.png', () => widget.onNavigateToTab?.call(1)),
                show: total > 0,
              );
            },
          ),
          const SizedBox(width: 10),
          // Calls
          _withDot(
            _qaImgBtn('images/phone_call.png', () {
              GetStorage().write('missed_calls_badge', 0);
              widget.onNavigateToTab?.call(2);
            }),
            show: _missedCallsBadge > 0,
          ),
          const SizedBox(width: 10),
          // Walkie-talkie
          _qaImgBtn('images/walkie.png', _openWalkieTalkie),
          const SizedBox(width: 10),
          // SecureGroup white pill
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupsScreen()),
                );
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/user.png', width: 20, height: 20,
                        color: Colors.black87),
                    const SizedBox(width: 7),
                    const Text(
                      'SecureGroup',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _withDot(Widget child, {required bool show}) {
    if (!show) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -3,
          right: -3,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0B0E06), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _qaImgBtn(String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _qaBtnBg,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(14),
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }

  // ── Recent call row ───────────────────────────────────────────────────────
  Widget _callRow(
    String name,
    String time, {
    required bool isSender,
    required String callState,
  }) {
    final String state = callState.toLowerCase();
    final bool isMissed = state.contains('miss') ||
        state.contains('reject') ||
        state.contains('no_answer') ||
        state.contains('declined');

    final String iconAsset = isSender
        ? 'images/outgoing_call.png'
        : (isMissed ? 'images/missed_call.png' : 'images/incoming_call.png');

    final Color nameColor =
        (!isSender && isMissed) ? const Color(0xFFE53935) : Colors.white;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF2A3618),
          child: Image.asset('images/user.png', width: 22, height: 22,
              color: Colors.white54),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: nameColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Image.asset(iconAsset, width: 18, height: 18),
      ],
    );
  }

  // ── Announcement card (floating glassmorphism) ───────────────────────────
  Widget _buildAnnouncementCard() {
    final bool showPlaceholder = _announcementsLoading || _announcements.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: _announceBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 82,
            child: showPlaceholder
                ? Center(
                    child: Text(
                      _announcementsLoading
                          ? 'Loading announcements...'
                          : 'No announcements',
                      style: const TextStyle(
                        color: _announceText,
                        fontSize: 12,
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: _announcementController,
                    itemCount: _announcements.length,
                    onPageChanged: (i) =>
                        setState(() => _currentAnnouncementPage = i),
                    itemBuilder: (_, i) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _announcements[i]['title'] ?? '',
                          style: const TextStyle(
                            color: _announceText,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _announcements[i]['body'] ?? '',
                          style: const TextStyle(
                              color: _announceText,
                              fontSize: 11,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_announcements.length, (i) {
              final isActive = i == _currentAnnouncementPage;
              return Padding(
                padding: EdgeInsets.only(
                    right: i < _announcements.length - 1 ? 6.0 : 0.0),
                child: Container(
                  width: isActive ? 22 : 9,
                  height: 9,
                  decoration: isActive
                      ? BoxDecoration(
                          color: _dotActive,
                          borderRadius: BorderRadius.circular(5),
                        )
                      : BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _dotActive, width: 1.5),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Bottom action bar (part of page, not a separate nav) ──────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          // SECURE MODE
          Expanded(
            child: GestureDetector(
              onTap: _toggleSecureMode,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: _btnBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SECURE MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _secureMode
                            ? _accentBar
                            : const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _secureMode
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 14,
                          height: 14,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ALL APPLICATIONS
          Expanded(
            child: GestureDetector(
              onTap: _showAllApplications,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: _btnBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apps_outlined, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'ALL APPLICATIONS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ALL APPLICATIONS modal sheet
// ═══════════════════════════════════════════════════════════════════════════
class _AllAppsSheet extends StatelessWidget {
  final void Function(int)? onNavigate;
  final VoidCallback? onOpenWalkieTalkie;
  const _AllAppsSheet({this.onNavigate, this.onOpenWalkieTalkie});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: _modalBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Text(
              'ALL APPLICATIONS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.75,
                ),
                itemCount: _apps.length,
                itemBuilder: (ctx, i) => _AppTile(
                  entry: _apps[i],
                  onTap: () {
                    if (!_apps[i].installed) {
                      showDialog(
                        context: ctx,
                        builder: (_) =>
                            _ComingSoonDialog(appName: _apps[i].label),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    if (_apps[i].tabIndex != null) {
                      onNavigate?.call(_apps[i].tabIndex!);
                    } else if (_apps[i].label == 'Walkie-Talkie') {
                      onOpenWalkieTalkie?.call();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final _AppEntry entry;
  final VoidCallback onTap;
  const _AppTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool active = entry.installed;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _appIconBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF3A5010)
                        : const Color(0xFF2A3018),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(13),
                child: entry.asset != null
                    ? Image.asset(
                        entry.asset!,
                        fit: BoxFit.contain,
                        color: active ? _accentGreen : Colors.white54,
                      )
                    : Icon(
                        entry.icon,
                        color: active ? _accentGreen : Colors.white54,
                        size: 24,
                      ),
              ),
              // "Coming Soon" badge for uninstalled apps
              if (!active)
                Positioned(
                  bottom: -4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3D0A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _accentGreen.withOpacity(0.4), width: 0.8),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(
                          color: _accentGreen,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMING SOON dialog
// ═══════════════════════════════════════════════════════════════════════════
class _ComingSoonDialog extends StatelessWidget {
  final String appName;
  const _ComingSoonDialog({required this.appName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _modalBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accentGreen.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _appIconBg,
                shape: BoxShape.circle,
                border: Border.all(
                    color: _accentGreen.withOpacity(0.4), width: 1),
              ),
              child: const Icon(Icons.rocket_launch_outlined,
                  color: _accentGreen, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'COMING SOON',
              style: TextStyle(
                color: _accentGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This application is not yet available.\nStay tuned for updates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white54, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _accentBar,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'GOT IT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
