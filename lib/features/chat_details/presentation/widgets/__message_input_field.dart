import 'dart:async';
import 'dart:io';

import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/pusher/pusher_service.dart';
import 'package:defcomm/core/services/file_picker_service.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_bloc.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_event.dart';
import 'package:defcomm/features/messaging/domain/entities/message_thread.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:defcomm/features/messaging/presentation/bloc/messaging_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageInputField extends StatefulWidget {
  final String chatUserId;
  final String? userName;
  const MessageInputField({
    super.key, required this.chatUserId, this.userName
  });

  @override
  State<MessageInputField> createState() => MessageInputFieldState();
}

class MessageInputFieldState extends State<MessageInputField> {

  final _controller = TextEditingController();
  final _filePickerService = FilePickerService();


  bool _isTyping = false;
  Timer? _typingTimer;

  PusherService get _pusher => serviceLocator<PusherService>();

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final trimmed = value.trim();

    // User started typing
    if (!_isTyping && trimmed.isNotEmpty) {
      _isTyping = true;
      _pusher.sendTypingState(
        toUserId: widget.chatUserId,
        isTyping: true,
      );
    }

    // Reset debounce timer
    _typingTimer?.cancel();
    if (trimmed.isEmpty) {
      // If user cleared text, send "not_typing" immediately
      if (_isTyping) {
        _isTyping = false;
        _pusher.sendTypingState(
          toUserId: widget.chatUserId,
          isTyping: false,
        );
      }
    } else {
      // If still typing, wait 2s after last keypress to send "not_typing"
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (_isTyping) {
          _isTyping = false;
          _pusher.sendTypingState(
            toUserId: widget.chatUserId,
            isTyping: false,
          );
        }
      });
    }
  }
  
  void _sendMessage() {
  final text = _controller.text.trim();
  if (text.isEmpty) return;

  if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      _pusher.sendTypingState(
        toUserId: widget.chatUserId,
        isTyping: false,
      );
    }

  // 1) Dispatch the existing ChatDetail event to actually send the message
  context.read<ChatDetailBloc>().add(
    MessageSent(
      message: text,
      chatUserId: widget.chatUserId,
    ),
  );

  // 2) Optimistically create a minimal MessageThread and notify MessagingBloc
  //    Use a temporary id if you don't have a server thread id yet.
  //    Replace the fields below with whatever your MessageThread entity expects.
  // final optimisticThread = MessageThread(
  //   id: widget.chatUserId, // use chatUserId for now or a composite id like 'me-${widget.chatUserId}'
  //   lastMessage: text, 
  //   chatId: '', 
  //   chatUserToId: '', 
  //   chatUserId: '', 
  //   chatUserToName: widget.userName ??  '', 
  //   isFile: '', 
  //   chatUserType: '', 
  //   imageUrl: 'images/defcomm_logo_1.png',
  // );

// context.read<ChatDetailBloc>().add(
//         // MessageSent(
//         //   message: text,
//         //   chatUserId: widget.chatUserId,
//         // ),
//       );
        // try {
    // context.read<MessagingBloc>().add(NewThreadCreatedEvent(optimisticThread));
  // } catch (e) {
  //   // If MessagingBloc isn't available here for some reason, ignore safely
  //   debugPrint('Failed to notify MessagingBloc: $e');
  // }

  // 3) Clear input and scroll
  _controller.clear();
  // If you have a method to scroll the chat to bottom, call it here:
  // _scrollToBottom();
}


  void _handlePickedFile(File? file) {
    if (file != null) {
      // The file was successfully picked.
      // Now, you would typically add an event to your BLoC to upload this file.
      debugPrint('File picked: ${file.path}');

      // Example of what you would do next:
      // context.read<ChatDetailBloc>().add(
      //   FileMessageSent(
      //     file: file,
      //     chatUserId: widget.chatUserId,
      //     // You might need to determine the file type here
      //   ),
      // );
    } else {
      // User canceled the picker
      debugPrint('No file selected.');
    }
  }
  void _showAttachmentDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.tertiaryGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Wrap( 
              children: <Widget>[
                _buildDialogOption(
                  icon: Icons.description,
                  label: 'Document',
                  onTap: () async { 
                    final file = await _filePickerService.pickDocument();
                    _handlePickedFile(file);
                  },
                ),
                _buildDialogOption(
                  icon: Icons.photo_library,
                  label: 'Image',
                 onTap: () async { 
                    final file = await _filePickerService.pickImageFromGallery();
                    _handlePickedFile(file);
                  },
                ),
                _buildDialogOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  onTap: () async { 
                    final file = await _filePickerService.pickVideoFromGallery();
                    _handlePickedFile(file);
},
                ),
                _buildDialogOption(
                  icon: Icons.headset,
                  label: 'Audio',
                  onTap: () async { 
                    final file = await _filePickerService.pickAudio();
                    _handlePickedFile(file);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.of(context).pop(); 
        onTap(); 
      },
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tertiaryGreen,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                  border: Border.all(color: Colors.white54, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        controller: _controller,
                        onChanged: _onTextChanged,
                        decoration: InputDecoration(
                          hintText: "Message...",
                          hintStyle: GoogleFonts.poppins(color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAttachmentDialog,
                      child: Image.asset("images/upload_file.png")
                      ),
                      SizedBox(width: 10,),

                    GestureDetector(
                      onTap: () {},
                      child: Image.asset("images/get_images.png")
                    ),
                    SizedBox(width: 10,),
                   
                  ],
                ),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xff719709),
                borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight:Radius.circular(20))
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 25),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
