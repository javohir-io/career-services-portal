import 'package:flutter/material.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import 'job_thumbnail.dart';

/// Card used in the job/internship listing (Student Dashboard &
/// Home/Jobs screens). Tapping opens the Job Detail screen.
class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback? onSaveToggle;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobThumbnail(job: job, size: 48, borderRadius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${job.title} \u2013 ${job.company}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (onSaveToggle != null)
              IconButton(
                onPressed: onSaveToggle,
                icon: Icon(
                  job.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.black,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
