import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/application_service.dart';
import '../theme/app_theme.dart';
import '../widgets/labeled_text_field.dart';
import 'interview_scheduling_screen.dart';

class ResumeSubmissionScreen extends StatefulWidget {
  final String jobId;
  const ResumeSubmissionScreen({super.key, required this.jobId});

  @override
  State<ResumeSubmissionScreen> createState() =>
      _ResumeSubmissionScreenState();
}

class _ResumeSubmissionScreenState extends State<ResumeSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _universityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _skillLevel;
  String? _fileName;
  Uint8List? _fileBytes;
  bool _submitting = false;

  static const _skillLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _universityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true, // Always load bytes — works on web, desktop & mobile
      );
      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.single;
        if (picked.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not read the selected file. Please '
                    'try a different file.'),
              ),
            );
          }
          return;
        }
        setState(() {
          _fileName = picked.name;
          _fileBytes = picked.bytes;
        });
      }
    } catch (e) {
      // Surface the real error instead of a generic message — this is
      // almost always either a MissingPluginException (native plugin
      // not registered — needs `flutter clean` + a full restart after
      // `flutter create .`) or a missing Visual Studio C++ workload on
      // Windows desktop.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skillLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a skill level')),
      );
      return;
    }
    if (_fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your resume')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final application = await ApplicationService.instance.submitApplication(
        jobId: widget.jobId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        university: _universityController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        skillLevel: _skillLevel!,
        resumeBytes: _fileBytes!,
        resumeFileName: _fileName!,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InterviewSchedulingScreen(
            jobId: widget.jobId,
            applicationId: application['id'] as String?,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit application: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit a Resume')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Full Name:',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                LabeledTextFieldRow(
                  left: LabeledTextField(
                    hint: 'First Name',
                    controller: _firstNameController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  right: LabeledTextField(
                    hint: 'Last Name',
                    controller: _lastNameController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Address:',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                LabeledTextField(
                  hint: 'Street Address',
                  controller: _addressController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                LabeledTextFieldRow(
                  left: LabeledTextField(
                    hint: 'City',
                    controller: _cityController,
                  ),
                  right: LabeledTextField(
                    hint: 'University',
                    controller: _universityController,
                  ),
                ),
                const SizedBox(height: 18),
                LabeledTextField(
                  label: 'Phone:',
                  hint: '+(00)00000000000',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 18),
                LabeledTextField(
                  label: 'E-mail:',
                  hint: 'youremail@fakemail.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your e-mail';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid e-mail';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                const Text('Skill Level:',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _skillLevel,
                  hint: const Text('Please Select'),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _skillLevels
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _skillLevel = v),
                ),
                const SizedBox(height: 18),
                const Text('Upload resume:',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _fileName == null
                              ? Icons.upload_file_outlined
                              : Icons.check_circle_outline,
                          size: 36,
                          color: _fileName == null
                              ? AppColors.textSecondary
                              : AppColors.success,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _fileName ?? 'Select file',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Form'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
