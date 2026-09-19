import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final saved = appState.savedJobs;
        return Scaffold(
          appBar: AppBar(title: const Text('Saved Internships')),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => appState.loadJobs(),
              child: saved.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.bookmark_border,
                            size: 48, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'No saved internships yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: saved.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final job = saved[index];
                        return JobCard(
                          job: job,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(jobId: job.id),
                            ),
                          ),
                          onSaveToggle: () => appState.toggleSaved(job.id),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
