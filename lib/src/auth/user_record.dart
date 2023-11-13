import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// 'REDACTED', encoded as a base64 string.
final String _b64Redacted = base64.encode('REDACTED'.codeUnits);

/// User metadata class that provides metadata information like user account
/// creation and last sign in time.
@immutable
class UserMetadata {
  final DateTime? creationTime;
  final DateTime? lastSignInTime;

  const UserMetadata({this.creationTime, this.lastSignInTime});

  UserMetadata.fromJson(Map<String, dynamic> map)
      : this(
          creationTime: map['createdAt'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  int.parse(map['createdAt'])),
          lastSignInTime: map['lastSignInTime'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  int.parse(map['lastSignInTime']),
                ),
        );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'lastSignInTime': lastSignInTime?.toIso8601String(),
      'creationTime': creationTime?.toIso8601String(),
    };
  }

  @override
  bool operator ==(covariant UserMetadata other) {
    if (identical(this, other)) return true;

    return other.creationTime == creationTime &&
        other.lastSignInTime == lastSignInTime;
  }

  @override
  int get hashCode => creationTime.hashCode ^ lastSignInTime.hashCode;

  @override
  String toString() =>
      'UserMetadata(creationTime: $creationTime, lastSignInTime: $lastSignInTime)';
}

/// User info class that provides provider user information for different
/// Firebase providers like google.com, facebook.com, password, etc.
@immutable
class UserInfo {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String providerId;
  final String? phoneNumber;

  const UserInfo({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.providerId,
    this.phoneNumber,
  });

  UserInfo.fromJson(Map<String, dynamic> map)
      : this(
          uid: map['rawId'],
          displayName: map['displayName'],
          email: map['email'],
          photoUrl: map['photoURL'],
          providerId: map['providerId'],
          phoneNumber: map['phoneNumber'],
        );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoUrl,
      'providerId': providerId,
      'phoneNumber': phoneNumber,
    };
  }

  @override
  bool operator ==(covariant UserInfo other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.displayName == displayName &&
        other.email == email &&
        other.photoUrl == photoUrl &&
        other.providerId == providerId &&
        other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        displayName.hashCode ^
        email.hashCode ^
        photoUrl.hashCode ^
        providerId.hashCode ^
        phoneNumber.hashCode;
  }

  @override
  String toString() {
    return 'UserInfo(uid: $uid, displayName: $displayName, email: $email, photoUrl: $photoUrl, providerId: $providerId, phoneNumber: $phoneNumber)';
  }
}

/// User record class that defines the Firebase user object populated from
/// the Firebase Auth getAccountInfo response.
@immutable
class UserRecord {
  final String uid;
  final String? email;
  final bool? emailVerified;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final bool? disabled;
  final UserMetadata? metadata;
  final List<UserInfo>? providerData;
  final String? passwordHash;
  final String? passwordSalt;
  final Map<String, dynamic>? customClaims;
  final String? tenantId;
  final DateTime? tokensValidAfterTime;

  const UserRecord({
    required this.uid,
    this.email,
    this.emailVerified,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.disabled,
    this.metadata,
    this.providerData,
    this.passwordHash,
    this.passwordSalt,
    this.customClaims,
    this.tokensValidAfterTime,
    this.tenantId,
  });

  UserRecord.fromJson(Map<String, dynamic> map)
      : this(
          uid: map['localId'],
          email: map['email'],
          emailVerified: map['emailVerified'] ?? false,
          displayName: map['displayName'],
          photoUrl: map['photoUrl'],
          phoneNumber: map['phoneNumber'],
          // If disabled is not provided, the account is enabled by default.
          disabled: map['disabled'] ?? false,
          metadata: UserMetadata.fromJson(map),
          providerData: (map['providerUserInfo'] as List? ?? [])
              .map((v) => UserInfo.fromJson(v))
              .toList(),
          // If the password hash is redacted (probably due to missing permissions)
          // then clear it out, similar to how the salt is returned. (Otherwise, it
          // *looks* like a b64-encoded hash is present, which is confusing.)
          passwordHash:
              map['passwordHash'] == _b64Redacted ? null : map['passwordHash'],
          passwordSalt: map['passwordSalt'],
          customClaims: (() {
            try {
              return json.decode(map['customAttributes']);
            } catch (e) {
              return null;
            }
          })(),
          tokensValidAfterTime: map['validSince'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  int.parse(map['validSince']) * 1000),
          tenantId: map['tenantId'],
        );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'emailVerified': emailVerified,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'disabled': disabled,
      'metadata': metadata!.toJson(),
      'passwordHash': passwordHash,
      'passwordSalt': passwordSalt,
      'customClaims': customClaims, // TODO deep copy
      'tokensValidAfterTime': tokensValidAfterTime?.toIso8601String(),
      'tenantId': tenantId,
      'providerData': providerData!.map((v) => v.toJson()).toList()
    };
  }

  @override
  bool operator ==(covariant UserRecord other) {
    if (identical(this, other)) return true;
    final collectionEquals = const DeepCollectionEquality().equals;

    return other.uid == uid &&
        other.email == email &&
        other.emailVerified == emailVerified &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.phoneNumber == phoneNumber &&
        other.disabled == disabled &&
        other.metadata == metadata &&
        collectionEquals(other.providerData, providerData) &&
        other.passwordHash == passwordHash &&
        other.passwordSalt == passwordSalt &&
        collectionEquals(other.customClaims, customClaims) &&
        other.tenantId == tenantId &&
        other.tokensValidAfterTime == tokensValidAfterTime;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        emailVerified.hashCode ^
        displayName.hashCode ^
        photoUrl.hashCode ^
        phoneNumber.hashCode ^
        disabled.hashCode ^
        metadata.hashCode ^
        providerData.hashCode ^
        passwordHash.hashCode ^
        passwordSalt.hashCode ^
        customClaims.hashCode ^
        tenantId.hashCode ^
        tokensValidAfterTime.hashCode;
  }

  @override
  String toString() {
    return 'UserRecord(uid: $uid, email: $email, emailVerified: $emailVerified, displayName: $displayName, photoUrl: $photoUrl, phoneNumber: $phoneNumber, disabled: $disabled, metadata: $metadata, providerData: $providerData, passwordHash: $passwordHash, passwordSalt: $passwordSalt, customClaims: $customClaims, tenantId: $tenantId, tokensValidAfterTime: $tokensValidAfterTime)';
  }
}
