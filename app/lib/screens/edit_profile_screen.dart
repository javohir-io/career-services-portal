import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/labeled_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _universityController;
  late final TextEditingController _degreeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _aboutController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Read from widget.user (passed in via the constructor) rather than
    // AppStateScope.of(context) here — InheritedWidgets aren't safely
    // readable yet inside initState().
    _nameController = TextEditingController(text: widget.user.name);
    _universityController = TextEditingController(text: widget.user.university);
    _degreeController = TextEditingController(text: widget.user.degreeProgram);
    _phoneController = TextEditingController(text: widget.user.phone);
    _aboutController = TextEditingController(text: widget.user.about);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await AppStateScope.of(context).updateProfile(
        name: _nameController.text.trim(),
        university: _universityController.text.trim(),
        degreeProgram: _degreeController.text.trim(),
        phone: _phoneController.text.trim(),
        about: _aboutController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save changes: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledTextField(
                  label: 'Full Name',
                  hint: 'Your name',
                  controller: _nameController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 18),
                LabeledTextField(
                  label: 'University',
                  hint: 'Your university',
                  controller: _universityController,
                ),
                const SizedBox(height: 18),
                LabeledTextField(
                  label: 'Degree Program',
                  hint: 'Your degree program',
                  controller: _degreeController,
                ),
                const SizedBox(height: 18),
                LabeledTextField(
                  label: 'Phone',
                  hint: '+(00)00000000000',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 18),
                LabeledTextField(
                  label: 'About',
                  hint: 'Tell us about yourself',
                  controller: _aboutController,
                  maxLines: 5,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _submitting ? null : _handleSave,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
