import '../models/job.dart';
import 'api_client.dart';

class JobService {
  JobService._();
  static final instance = JobService._();

  final _client = ApiClient.instance;

  Future<List<Job>> fetchJobs({String? search}) async {
    final data = await _client.get('/api/jobs', query: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final jobs = (data['jobs'] as List)
        .map((j) => Job.fromJson(j as Map<String, dynamic>))
        .toList();
    return jobs;
  }

  Future<Job> fetchJobDetail(String id) async {
    final data = await _client.get('/api/jobs/$id');
    return Job.fromJson(data['job'] as Map<String, dynamic>);
  }

  Future<List<Job>> fetchSavedJobs() async {
    final data = await _client.get('/api/jobs/saved');
    final jobs = (data['jobs'] as List)
        .map((j) => Job.fromJson(j as Map<String, dynamic>, isSaved: true))
        .toList();
    return jobs;
  }

  /// Returns the new saved state (true = now saved, false = now unsaved).
  Future<bool> toggleSave(String jobId) async {
    final data = await _client.post('/api/jobs/$jobId/save');
    return data['isSaved'] as bool;
  }
}
