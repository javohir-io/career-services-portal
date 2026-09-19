import 'api_client.dart';

class ApplicationService {
  ApplicationService._();
  static final instance = ApplicationService._();

  final _client = ApiClient.instance;

  Future<Map<String, dynamic>> submitApplication({
    required String jobId,
    required String firstName,
    required String lastName,
    required String address,
    required String city,
    required String university,
    required String phone,
    required String email,
    required String skillLevel,
    required List<int> resumeBytes,
    required String resumeFileName,
  }) async {
    final data = await _client.postMultipart(
      '/api/applications',
      fields: {
        'jobId': jobId,
        'firstName': firstName,
        'lastName': lastName,
        'address': address,
        'city': city,
        'university': university,
        'phone': phone,
        'email': email,
        'skillLevel': skillLevel,
      },
      fileFieldName: 'resume',
      bytes: resumeBytes,
      fileName: resumeFileName,
    );
    return data['application'] as Map<String, dynamic>;
  }
}
