// domain/entities/user.dart
import 'package:equatable/equatable.dart';

// class User extends Equatable {
//   final String id;
//   final String email;
//   final String name;

//   const User({
//     required this.id,
//     required this.email,
//     required this.name,
//   });

//   @override
//   List<Object> get props => [id, email, name];
// }
class UserEntity extends Equatable{
  final String uid;
  final String? email;
  final String? displayName;
  
  const UserEntity({required this.uid, this.email, this.displayName});
  
  @override
  List<Object?> get props => [uid, email, displayName];
}