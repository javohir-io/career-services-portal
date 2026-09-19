/// The logged-in student's profile, as returned by the backend
/// (`/api/auth/register`, `/api/auth/login`, `/api/auth/me`).
class AppUser {
  final String id;
  final String name;
  final String email;
  final String university;
  final String degreeProgram;
  final String phone;
  final String about;
  final String title;
  final String? profilePhotoUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    required this.degreeProgram,
    required this.phone,
    required this.about,
    required this.title,
    this.profilePhotoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      university: json['university'] as String? ?? '',
      degreeProgram: json['degreeProgram'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      about: json['about'] as String? ?? '',
      title: json['title'] as String? ?? 'Student',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
    );
  }
}
