import '../entities/linked_device.dart';
import '../repositories/linked_devices_repository.dart';

class GetLinkedDevices {
  final LinkedDevicesRepository repository;

  GetLinkedDevices(this.repository);

  Future<List<LinkedDevice>> call() {
    return repository.getLinkedDevices();
  }
}
