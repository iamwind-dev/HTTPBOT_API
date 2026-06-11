class OpenApiDirectoryVersion {
  const OpenApiDirectoryVersion({required this.name, required this.specUrl});

  final String name;
  final String specUrl;
}

class OpenApiDirectoryEntry {
  const OpenApiDirectoryEntry({
    required this.apiId,
    required this.title,
    required this.providerLabel,
    required this.description,
    required this.logoUrl,
    required this.versions,
    required this.preferredVersionName,
  });

  final String apiId;
  final String title;
  final String providerLabel;
  final String description;
  final String? logoUrl;
  final List<OpenApiDirectoryVersion> versions;
  final String preferredVersionName;
}
