import 'dart:convert';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/error/exception.dart';
import 'package:defcomm/features/linked_devices/data/model/linked_device_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

abstract interface class LinkedDevicesLocalDataSource {
  Future<void> cacheDevices(List<LinkedDeviceModel> devices);
  List<LinkedDeviceModel> getLastDevicesSync();
}

class LinkedDevicesLocalDataSourceImpl implements LinkedDevicesLocalDataSource {
  final GetStorage box;
  LinkedDevicesLocalDataSourceImpl(this.box);

  final String _kKey = 'cached_linked_devices';

  @override
  Future<void> cacheDevices(List<LinkedDeviceModel> devices) async {
    final List<Map<String, dynamic>> jsonList = 
        devices.map((e) => e.toMap()).toList();
    
    await box.write(_kKey, jsonList);
  }

  @override
  List<LinkedDeviceModel> getLastDevicesSync() {
    if (!box.hasData(_kKey)) return [];

    final rawData = box.read(_kKey);
    
    if (rawData is List) {
      return rawData
          .map((e) => LinkedDeviceModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}


abstract interface class LinkedDevicesRemoteDataSource {
  Future<List<LinkedDeviceModel>> fetchLinkedDevices();
}

class LinkedDevicesRemoteDataSourceImpl implements LinkedDevicesRemoteDataSource {
  final http.Client client;

  LinkedDevicesRemoteDataSourceImpl(this.client);

  @override
  Future<List<LinkedDeviceModel>> fetchLinkedDevices() async {
    final box = GetStorage();



    final token = box.read("accessToken");
    
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/auth/logindevice/active'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Linked Devices Response: ${response.statusCode}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];

        return data
            .map((item) => LinkedDeviceModel.fromJson(item))
            .toList();
      } else {
        throw ServerException('Failed to fetch linked devices');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}