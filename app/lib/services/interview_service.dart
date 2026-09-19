import 'api_client.dart';

class InterviewService {
  InterviewService._();
  static final instance = InterviewService._();

  final _client = ApiClient.instance;

  Future<Map<String, dynamic>> scheduleInterview({
    required String jobId,
    String? applicationId,
    required DateTime date,
    required String timeSlot,
    String? reason,
  }) async {
    final data = await _client.post('/api/interviews', body: {
      'jobId': jobId,
      if (applicationId != null) 'applicationId': applicationId,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return data['interview'] as Map<String, dynamic>;
  }
}
