import 'package:defcomm/features/linked_devices/data/datasources/linked_device_datasource.dart';
import 'package:defcomm/features/linked_devices/data/model/linked_device_model.dart';

import '../../domain/entities/linked_device.dart';
import '../../domain/repositories/linked_devices_repository.dart';
import '../datasources/linked_devices_remote_datasource.dart';



// class LinkedDevicesRepositoryImpl implements LinkedDevicesRepository {
//   final LinkedDevicesRemoteDataSource remote;

//   LinkedDevicesRepositoryImpl(this.remote);

//   @override
//   Future<List<LinkedDevice>> getLinkedDevices() {
//     return remote.fetchLinkedDevices();
//   }
// }


class LinkedDevicesRepositoryImpl implements LinkedDevicesRepository {
  final LinkedDevicesRemoteDataSource remoteDataSource;
  final LinkedDevicesLocalDataSource localDataSource;

  LinkedDevicesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<LinkedDevice>> getLinkedDevices() async {
    try {
      final remoteDevices = await remoteDataSource.fetchLinkedDevices();
      
      await localDataSource.cacheDevices(remoteDevices);

      return remoteDevices;
    } catch (e) {
      rethrow;
    }
  }
}