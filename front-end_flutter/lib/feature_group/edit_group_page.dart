import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/hive/hive_sync_manager.dart';
import 'package:inote/hive/sync/sync_groups.dart';
import 'package:inote/model/group_model.dart';
import 'package:inote/hive/hive_group_box.dart';

class EditGroupPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final Function(GroupModel updatedGroup)? onGroupUpdated;

  const EditGroupPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.onGroupUpdated,
  });

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  late TextEditingController nameController;
  late TextEditingController entryCodeController;
  late String currentUsername;

  GroupModel? group;
  int? groupIdx;

  @override
  void initState() {
    super.initState();

    final allGroups = HiveGroupBox.getGroups();

    groupIdx = allGroups.indexWhere((g) => g.id == widget.groupId);
    group = groupIdx != -1 ? allGroups[groupIdx!] : null;

    nameController =
        TextEditingController(text: group?.name ?? widget.groupName);
    entryCodeController = TextEditingController(text: group?.entryCode ?? '');
    currentUsername = HiveAuthBox.getActiveUsername() ?? '';
  }

  void _showKickConfirmation(GroupMember member) {
    if (group == null ||
        member.username == group!.leader ||
        member.username == currentUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You can't remove the leader or yourself.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Remove Member",
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to remove ${member.username}?",
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
            onPressed: () async {
              if (group?.id != null) {
                try {
                  final res = await http.put(
                    Uri.parse('${HiveSyncBox.apiUrl}/groups/${group!.id}'),
                    headers: HiveSyncManager().headers(json: true),
                    body: jsonEncode({
                      'kick_member_id': member.id,
                    }),
                  );

                  if (res.statusCode == 200 || res.statusCode == 201) {
                    final decoded = jsonDecode(res.body);
                    final groupMap =
                        (decoded['group'] ?? decoded) as Map<String, dynamic>?;

                    if (groupMap != null) {
                      final updatedFromApi = GroupModel.fromMap(
                          HiveSyncManager().apiToLocal(groupMap));
                      await HiveGroupBox.updateGroup(updatedFromApi);

                      if (mounted) {
                        setState(() {
                          group = updatedFromApi;
                        });
                      }
                    }
                  } else {
                    print(
                        "Kick member API failed: ${res.statusCode} ${res.body}");
                  }
                } catch (e) {
                  print("Kick member API error: $e");
                }
              }

              Navigator.pop(context);
            },
            child: Text(
              "Remove",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGroup() async {
    if (group == null || (group?.id?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot update group without ID.")),
      );
      return;
    }

    final updatedGroup = group!.copyWith(
      name: nameController.text.trim(),
      entryCode: entryCodeController.text.trim(),
    );

    await HiveGroupBox.updateGroup(updatedGroup);
    try {
      final res = await http.put(
        Uri.parse('${HiveSyncBox.apiUrl}/groups/${group!.id}'),
        headers: HiveSyncManager().headers(json: true),
        body: jsonEncode(HiveSyncManager().localToApi(updatedGroup)),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        final groupMap = (decoded['group'] ?? decoded) as Map<String, dynamic>?;

        if (groupMap != null) {
          final updatedFromApi =
              GroupModel.fromMap(HiveSyncManager().apiToLocal(groupMap));
          await HiveGroupBox.updateGroup(updatedFromApi);

          setState(() {
            group = updatedFromApi;
          });

          widget.onGroupUpdated?.call(updatedFromApi);
        }
      } else {
        print("Update group API failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("Update group API error: $e");
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Group updated!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = group?.members ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Group",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.indigoAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveGroup,
            tooltip: "Save",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: entryCodeController,
              decoration: InputDecoration(
                labelText: "Entry Code",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Members",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.indigoAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: members.isEmpty
                  ? Center(
                      child: Text(
                        "No members found",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, idx) {
                        final member = members[idx];
                        final isLeader = member.username == group?.leader;
                        final isCurrent = member.username == currentUsername;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            title: Text(
                              member.username.toUpperCase(),
                              style: GoogleFonts.poppins(),
                            ),
                            subtitle: isLeader
                                ? Text(
                                    "Leader",
                                    style: GoogleFonts.poppins(
                                      color: Colors.indigo,
                                    ),
                                  )
                                : isCurrent
                                    ? Text(
                                        "You",
                                        style: GoogleFonts.poppins(
                                          color: Colors.green,
                                        ),
                                      )
                                    : null,
                            trailing: (isLeader || isCurrent)
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      Icons.person_remove,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () =>
                                        _showKickConfirmation(member),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
