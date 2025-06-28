class UserModel {
  final String username;
  final String email;
  final String password;

  UserModel({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() => {
        'username': username,
        'email': email,
        'password': password,
      };

  factory UserModel.fromMap(Map<dynamic, dynamic> map) => UserModel(
        username: (map['username'] ?? map['name'] ?? '').toString(),
        email: (map['email'] ?? '').toString(),
        password: (map['password'] ?? '').toString(),
      );

  UserModel copyWith({
    String? username,
    String? email,
    String? password,
  }) {
    return UserModel(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}
