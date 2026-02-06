// import 'dart:convert';

// import 'package:defcomm/features/group_chat/domain/usecases/send_group_message.dart';

// abstract class GroupCallRemoteDataSource {
//   Future<void> publishGroupCallControl({required String groupId, required String message});
// }

// class GroupCallRemoteDataSourceImpl implements GroupCallRemoteDataSource {
//   // inject your existing send-message usecase so we don't duplicate HTTP logic
//   final SendGroupMessage sendGroupMessageUseCase; // alias to your existing SendMessage but tailored for group
//   GroupCallRemoteDataSourceImpl(this.sendGroupMessageUseCase);

//   @override
//   Future<void> publishGroupCallControl({required String groupId, required String message}) async {
//     // Use your existing send message use case but with mssType = 'call'
//     await sendGroupMessageUseCase(
//       SendGroupMessageParams(
//         message: message,
//         isFile: false,
//         currentChatUser: groupId, // backend expects group id here
//         mssType: 'call',
//       ),
//     );
//   }
// }



import 'dart:convert';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

abstract class GroupCallRemoteDataSource {
  Future<String> createMeeting();
}

class GroupCallRemoteDataSourceImpl implements GroupCallRemoteDataSource {
  final http.Client client;
  static const String _baseUrl = 'https://api.videosdk.live/v2';

  GroupCallRemoteDataSourceImpl({required this.client,});

  @override
  Future<String> createMeeting() async {
    final uri = Uri.parse('$_baseUrl/rooms');

    final response = await client.post(
      uri,
      headers: {
        'Authorization': videoDevTokenKey, 
        'Content-Type': 'application/json',
      },
    );

    debugPrint('VideoSDK createMeeting group status: ${response.statusCode}');
    debugPrint('VideoSDK createMeeting group body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      final roomId = jsonMap['roomId'] as String?;
      if (roomId == null || roomId.isEmpty) {
        throw Exception('VideoSDK response missing roomId');
      }
      return roomId;
    } else {
      throw Exception('Failed to create meeting. Status: ${response.statusCode}');
    }
  }
}
