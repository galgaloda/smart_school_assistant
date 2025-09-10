// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_role.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 100;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      email: fields[1] as String,
      displayName: fields[2] as String,
      role: fields[3] as UserRole,
      permissions: (fields[4] as List).cast<Permission>(),
      createdAt: fields[5] as DateTime?,
      lastLoginAt: fields[6] as DateTime?,
      isActive: fields[7] as bool,
      profileImageUrl: fields[8] as String?,
      metadata: (fields[9] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.permissions)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastLoginAt)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.profileImageUrl)
      ..writeByte(9)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
