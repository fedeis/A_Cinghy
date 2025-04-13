enum FileLocation {
  local,
  oneDrive,
}

class FileInfo {
  final String path;
  final String name;
  final FileLocation location;
  final String? oneDriveId;
  final DateTime? lastModified;

  FileInfo({
    required this.path,
    required this.name,
    required this.location,
    this.oneDriveId,
    this.lastModified,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      path: json['path'] as String,
      name: json['name'] as String,
      location: json['location'] == 'oneDrive' 
          ? FileLocation.oneDrive 
          : FileLocation.local,
      oneDriveId: json['oneDriveId'] as String?,
      lastModified: json['lastModified'] != null 
          ? DateTime.parse(json['lastModified'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'location': location == FileLocation.oneDrive ? 'oneDrive' : 'local',
      'oneDriveId': oneDriveId,
      'lastModified': lastModified?.toIso8601String(),
    };
  }
}