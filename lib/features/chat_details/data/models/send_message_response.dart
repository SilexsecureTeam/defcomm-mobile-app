// import 'dart:convert';

// class SendMessageResponse {
//   final String status;
//   final String message;
//   final ResponseData data;

//   SendMessageResponse({
//     required this.status,
//     required this.message,
//     required this.data,
//   });

//   // A factory constructor to create a SendMessageResponse from a JSON map
//   factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
//     return SendMessageResponse(
//       status: json['status'] as String,
//       message: json['message'] as String,
//       // The 'data' key in the JSON contains another object, so we parse it using ResponseData.fromJson
//       data: ResponseData.fromJson(json['data'] as Map<String, dynamic>),
//     );
//   }
// }

// // This class represents the nested "data" object in your JSON.
// class ResponseData {
//   final ChatMeta chatMeta;
//   final ChatMessageModel chatMessage; // This is the message model you ultimately want

//   ResponseData({
//     required this.chatMeta,
//     required this.chatMessage,
//   });

//   factory ResponseData.fromJson(Map<String, dynamic> json) {
//     return ResponseData(
//       chatMeta: ChatMeta.fromJson(json['chat_meta'] as Map<String, dynamic>),
//       // The inner 'data' key contains the actual message, so we parse it with ChatMessageModel
//       chatMessage: ChatMessageModel.fromJson(json['data'] as Map<String, dynamic>),
//     );
//   }
// }

// // This class represents the "chat_meta" object.
// class ChatMeta {
//   final String chatUserId;
//   final String chatId;
//   final String chatUserType;

//   ChatMeta({
//     required this.chatUserId,
//     required this.chatId,
//     required this.chatUserType,
//   });

//   factory ChatMeta.fromJson(Map<String, dynamic> json) {
//     return ChatMeta(
//       chatUserId: json['chat_user_id'] as String,
//       chatId: json['chat_id'] as String,
//       chatUserType: json['chat_user_type'] as String,
//     );
//   }
// }


// // This is the ChatMessageModel you want to return from your function.
// // It is based on the structure you provided.
// class ChatMessageModel {
//   final String id;
//   final bool isMyChat;
//   final String senderId;
//   final String recipientId;
//   final String? recipientName;
//   final String? message;
//   final String? createdAt;
//   final bool isFile;
//   final bool isRead;

//   const ChatMessageModel({
//     required this.id,
//     required this.isMyChat,
//     required this.senderId,
//     required this.recipientId,
//     this.recipientName,
//     this.message,
//     this.createdAt,
//     required this.isFile,
//     required this.isRead,
//   });

//   factory ChatMessageModel.fromJson(Map<String, dynamic> map) {
//     // Helper function to safely convert "yes" or "no" strings to a boolean
//     bool isTruthy(String? value) => value?.toLowerCase() == 'yes';

//     return ChatMessageModel(
//       id: map['id'] as String,
//       isMyChat: isTruthy(map['is_my_chat'] as String?),
//       senderId: map['user_id'] as String,
//       recipientId: map['user_to'] as String,
//       recipientName: map['user_to_name'] as String?,
//       message: map['message'] as String?,
//       createdAt: map['created_at'] as String?,
//       isFile: isTruthy(map['is_file'] as String?),
//       isRead: isTruthy(map['is_read'] as String?),
//     );
//   }
// }



import 'package:defcomm/features/chat_details/data/models/chat_messge_model.dart';

// class SendMessageResponseModel {
//   final String status;
//   final String message;
//   final ChatMessageModel chatMessage; // The final object you need

//   SendMessageResponseModel({
//     required this.status,
//     required this.message,
//     required this.chatMessage,
//   });

//   factory SendMessageResponseModel.fromJson(Map<String, dynamic> json) {
//     return SendMessageResponseModel(
//       status: json['status'] as String,
//       message: json['message'] as String,
//       // Here, we perform the correct nested access inside the model
//       chatMessage: ChatMessageModel.fromJson(json['data']['data'] as Map<String, dynamic>),
//     );
//   }
// }

class SendMessageResponseModel {
  final String status;
  final String message;
  final ChatMessageModel chatMessage; // The final object you need

  SendMessageResponseModel({
    required this.status,
    required this.message,
    required this.chatMessage,
  });

  factory SendMessageResponseModel.fromJson(Map<String, dynamic> json) {
    return SendMessageResponseModel(
      status: json['status'] as String,
      message: json['message'] as String,
      chatMessage: ChatMessageModel.fromJson(
        json['data']['data'] as Map<String, dynamic>,
      ),
    );
  }
}
