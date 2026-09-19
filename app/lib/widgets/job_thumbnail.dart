import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_client.dart';
import 'company_logo.dart';

/// Shows a job's real cover image (uploaded via the admin panel) when
/// available, falling back to the colored [CompanyLogo] badge
/// otherwise. Also falls back on a network error (e.g. the image was
/// deleted from disk but the URL is still stored).
class JobThumbnail extends StatelessWidget {
  final Job job;
  final double size;
  final double borderRadius;

  const JobThumbnail({
    super.key,
    required this.job,
    this.size = 48,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (job.imageUrl == null || job.imageUrl!.isEmpty) {
      return CompanyLogo(logoAsset: job.logoAsset, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        '${ApiClient.baseUrl}${job.imageUrl}',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            CompanyLogo(logoAsset: job.logoAsset, size: size),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}
