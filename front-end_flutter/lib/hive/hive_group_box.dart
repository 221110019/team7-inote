import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/hive/hive_sync_manager.dart';
import 'package:inote/hive/sync/sync_groups.dart';
import 'package:inote/model/group_model.dart';

class HiveGroupBox {
  static const String boxName = 'groupsBox';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static Box get box => Hive.box(boxName);

  static List<GroupModel> getGroups() {
    return box.values
        .map((e) {
          if (e is GroupModel) return e;
          if (e is Map) {
            return GroupModel.fromMap(Map<String, dynamic>.from(e));
          }
          return null;
        })
        .whereType<GroupModel>()
        .toList();
  }

  static Future<int> addGroupLocally(GroupModel group) async {
    final index = await box.add(group.toMap());
    return index;
  }

  static Future<void> syncNewGroupToApi(int hiveIndex) async {
    final raw = box.getAt(hiveIndex);
    if (raw == null) return;

    final group = raw is GroupModel
        ? raw
        : GroupModel.fromMap(Map<String, dynamic>.from(raw));

    final apiUrl = HiveSyncBox.apiUrl;

    try {
      final res = await http.post(
        Uri.parse('$apiUrl/groups'),
        headers: HiveSyncManager().headers(json: true),
        body: jsonEncode({
          'name': group.name,
          'entry_code': group.entryCode,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        final groupMap = decoded['group'] ?? decoded;

        final newGroup = GroupModel.fromMap(
          HiveSyncManager().apiToLocal(groupMap),
        );

        await box.putAt(
          hiveIndex,
          newGroup.toMap(),
        );
      } else {
        print('[HiveGroupBox] Failed to sync new group: ${res.body}');
      }
    } catch (e) {
      print('[HiveGroupBox] Exception syncing new group: $e');
    }
  }

  static Future<void> updateGroup(GroupModel group) async {
    final index = box.values.toList().indexWhere((e) {
      final map =
          e is GroupModel ? e.toMap() : Map<String, dynamic>.from(e as Map);
      return map['id']?.toString() == group.id?.toString();
    });

    if (index != -1) {
      await box.putAt(index, group.toMap());
    }

    if (group.id != null && group.id!.isNotEmpty) {
      final apiUrl = HiveSyncBox.apiUrl;
      try {
        final res = await http.put(
          Uri.parse('$apiUrl/groups/${group.id}'),
          headers: HiveSyncManager().headers(json: true),
          body: jsonEncode({
            'name': group.name,
            'entry_code': group.entryCode,
          }),
        );

        if (res.statusCode != 200) {
          print('[HiveGroupBox] Failed to update group on server: ${res.body}');
        }
      } catch (e) {
        print('[HiveGroupBox] Exception updating group: $e');
      }
    } else {
      print('[HiveGroupBox] Skipped server update because ID is missing.');
    }
  }

  static Future<void> deleteGroupAndData(GroupModel group) async {
    final index = box.values.toList().indexWhere((e) {
      final map =
          e is GroupModel ? e.toMap() : Map<String, dynamic>.from(e as Map);
      return map['id']?.toString() == group.id?.toString();
    });

    if (index != -1) {
      await box.deleteAt(index);
    }

    if (group.id != null && group.id!.isNotEmpty) {
      final apiUrl = HiveSyncBox.apiUrl;
      try {
        final res = await http.delete(
          Uri.parse('$apiUrl/groups/${group.id}'),
          headers: HiveSyncManager().headers(),
        );

        if (res.statusCode != 200 && res.statusCode != 204) {
          print('[HiveGroupBox] Failed to delete group on server: ${res.body}');
        }
      } catch (e) {
        print('[HiveGroupBox] Exception deleting group: $e');
      }
    } else {
      print('[HiveGroupBox] Skipped server delete because ID is missing.');
    }
  }

  static Future<void> leaveGroup(GroupModel group, String username) async {
    final members = List<GroupMember>.from(group.members);
    members.removeWhere((m) => m.username == username);

    final updated = group.copyWith(members: members);
    await updateGroup(updated);
  }

  static Future<void> updateGroupByName(
      String name, GroupModel newGroup) async {
    final index = box.values.toList().indexWhere((e) {
      final map =
          e is GroupModel ? e.toMap() : Map<String, dynamic>.from(e as Map);
      return map['name']?.toString() == name;
    });

    if (index != -1) {
      await box.putAt(index, newGroup.toMap());
    }
  }
}
