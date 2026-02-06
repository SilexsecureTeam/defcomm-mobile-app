import 'package:defcomm/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

import '../bloc/group_call_bloc.dart';

class GroupCallScreen extends StatefulWidget {
  final String groupId;
  final String roomId; 
  final bool isCreator;
  final String groupName;
  final String
  displayName; 
  final bool autoJoin;

  const GroupCallScreen({
    Key? key,
    required this.groupId,
    required this.roomId,
    required this.isCreator,
    required this.groupName,
    required this.displayName,
    this.autoJoin = false, 
  }) : super(key: key);

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends State<GroupCallScreen> {
  late final GroupCallBloc bloc;
  bool _speakerOn = false;
  bool _isRinging = false;
  bool _hasTriggedStartup = false;

  @override
  void initState() {
    super.initState();

     WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bloc.state is! GroupCallInitial) return;

      if (widget.isCreator) {
        _startOrJoinCall(); 
      } else if (widget.autoJoin) {
        _startOrJoinCall();
      } else {
        _startRingtone();
      }
    });
    

    if (!widget.isCreator) {
      // _startRingtone();
    } else {
      
      // bloc.add(StartGroupCallRequested(groupId: widget.groupId, displayName: widget.displayName, meetingId: widget.roomId));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bloc = BlocProvider.of<GroupCallBloc>(context);

   
   
  }

  void _startOrJoinCall() {
    bloc.add(
      StartGroupCallRequested(
        groupId: widget.groupId,
        displayName: widget.displayName,
        meetingId: widget.roomId.isNotEmpty ? widget.roomId : null,
      ),
    );
  }

  void _startRingtone() {
    try {
      FlutterRingtonePlayer().playRingtone(looping: true);
      _isRinging = true;
    } catch (e) {
      debugPrint('Could not start ringtone: $e');
    }
  }

  void _stopRingtone() {
    try {
      FlutterRingtonePlayer().stop();
    } catch (e) {
      debugPrint('Could not stop ringtone: $e');
    } finally {
      _isRinging = false;
    }
  }

  @override
  void dispose() {
    _stopRingtone();
    super.dispose();
  }

  void _onAccept() {
    // stop ringtone
    _stopRingtone();
    _startOrJoinCall();

    // bloc.add(
    //   StartGroupCallRequested(
    //     groupId: widget.groupId,
    //     displayName: widget.displayName,
    //     meetingId: widget.roomId,
    //   ),
    // );
  }

  void _onReject() async {
    _stopRingtone();
    Navigator.of(context).maybePop();
  }

  void _toggleSpeaker() {
    setState(() {
      _speakerOn = !_speakerOn;
    });
  }

  void _toggleMute() {
    bloc.add(ToggleLocalMuteEvent());
  }

  void _leaveCall() {
    bloc.add(GroupCallEndedEvent());
    Navigator.of(context).maybePop();
  }

  Widget _buildParticipantCard(GroupParticipant participant) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blueGrey[700],
              child: Text(
                participant.name.isNotEmpty
                    ? participant.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              participant.name,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  participant.muted ? Icons.mic_off : Icons.mic,
                  color: participant.muted
                      ? Colors.redAccent
                      : Colors.greenAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  participant.muted ? 'Muted' : 'Live',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(GroupCallState state) {
    final isMuted = (state is GroupCallConnected) ? state.isMuted : false;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Mute
          Column(
            children: [
              GestureDetector(
                onTap: _toggleMute,
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: isMuted ? Colors.white : Colors.grey[800],
                  child: Icon(
                    isMuted ? Icons.mic_off : Icons.mic,
                    color: isMuted ? Colors.red : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMuted ? 'Muted' : 'Mute',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),

          // Speaker
          Column(
            children: [
              GestureDetector(
                onTap: _toggleSpeaker,
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: _speakerOn ? Colors.white : Colors.grey[800],
                  child: Icon(
                    Icons.volume_up,
                    color: _speakerOn ? Colors.green : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _speakerOn ? 'Speaker' : 'Loud',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),

          Column(
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Leave call'),
                      content: const Text(
                        'Are you sure you want to leave the call?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _leaveCall();
                          },
                          child: const Text('Leave'),
                        ),
                      ],
                    ),
                  );
                },
                child: const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.call_end, color: Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              const Text('Leave', style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedView(GroupCallState state) {
    final participants = (state is GroupCallConnected)
        ? state.participants
        : <GroupParticipant>[];

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.groupName,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              // show count
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${participants.length} participants',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              itemCount: participants.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, i) {
                final p = participants[i];
                return _buildParticipantCard(p);
              },
            ),
          ),
        ),

        const SizedBox(height: 8),

        _buildBottomControls(state),
      ],
    );
  }

  Widget _buildDialingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          const Text('Connecting...', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Incoming group call',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                widget.groupName,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _onAccept,
                    icon: const Icon(Icons.call),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _onReject,
                    icon: const Icon(Icons.call_end),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tertiaryGreen,
      // appBar: AppBar(
      //   title: Text(widget.groupName),
      //   backgroundColor: AppColors.tertiaryGreen,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.chat_bubble_outline),
      //       onPressed: () => Navigator.of(context).maybePop(),
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.dashboardBackgroundColor,
              ),
            ),

            Column(
              children: [
                _buildAppBar(context),

                Expanded(
                  child: BlocConsumer<GroupCallBloc, GroupCallState>(
                    bloc: bloc,
                    listener: (context, state) {
                      if (state is GroupCallConnected && _isRinging)
                        _stopRingtone();

                      // If call ended remotely, close screen
                      if (state is GroupCallInitial && !_isRinging) {
                        Navigator.of(context).maybePop();
                      }

                      if (state is GroupCallError) {
                        Fluttertoast.showToast(
                          msg: 'Call error: ${state.message}',
                        );
                      }
                    },
                    builder: (context, state) {
                      Widget body;
                      if (state is GroupCallConnecting) {
                        body = SizedBox(
                          child: Center(
                            child: Text("Connecting"),
                          ),
                        );
                      } else if (state is GroupCallConnected) {
                        body = _buildConnectedView(state);
                      } else {
                        // initial or error → show a minimal waiting UI (creator might trigger start)
                        body = Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Waiting...',
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  if (widget.isCreator) {
                                    // start calling - convenience: dispatch start if creator
                                    bloc.add(
                                      StartGroupCallRequested(
                                        groupId: widget.groupId,
                                        displayName: widget.displayName,
                                        meetingId: widget.roomId.isNotEmpty
                                            ? widget.roomId
                                            : null,
                                      ),
                                    );
                                  } else {
                                    // invitee: show accept overlay via _startRingtone (already started in init)
                                     _onAccept(); 
                                    // _startRingtone();
                                  }
                                },
                                child: const Text('Start / Join'),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                child: const Text('Back'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Stack(
                        children: [
                          body,
                          // Show incoming overlay for invitee only while in initial state
                          if (!widget.isCreator &&
                              _isRinging &&
                              (state is GroupCallInitial ||
                                  state is GroupCallConnecting))
                            _buildIncomingOverlay(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const BackButton(color: Colors.white),
              const SizedBox(width: 8),
              Text(widget.groupName),
              const SizedBox(width: 8),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
