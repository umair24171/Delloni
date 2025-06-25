import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String type; // 'individual' or 'company'
  final String email;
  final String phone;
  final String language;
  final bool isEmailVerified;
  final DateTime? createdAt;
  // Company-specific fields
  final String? companyName;
  final String? address;
  final String? registerId;
  final String? profileImage;
  // Location fields
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String? bio;

  UserModel({
    required this.uid,
    required this.type,
    required this.email,
    required this.phone,
    required this.language,
    required this.isEmailVerified,
    this.createdAt,
    this.companyName,
    this.address,
    this.registerId,
    this.profileImage,
    this.latitude,
    this.longitude,
    this.locationAddress,
     this.bio,
  });

  // Factory constructor to create UserModel from Firestore data
  factory UserModel.fromFirestore(
    Map<String, dynamic> userData,
    Map<String, dynamic>? locationData,
  ) {
    return UserModel(
      uid: userData['uid'] ?? '',
      type: userData['type'] ?? '',
      email: userData['email'] ?? '',
      phone: userData['phone'] ?? '',
      language: userData['language'] ?? 'English',
      isEmailVerified: userData['isEmailVerified'] ?? false,
      createdAt: (userData['createdAt'] as Timestamp?)?.toDate(),
      companyName: userData['companyName'],
      address: userData['address'],
      registerId: userData['registerId'],
      profileImage: userData['profileImage'],
      latitude: locationData?['latitude']?.toDouble(),
      longitude: locationData?['longitude']?.toDouble(),
      locationAddress: locationData?['address'],
      bio: userData['bio'],
    );
  }

  // Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'type': type,
      'email': email,
      'phone': phone,
      'language': language,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'companyName': companyName,
      'address': address,
      'registerId': registerId,
      'profileImage': profileImage,
      'bio': bio,
    };
  }

  // CopyWith method for updates
  UserModel copyWith({
    String? uid,
    String? type,
    String? email,
    String? phone,
    String? language,
    bool? isEmailVerified,
    DateTime? createdAt,
    String? companyName,
    String? address,
    String? registerId,
    String? profileImage,
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? bio,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      type: type ?? this.type,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      registerId: registerId ?? this.registerId,
      profileImage: profileImage ?? this.profileImage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
       bio: bio ?? this.bio,
    );
  }
}