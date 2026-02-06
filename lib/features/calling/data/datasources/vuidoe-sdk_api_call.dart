import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:defcomm/core/constants/base_url.dart';


//Auth token we will use to generate a meeting and connect to it

// API call to create meeting
Future<String> createMeeting() async {
final http.Response httpResponse = await http.post(
Uri.parse("https://api.videosdk.live/v2/rooms"),
headers: {'Authorization': videoDevTokenKey},
);

//Destructuring the roomId from the response
return json.decode(httpResponse.body)['roomId'];
}