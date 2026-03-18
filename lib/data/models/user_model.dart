class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isAdmin;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.bannerUrl,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] as String,
        email: map['email'] as String,
        displayName: map['displayName'] as String? ?? '',
        avatarUrl: map['avatarUrl'] as String?,
        bannerUrl: map['bannerUrl'] as String?,
        isAdmin: map['isAdmin'] as bool? ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int? ?? 0,
        ),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'bannerUrl': bannerUrl,
        'isAdmin': isAdmin,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? bannerUrl,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bannerUrl: bannerUrl ?? this.bannerUrl,
        isAdmin: isAdmin,
        createdAt: createdAt,
      );
}
