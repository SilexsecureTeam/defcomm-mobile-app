import 'package:get_storage/get_storage.dart';
import '../models/call_model.dart'; // Import your CallModel

abstract interface class CallsLocalDataSource {
  Future<List<CallModel>> getLocalCalls();
  Future<void> cacheCalls(List<CallModel> calls);
}

class CallsLocalDataSourceImpl implements CallsLocalDataSource {
  final GetStorage box;
  CallsLocalDataSourceImpl(this.box);

  final String _key = 'recent_calls_cache';

  @override
  Future<List<CallModel>> getLocalCalls() async {
    if (!box.hasData(_key)) return [];
    
    final List<dynamic> jsonList = box.read(_key);
    return jsonList
        .map((e) => CallModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheCalls(List<CallModel> calls) async {
    final List<Map<String, dynamic>> jsonList = 
        calls.map((c) => c.toMap()).toList();
    await box.write(_key, jsonList);
  }
}