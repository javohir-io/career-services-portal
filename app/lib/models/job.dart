/// A job / internship posting, as returned by the backend's
/// `/api/jobs` endpoints. `isSaved` is populated client-side (see
/// [AppState]) since the public list endpoint doesn't require auth.
class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String logoAsset;
  final List<String> tags;
  final String description;
  final List<String> requirements;
  final String companyAbout;
  final String? imageUrl;
  final bool isSaved;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.logoAsset,
    required this.tags,
    required this.description,
    required this.requirements,
    required this.companyAbout,
    this.imageUrl,
    this.isSaved = false,
  });

  factory Job.fromJson(Map<String, dynamic> json, {bool isSaved = false}) {
    return Job(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      location: json['location'] as String? ?? '',
      logoAsset: json['logoAsset'] as String? ?? 'default',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      description: json['description'] as String? ?? '',
      requirements:
          (json['requirements'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      companyAbout: json['companyAbout'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      isSaved: json['isSaved'] as bool? ?? isSaved,
    );
  }

  Job copyWith({bool? isSaved}) {
    return Job(
      id: id,
      title: title,
      company: company,
      location: location,
      logoAsset: logoAsset,
      tags: tags,
      description: description,
      requirements: requirements,
      companyAbout: companyAbout,
      imageUrl: imageUrl,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
