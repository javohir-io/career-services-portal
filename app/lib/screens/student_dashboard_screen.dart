import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';
import 'edit_profile_screen.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        final jobs = appState.jobs;

        if (user == null) {
          // Shouldn't normally happen (this tab is behind the logged-in
          // MainNavScreen), but guard against a stale/expired session.
          return const Scaffold(
            body: Center(child: Text('Please log in to view your profile.')),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout, size: 20),
                      tooltip: 'Log out',
                      onPressed: () async {
                        await appState.logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: user),
                        ),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Column(
                    children: [
                      _ProfileAvatar(photoUrl: user.profilePhotoUrl),
                      const SizedBox(height: 14),
                      Text(
                        user.name.isEmpty ? 'Student' : user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.title.isEmpty ? 'Student' : user.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _IconPill(icon: Icons.school_outlined),
                          SizedBox(width: 12),
                          _IconPill(icon: Icons.call_outlined),
                          SizedBox(width: 12),
                          _IconPill(icon: Icons.mail_outline),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.about.isEmpty
                            ? 'Tell companies about yourself — add a short '
                                'bio from Edit Profile.'
                            : user.about,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _InfoField(
                              label: 'University',
                              value: user.university.isEmpty
                                  ? 'Not set'
                                  : user.university,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoField(
                              label: 'Degree Program',
                              value: user.degreeProgram.isEmpty
                                  ? 'Not set'
                                  : user.degreeProgram,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoField(label: 'E-mail', value: user.email),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Internship Opportunities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                if (jobs.isEmpty && appState.jobsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ...jobs.map(
                    (job) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: JobCard(
                        job: job,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JobDetailScreen(jobId: job.id),
                          ),
                        ),
                        onSaveToggle: () => appState.toggleSaved(job.id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  const _IconPill({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Icon(icon, size: 18, color: AppColors.textPrimary),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Text(
            value,
            style:
                const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// The profile photo circle on the Student Dashboard. Tapping it opens
/// the file picker, uploads the chosen image, and updates AppState —
/// self-contained so the parent screen doesn't need extra state for it.
class _ProfileAvatar extends StatefulWidget {
  final String? photoUrl;
  const _ProfileAvatar({required this.photoUrl});

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // works on web, desktop, and mobile alike
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      if (picked.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read the selected image.'),
            ),
          );
        }
        return;
      }

      setState(() => _uploading = true);
      await AppStateScope.of(context).uploadProfilePhoto(
        bytes: picked.bytes!,
        fileName: picked.name,
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = widget.photoUrl != null
        ? '${ApiClient.baseUrl}${widget.photoUrl}'
        : null;

    return GestureDetector(
      onTap: _uploading ? null : _pickAndUpload,
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceGrey,
              border: Border.all(color: AppColors.divider),
              image: fullUrl != null
                  ? DecorationImage(
                      image: NetworkImage(fullUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: fullUrl == null
                ? const Icon(Icons.person, size: 56, color: AppColors.textHint)
                : null,
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              child: _uploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
