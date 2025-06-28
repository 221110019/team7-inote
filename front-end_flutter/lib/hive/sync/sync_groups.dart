import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/hive/hive_group_box.dart';
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/hive/hive_sync_manager.dart';
import 'package:inote/model/group_model.dart';

extension GroupsSync on HiveSyncManager {
  Future<void> syncGroups() async {
    final apiUrl = HiveSyncBox.apiUrl;
    final groupsBox = HiveGroupBox.box;
    final currentUsername = HiveAuthBox.getActiveUsername() ?? 'Guest';

    if (apiUrl.isEmpty) {
      lastError = 'API URL is empty.';
      return;
    }

    List<GroupModel> apiGroups = [];

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/groups'),
        headers: headers(),
      );

      if (response.statusCode == 200) {
        final decoded = _safeJsonDecode(response.body);

        final groupList = decoded is Map && decoded['groups'] is List
            ? decoded['groups']
            : decoded is List
                ? decoded
                : [];

        apiGroups = groupList
            .whereType<Map>()
            .map((e) => GroupModel.fromMap(apiToLocal(e)))
            .toList();
      } else if (response.statusCode == 401) {
        await HiveSyncBox.setApiToken(null);
        lastError = "Session expired. Please log in again.";
        return;
      } else {
        lastError = 'Failed to fetch groups: ${response.statusCode}';
        return;
      }
    } catch (e) {
      lastError = 'Connection error: $e';
      return;
    }

    final localGroups = groupsBox.values
        .map((e) {
          if (e is GroupModel) return e;
          if (e is Map) {
            return GroupModel.fromMap(Map<String, dynamic>.from(e));
          }
          return null;
        })
        .whereType<GroupModel>()
        .toList();

    final apiGroupMap = {
      for (final g in apiGroups)
        if (g.id != null && g.id!.isNotEmpty) g.id!: g,
    };
    for (final apiGroup in apiGroups) {
      if (apiGroup.id == null || apiGroup.id!.isEmpty) continue;

      final localIndex = localGroups.indexWhere((g) => g.id == apiGroup.id);
      if (localIndex == -1) {
        await groupsBox.add(apiGroup.toMap());
      } else {
        await groupsBox.putAt(localIndex, apiGroup.toMap());
      }
    }

    for (int i = 0; i < groupsBox.length; i++) {
      final raw = groupsBox.getAt(i);
      final group = raw is GroupModel
          ? raw
          : GroupModel.fromMap(Map<String, dynamic>.from(raw));

      if ((group.id == null ||
              group.id!.isEmpty ||
              group.id!.startsWith('@temp-')) &&
          group.leader == currentUsername) {
        if (group.id == null || group.id!.isEmpty) {
          final tempId =
              "@temp-${DateTime.now().microsecondsSinceEpoch % 10000}";
          await groupsBox.putAt(
            i,
            group.copyWith(id: tempId).toMap(),
          );
        }

        final postGroup =
            raw is GroupModel ? raw.copyWith(id: group.id) : group;

        final res = await http.post(
          Uri.parse('$apiUrl/groups'),
          headers: headers(json: true),
          body: jsonEncode(localToApi(postGroup)),
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          final decoded = _safeJsonDecode(res.body);
          final groupMap =
              (decoded['group'] ?? decoded) as Map<String, dynamic>?;

          if (groupMap != null) {
            final newGroup = GroupModel.fromMap(apiToLocal(groupMap));

            await groupsBox.putAt(
              i,
              group.copyWith(id: newGroup.id).toMap(),
            );
          }
        }
      } else if (group.id != null &&
          group.id!.isNotEmpty &&
          !group.id!.startsWith("@temp-") &&
          apiGroupMap.containsKey(group.id) &&
          group.leader == currentUsername) {
        await http.put(
          Uri.parse('$apiUrl/groups/${group.id}'),
          headers: headers(json: true),
          body: jsonEncode(localToApi(group)),
        );
      }
    }

    for (final group in localGroups.where((g) =>
        g.isDeleted &&
        g.id != null &&
        g.id!.isNotEmpty &&
        !g.id!.startsWith("@temp-"))) {
      try {
        final res = await http.delete(
          Uri.parse('$apiUrl/groups/${group.id}'),
          headers: headers(),
        );

        if (res.statusCode == 200 || res.statusCode == 204) {
          final idx = localGroups.indexOf(group);
          if (idx != -1) await groupsBox.deleteAt(idx);
        }
      } catch (_) {}
    }
  }

  Map<String, dynamic> apiToLocal(Map e) {
    return {
      'id': e['id']?.toString(),
      'name': e['name'] ?? '',
      'leader': e['leader'] ?? '',
      'entryCode': e['entry_code'] ?? '',
      'isDeleted': e['isDeleted'] ?? false,
      'members': (e['members'] as List<dynamic>? ?? [])
          .map((m) => {
                'id': m['id']?.toString() ?? '',
                'username': m['username']?.toString() ?? '',
              })
          .toList(),
    };
  }

  Map<String, dynamic> localToApi(GroupModel group) {
    return {
      'id': group.id,
      'name': group.name,
      'leader': group.leader,
      'entry_code': group.entryCode,
      'members': group.members
          .map((m) => {
                'id': m.id,
                'username': m.username,
              })
          .toList(),
      'isDeleted': group.isDeleted,
    };
  }

  dynamic _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (e) {
      print('[syncGroups] JSON decode error: $e');
      return {};
    }
  }
}
