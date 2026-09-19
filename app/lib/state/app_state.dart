import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart';

/// App-wide state, now backed by real API calls instead of mock data.
/// Screens listen to this via [AppStateScope] and call its methods to
/// mutate state; [AppState] takes care of calling the right service and
/// notifying listeners once the network call resolves.
class AppState extends ChangeNotifier {
  AppUser? _currentUser;
  List<Job> _jobs = [];
  bool _jobsLoading = false;
  String? _jobsError;
  bool _bootstrapping = true;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  List<Job> get jobs => _jobs;
  List<Job> get savedJobs => _jobs.where((j) => j.isSaved).toList();
  bool get jobsLoading => _jobsLoading;
  String? get jobsError => _jobsError;
  bool get bootstrapping => _bootstrapping;

  /// Call once at app startup: restores a saved session (if any) and
  /// preloads the job list.
  Future<void> bootstrap() async {
    _bootstrapping = true;
    notifyListeners();
    try {
      if (await AuthService.instance.isLoggedIn) {
        _currentUser = await AuthService.instance.fetchMe();
      }
    } catch (_) {
      // Stored token might be expired/invalid; fall back to logged out.
      _currentUser = null;
    }
    await loadJobs();
    _bootstrapping = false;
    notifyListeners();
  }

  Future<void> loadJobs({String? search}) async {
    _jobsLoading = true;
    _jobsError = null;
    notifyListeners();
    try {
      final results = await JobService.instance.fetchJobs(search: search);
      List<String> savedIds = [];
      if (isLoggedIn) {
        try {
          final saved = await JobService.instance.fetchSavedJobs();
          savedIds = saved.map((j) => j.id).toList();
        } catch (_) {
          // Non-fatal: just show jobs as unsaved if this call fails.
        }
      }
      _jobs = results
          .map((j) => j.copyWith(isSaved: savedIds.contains(j.id)))
          .toList();
    } catch (e) {
      _jobsError = e.toString();
    }
    _jobsLoading = false;
    notifyListeners();
  }

  bool isSaved(String jobId) {
    final matches = _jobs.where((j) => j.id == jobId);
    return matches.isNotEmpty && matches.first.isSaved;
  }

  Future<void> toggleSaved(String jobId) async {
    if (!isLoggedIn) return; // Screens should prompt login before calling.
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return;

    final optimistic = !_jobs[index].isSaved;
    _jobs[index] = _jobs[index].copyWith(isSaved: optimistic);
    notifyListeners();

    try {
      final actual = await JobService.instance.toggleSave(jobId);
      _jobs[index] = _jobs[index].copyWith(isSaved: actual);
    } catch (_) {
      // Roll back on failure.
      _jobs[index] = _jobs[index].copyWith(isSaved: !optimistic);
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _currentUser =
        await AuthService.instance.login(email: email, password: password);
    notifyListeners();
    await loadJobs();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? university,
    String? phone,
  }) async {
    _currentUser = await AuthService.instance.register(
      name: name,
      email: email,
      password: password,
      university: university,
      phone: phone,
    );
    notifyListeners();
    await loadJobs();
  }

  Future<void> updateProfile({
    String? name,
    String? university,
    String? degreeProgram,
    String? phone,
    String? about,
  }) async {
    _currentUser = await AuthService.instance.updateProfile(
      name: name,
      university: university,
      degreeProgram: degreeProgram,
      phone: phone,
      about: about,
    );
    notifyListeners();
  }

  Future<void> uploadProfilePhoto({
    required List<int> bytes,
    required String fileName,
  }) async {
    _currentUser = await AuthService.instance.uploadProfilePhoto(
      bytes: bytes,
      fileName: fileName,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _currentUser = null;
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}
