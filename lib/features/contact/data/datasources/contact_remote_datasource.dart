import 'package:defcomm/core/constants/base_url.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/error/failures.dart';

abstract class ContactRemoteDataSource {
  Future<void> addContact(String contactId, {String? note});
}

class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  final http.Client client;

  ContactRemoteDataSourceImpl({
    required this.client,
  });

   final box = GetStorage();

  @override
  Future<void> addContact(String contactId, {String? note}) async {
    final token = box.read("accessToken");

    final queryParams = <String, String>{};
    if (note != null && note.isNotEmpty) queryParams['note'] = note;

    final uri = Uri.parse("$baseUrl/user/contact/add/$contactId")
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      throw ServerFailure(
        'Failed to add contact (${response.statusCode}): ${response.body}',
      );
    }
  }
}
