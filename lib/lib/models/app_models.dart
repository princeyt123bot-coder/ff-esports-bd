import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final double walletBalance;
  final String role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.walletBalance,
    required this.role,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      walletBalance: (data['wallet_balance'] ?? 0).toDouble(),
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'wallet_balance': walletBalance,
      'role': role,
    };
  }
}

class TournamentModel {
  final String id;
  final String title;
  final String type;
  final String category;
  final double entryFee;
  final double prizePool;
  final String dateTime;
  final String mapName;
  final int totalSlots;
  final int joinedSlots;
  final String roomId;
  final String roomPass;
  final String status;
  final String thumbnail;
  final List<String> joinedUsers;

  TournamentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.entryFee,
    required this.prizePool,
    required this.dateTime,
    required this.mapName,
    required this.totalSlots,
    required this.joinedSlots,
    required this.roomId,
    required this.roomPass,
    required this.status,
    required this.thumbnail,
    required this.joinedUsers,
  });

  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    return TournamentModel(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'Solo',
      category: data['category'] ?? 'All',
      entryFee: (data['entry_fee'] ?? 0).toDouble(),
      prizePool: (data['prize_pool'] ?? 0).toDouble(),
      dateTime: data['date_time'] ?? '',
      mapName: data['map_name'] ?? 'Bermuda',
      totalSlots: data['total_slots'] ?? 48,
      joinedSlots: data['joined_slots'] ?? 0,
      roomId: data['room_id'] ?? '',
      roomPass: data['room_pass'] ?? '',
      status: data['status'] ?? 'Upcoming',
      thumbnail: data['thumbnail'] ?? '',
      joinedUsers: List<String>.from(data['joined_users'] ?? []),
    );
  }
}
