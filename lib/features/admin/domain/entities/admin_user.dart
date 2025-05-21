class AdminUser {
  final String id;
  final String email;
  final String name;
  final bool isActive;
  final String createdAt;
  
  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });
}
