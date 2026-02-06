// lib/features/group_chat/presentation/widgets/group_message_input.dart
import 'dart:async';

import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/pusher/pusher_service.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/group_chat/domain/entities/group_chat_message.dart';
import 'package:defcomm/features/group_chat/domain/entities/group_member.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_bloc.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_event.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_state.dart';
import 'package:defcomm/features/group_chat/presentation/models/group_membr_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';


class GroupMessageInput extends StatefulWidget {
  final String groupUserIdEn;            // encrypted group id
  final List<GroupMemberUi> members;     // mentionable members

  const GroupMessageInput({
    super.key,
    required this.groupUserIdEn,
    required this.members,
  });

  @override
  State<GroupMessageInput> createState() => _GroupMessageInputState();
}

class _GroupMessageInputState extends State<GroupMessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // mention suggestions
  bool _showMentionList = false;
  List<GroupMemberUi> _filteredMembers = [];
  final List<String> _selectedTagUserIds = [];

  bool _isTyping = false;
  Timer? _typingTimer;

  PusherService get _pusher => serviceLocator<PusherService>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;

    if (cursor <= 0 || cursor > text.length) {
      setState(() {
        _showMentionList = false;
      });
      return;
    }

    final atIndex = text.lastIndexOf('@', cursor - 1);
    if (atIndex == -1) {
      setState(() => _showMentionList = false);
      return;
    }

    // word after @ up to cursor
    final mentionQuery = text.substring(atIndex + 1, cursor).trim();

    List<GroupMemberUi> filtered;
    if (mentionQuery.isEmpty) {
      filtered = widget.members;
    } else {
      final q = mentionQuery.toLowerCase();
      filtered = widget.members
          .where((m) => m.displayName.toLowerCase().contains(q))
          .toList();
    }

    setState(() {
      _filteredMembers = filtered;
      _showMentionList = filtered.isNotEmpty;
    });
  }

  void _onTextChangedSendTyping(String value) {
    final trimmed = value.trim();

    if (!_isTyping && trimmed.isNotEmpty) {
      _isTyping = true;
      _pusher.sendTypingState(
        toUserId: widget.groupUserIdEn,
        isTyping: true,
      );
    }

    _typingTimer?.cancel();
    if (trimmed.isEmpty) {
      if (_isTyping) {
        _isTyping = false;
        _pusher.sendTypingState(
          toUserId: widget.groupUserIdEn,
          isTyping: false,
        );
      }
    } else {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (_isTyping) {
          _isTyping = false;
          _pusher.sendTypingState(
            toUserId: widget.groupUserIdEn,
            isTyping: false,
          );
        }
      });
    }
  }

  void _insertMention(GroupMemberUi member) {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;

    if (cursor <= 0 || cursor > text.length) return;

    final atIndex = text.lastIndexOf('@', cursor - 1);
    if (atIndex == -1) return;

    final before = text.substring(0, atIndex);
    final after = text.substring(cursor);

    final insert = '@${member.displayName} ';
    final newText = before + insert + after;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: before.length + insert.length,
      ),
    );

    if (!_selectedTagUserIds.contains(member.id)) {
      _selectedTagUserIds.add(member.id);
    }

    setState(() {
      _showMentionList = false;
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<GroupChatBloc>().add(
          GroupMessageSent(
            message: text,
            groupUserIdEn: widget.groupUserIdEn,
            tagUserIds: List<String>.from(_selectedTagUserIds),
          ),
        );

    _controller.clear();
    _selectedTagUserIds.clear();

    setState(() {
      _showMentionList = false;
      _filteredMembers = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showMentionList)
          Flexible(
            child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 180,                 
            ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = _filteredMembers[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        member.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => _insertMention(member),
                    );
                  },
                ),
              ),
            ),
          ),

        Container(
          color: AppColors.tertiaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      border: Border.all(color: Colors.white54, width: 1),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onTextChangedSendTyping,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '   Message...',
                        hintStyle:
                            GoogleFonts.poppins(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xff719709),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.send, color: Colors.white, size: 25),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final GroupChatMessage message;
  const _ReplyPreview({required this.message});

  @override
  Widget build(BuildContext context) {
    final snippet = (message.message ?? '').length > 40
        ? '${message.message!.substring(0, 40)}…'
        : (message.message ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            color: AppColors.primaryGradientStart,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName ?? 'Someone',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  snippet,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white70),
            onPressed: () {
              context.read<GroupChatBloc>().add(GroupReplyCleared());
            },
          ),
        ],
      ),
    );
  }
}
