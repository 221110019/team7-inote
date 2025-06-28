import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inote/hive/hive_note_box.dart';
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/hive/hive_task_box.dart';
import 'package:inote/model/user_model.dart';
import '../hive_sync_manager.dart';

extension UserSync on HiveSyncManager {
  Future<void> syncUsers() async {
    final apiUrl = HiveSyncBox.apiUrl;
    final usersBox = HiveAuthBox.box;

    final response =
        await http.get(Uri.parse('$apiUrl/user'), headers: headers());
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final apiUser = UserModel.fromMap(
          Map<String, dynamic>.from((decoded['user'] ?? decoded) as Map));

      final users = Map<String, dynamic>.from(
          usersBox.get(HiveAuthBox.usersKey, defaultValue: {}));

      final localUser = HiveAuthBox.getUser();
      final password = HiveAuthBox.getActiveUserPassword() ?? '';

      if (localUser != null &&
          (localUser.username != apiUser.username || password.isNotEmpty)) {
        final updateData = <String, dynamic>{};
        if (localUser.username != apiUser.username) {
          updateData['name'] = localUser.username;
        }
        if (password.isNotEmpty) {
          updateData['password'] = password;
          updateData['password_confirmation'] = password;
        }

        if (updateData.isNotEmpty) {
          final editRes = await http.put(
            Uri.parse('$apiUrl/user/edit'),
            headers: headers(json: true),
            body: jsonEncode(updateData),
          );

          if (editRes.statusCode == 200) {
            final updatedUser = UserModel.fromMap(
                Map<String, dynamic>.from(jsonDecode(editRes.body)['user']));

            if (localUser.username != updatedUser.username) {
              users.remove(localUser.username);
              await HiveAuthBox.setActiveUsername(updatedUser.username);
            }

            users[updatedUser.username] = updatedUser.toMap();
            await usersBox.put(HiveAuthBox.usersKey, users);
            await HiveAuthBox.setActiveUserEmail(updatedUser.email);
            await HiveAuthBox.setActiveUserPassword('');
          } else {
            print('Failed to EDIT user: ${editRes.body}');
          }
        }
      } else {
        users[apiUser.username] = apiUser.toMap();
        await usersBox.put(HiveAuthBox.usersKey, users);
      }
    } else if (response.statusCode == 401) {
      await HiveSyncBox.setApiToken(null);
      lastError = "Session expired. Please log in again.";
    } else {
      lastError = "Failed to sync user: ${response.statusCode}";
    }
  }

  Future<void> deleteActiveUserOnApi() async {
    final apiUrl = HiveSyncBox.apiUrl;
    final res = await http.delete(
      Uri.parse('$apiUrl/user/delete'),
      headers: headers(),
    );
    if (res.statusCode == 200 || res.statusCode == 204) {
      await HiveAuthBox.deleteActiveUserAndPrivateData();
    } else {
      print('Failed to DELETE user: ${res.body}');
    }
  }

  Future<void> updateUsernameEverywhere(
      String oldUsername, String newUsername) async {
    final notesBox = HiveNoteBox.box;
    for (int i = 0; i < notesBox.length; i++) {
      final note = notesBox.getAt(i);
      if (note is Map && note['by'] == oldUsername) {
        final updatedNote = Map<String, dynamic>.from(note);
        updatedNote['by'] = newUsername;
        notesBox.putAt(i, updatedNote);
      }
    }

    final tasksBox = HiveTaskBox.box;
    for (int i = 0; i < tasksBox.length; i++) {
      final task = tasksBox.getAt(i);
      if (task is Map && task['by'] == oldUsername) {
        final updatedTask = Map<String, dynamic>.from(task);
        updatedTask['by'] = newUsername;
        tasksBox.putAt(i, updatedTask);
      }
    }
  }
}
