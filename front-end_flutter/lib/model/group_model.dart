class GroupModel {
  final String? id;
  final String name;
  final String leader;
  final String entryCode;
  final List<GroupMember> members;
  final bool isDeleted;

  GroupModel({
    required this.id,
    required this.name,
    required this.leader,
    required this.entryCode,
    required this.members,
    this.isDeleted = false,
  });

  GroupModel copyWith({
    String? id,
    String? name,
    String? leader,
    String? entryCode,
    List<GroupMember>? members,
    bool? isDeleted,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      leader: leader ?? this.leader,
      entryCode: entryCode ?? this.entryCode,
      members: members ?? this.members,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'leader': leader,
      'entryCode': entryCode,
      'members': members.map((m) => m.toMap()).toList(),
      'isDeleted': isDeleted,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    final leader = map['leader']?.toString() ?? '';

    final membersList = (map['members'] as List<dynamic>? ?? [])
        .map((e) => GroupMember.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final hasLeader = membersList.any((m) => m.username == leader);

    final updatedMembers = hasLeader
        ? membersList
        : [
            ...membersList,
            if (leader.isNotEmpty) GroupMember(id: '', username: leader),
          ];

    return GroupModel(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      leader: leader,
      entryCode:
          map['entryCode']?.toString() ?? map['entry_code']?.toString() ?? '',
      members: updatedMembers,
      isDeleted: map['isDeleted'] == true,
    );
  }
}

class GroupMember {
  final String id;
  final String username;

  GroupMember({
    required this.id,
    required this.username,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id']?.toString() ?? '',
      username: map['username'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
      };
}
