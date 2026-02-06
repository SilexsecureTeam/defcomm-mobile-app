import '../entities/linked_device.dart';

abstract class LinkedDevicesRepository {
  Future<List<LinkedDevice>> getLinkedDevices();
}
