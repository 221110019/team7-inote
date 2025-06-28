import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:inote/feature_group/edit_group_page.dart';
import 'package:inote/feature_group/group_area.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/hive/hive_group_box.dart';
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/hive/hive_sync_manager.dart';
import 'package:inote/hive/sync/sync_groups.dart';
import 'package:inote/model/group_model.dart';

class MainGroup extends StatefulWidget {
  const MainGroup({super.key});

  @override
  State<MainGroup> createState() => _MainGroupState();
}

class _MainGroupState extends State<MainGroup> {
  List<GroupModel> ownedGroups = [];
  List<GroupModel> joinedGroups = [];

  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _reloadGroups();
  }

  void _reloadGroups() {
    final allGroups = HiveGroupBox.getGroups();
    final username = HiveAuthBox.getActiveUsername() ?? 'Guest';

    setState(() {
      ownedGroups =
          allGroups.where((g) => g.leader == username && !g.isDeleted).toList();
      joinedGroups = allGroups
          .where((g) =>
              g.members.any((m) => m.username == username) &&
              g.leader != username &&
              !g.isDeleted)
          .toList();
    });
  }

  Future<void> _handleCreateGroup(String name, String entryCode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final username = HiveAuthBox.getActiveUsername() ?? 'Guest';

      final tempId = "@temp-${DateTime.now().millisecondsSinceEpoch % 10000}";

      final newGroup = GroupModel(
        id: tempId,
        name: name,
        leader: username,
        entryCode: entryCode,
        members: [
          GroupMember(id: '', username: username),
        ],
      );

      await HiveGroupBox.addGroupLocally(newGroup);

      _reloadGroups();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group created locally! Syncing...")),
      );

      final res = await http.post(
        Uri.parse('${HiveSyncBox.apiUrl}/groups'),
        headers: HiveSyncManager().headers(json: true),
        body: jsonEncode(HiveSyncManager().localToApi(newGroup)),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        Map<String, dynamic>? groupMap;
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('group') && decoded['group'] is Map) {
            groupMap = Map<String, dynamic>.from(decoded['group']);
          } else {
            groupMap = decoded;
          }
        }

        if (groupMap != null) {
          final groupFromApi =
              GroupModel.fromMap(HiveSyncManager().apiToLocal(groupMap));

          final groupsBox = HiveGroupBox.box;
          final index = groupsBox.values.toList().indexWhere(
            (g) {
              final group = g is GroupModel
                  ? g
                  : GroupModel.fromMap(Map<String, dynamic>.from(g));
              return group.id == tempId;
            },
          );

          if (index != -1) {
            await groupsBox.putAt(
              index,
              groupFromApi.toMap(),
            );
          }
        } else {
          print("Server responded with no group data.");
        }
      } else {
        print(
            "Failed to create group on server. Status: ${res.statusCode}. Body: ${res.body}");
      }

      await HiveSyncManager().syncGroups();

      _reloadGroups();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group synced successfully!")),
      );
    } catch (e) {
      print("Create group error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating group.\n$e")),
      );
    } finally {
      Navigator.pop(context);
    }
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final entryCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Create Group",
          style: GoogleFonts.poppins(
            color: Colors.indigoAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: entryCodeController,
              decoration: InputDecoration(
                labelText: "Entry Code",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final name = nameController.text.trim();
              final entryCode = entryCodeController.text.trim();

              if (name.isEmpty || entryCode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Name and code are required.")),
                );
                return;
              }

              Navigator.pop(context);
              _handleCreateGroup(name, entryCode);
            },
            child: Text(
              "Create Group",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    final groupIdController = TextEditingController();
    final entryCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Join Group",
          style: GoogleFonts.poppins(
            color: Colors.indigoAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: groupIdController,
              decoration: InputDecoration(
                labelText: "Group ID (optional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: entryCodeController,
              decoration: InputDecoration(
                labelText: "Entry Code",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final idOrName = groupIdController.text.trim();
              final entryCode = entryCodeController.text.trim();
              final username = HiveAuthBox.getActiveUsername() ?? 'Guest';
              final groups = HiveGroupBox.getGroups();

              GroupModel? group;

              if (idOrName.isNotEmpty) {
                final matches = groups
                    .where(
                      (g) =>
                          g.id == idOrName ||
                          g.name.toLowerCase() == idOrName.toLowerCase(),
                    )
                    .toList();

                group = matches.isNotEmpty ? matches.first : null;
              }

              if (group == null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Group not found.")),
                );
                return;
              }

              if (group.entryCode != entryCode) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid entry code.")),
                );
                return;
              }

              if (group.members.any((m) => m.username == username)) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Already a member.")),
                );
                return;
              }

              Navigator.pop(context);

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  title: Text(
                    "Join Group",
                    style: GoogleFonts.poppins(
                      color: Colors.indigoAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    "Are you sure you want to join the group \"${group!.name}\"?",
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: GoogleFonts.poppins()),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final updatedGroup = group!.copyWith(
                          members: [
                            ...group.members,
                            GroupMember(id: '', username: username),
                          ],
                        );

                        await HiveGroupBox.updateGroup(updatedGroup);
                        await HiveSyncManager().syncGroups();
                        _reloadGroups();

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text("You have joined \"${group.name}\".")),
                        );
                      },
                      child: Text(
                        "Join",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              "Join Group",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Delete Group",
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this group?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child:
                Text("Delete", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Leave Group",
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to leave this group?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child:
                Text("Leave", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(GroupModel group, {required bool owned}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "${group.name} (ID: ${group.id})",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "Leader: ${group.leader}\nEntry Code: ${group.entryCode}",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupArea(
                members: group.members,
                groupId: group.id ?? '',
                groupName: group.name,
              ),
            ),
          );
        },
        trailing: owned
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.indigoAccent),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditGroupPage(
                            groupId: group.id!,
                            groupName: group.name,
                            onGroupUpdated: (updatedGroup) async {
                              await HiveGroupBox.updateGroup(updatedGroup);
                              await HiveSyncManager().syncGroups();
                              setState(() {});
                            },
                          ),
                        ),
                      );
                      _reloadGroups();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      _showDeleteConfirmation(() async {
                        if (group.id != null && group.id!.isNotEmpty) {
                          try {
                            final res = await http.delete(
                              Uri.parse(
                                  '${HiveSyncBox.apiUrl}/groups/${group.id}'),
                              headers: HiveSyncManager().headers(),
                            );

                            if (res.statusCode == 200 ||
                                res.statusCode == 204) {
                            } else {
                              print(
                                  "Delete group API failed: ${res.statusCode} ${res.body}");
                            }
                          } catch (e) {
                            print("Delete group API error: $e");
                          }
                        } else {
                          print("Group has no id → only deleting locally.");
                        }

                        await HiveGroupBox.deleteGroupAndData(group);
                        await HiveSyncManager().syncGroups();
                        _reloadGroups();
                      });
                    },
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                onPressed: () {
                  _showLeaveConfirmation(() async {
                    final username = HiveAuthBox.getActiveUsername() ?? 'Guest';
                    await HiveGroupBox.leaveGroup(group, username);
                    await HiveSyncManager().syncGroups();
                    _reloadGroups();
                  });
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOwnedGroups = ownedGroups
        .where((g) => g.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    final filteredJoinedGroups = joinedGroups
        .where((g) => g.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search group by name",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              style: GoogleFonts.poppins(),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.group_add, color: Colors.white),
                    label: Text(
                      "Join Group",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _showJoinGroupDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.create_new_folder,
                        color: Colors.white),
                    label: Text(
                      "Create Group",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _showCreateGroupDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Owned Group(s)",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.indigoAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredOwnedGroups.isEmpty
                  ? Center(
                      child: Text(
                        "No Group found",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredOwnedGroups.length,
                      itemBuilder: (context, i) =>
                          _buildGroupTile(filteredOwnedGroups[i], owned: true),
                    ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Joined Group(s)",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.indigoAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredJoinedGroups.isEmpty
                  ? Center(
                      child: Text(
                        "No Group found",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredJoinedGroups.length,
                      itemBuilder: (context, i) => _buildGroupTile(
                          filteredJoinedGroups[i],
                          owned: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
