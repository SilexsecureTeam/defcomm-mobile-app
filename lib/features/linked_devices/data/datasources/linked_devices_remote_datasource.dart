// // data/datasources/linked_devices_remote_datasource.dart
// import 'dart:convert';
// import 'package:defcomm/core/constants/base_url.dart';
// import 'package:defcomm/features/linked_devices/data/model/linked_device_model.dart';
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;

// abstract class LinkedDevicesRemoteDataSource {
//   Future<List<LinkedDeviceModel>> fetchLinkedDevices();
// }

// class LinkedDevicesRemoteDataSourceImpl
//     implements LinkedDevicesRemoteDataSource {
//   final http.Client client;

//   LinkedDevicesRemoteDataSourceImpl({required this.client});

//   @override
//   Future<List<LinkedDeviceModel>> fetchLinkedDevices() async {
//     final box = GetStorage();
//     final token = box.read("accessToken");
//     final res = await client.get(
//       Uri.parse('$baseUrl/auth/logindevice/active'),
//       headers: {'Authorization': 'Bearer $token'},
//     );

//     debugPrint("Linked devices active: ${res.body}");

//     if (res.statusCode != 200) {
//       throw Exception('Failed to fetch linked devices');
//     }

//     final Map<String, dynamic> responseMap = jsonDecode(res.body);
//     final List dataList = responseMap['data'] ?? []; 

//     return dataList.map((e) => LinkedDeviceModel.fromJson(e)).toList();
//   }
// }
