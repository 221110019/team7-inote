import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inote/hive/hive_sync_box.dart';
import 'sync/sync_notes.dart';
import 'sync/sync_tasks.dart';
import 'sync/sync_groups.dart';
import 'sync/sync_user.dart';

class HiveSyncManager {
  static final HiveSyncManager _instance = HiveSyncManager._internal();
  factory HiveSyncManager() => _instance;
  HiveSyncManager._internal();

  bool isSyncing = false;
  String? lastError;

  String? get token => HiveSyncBox.apiToken ?? '';

  Future<void> syncAll() async {
    if (token == null || token!.isEmpty) {
      lastError = "Token error, please logout then login again";
      return;
    }
    if (isSyncing) return;
    isSyncing = true;
    lastError = null;
    try {
      await syncUsers();
      await syncNotes();
      await syncTasks();
      await syncGroups();
    } catch (e) {
      lastError = e.toString();
    }
    isSyncing = false;
  }

  Map<String, String> headers({bool json = false}) {
    final t = token;
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (t != null && t.isNotEmpty) headers['Authorization'] = 'Bearer $t';
    return headers;
  }

  Future<bool> ensureUserRegisteredAndLoggedIn({
    required String username,
    required String password,
    required String email,
  }) async {
    final apiUrl = HiveSyncBox.apiUrl;
    try {
      final loginResponse = await http.post(
        Uri.parse('$apiUrl/user/login'),
        body: {
          'name': username,
          'password': password,
        },
      );
      if (loginResponse.statusCode == 201) {
        final data = jsonDecode(loginResponse.body);
        final token = data['token'];
        await HiveSyncBox.setApiToken(token);
        return true;
      }

      final registerResponse = await http.post(
        Uri.parse('$apiUrl/user/register'),
        body: {
          'name': username,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );
      if (registerResponse.statusCode == 201) {
        final loginAgain = await http.post(
          Uri.parse('$apiUrl/user/login'),
          body: {
            'name': username,
            'password': password,
          },
        );
        if (loginAgain.statusCode == 201) {
          final data = jsonDecode(loginAgain.body);
          final token = data['token'];
          await HiveSyncBox.setApiToken(token);
          return true;
        }
      }
      lastError = "Registration or login failed.";
      return false;
    } catch (e) {
      print("Silent offline login/register failure: $e");
      return true;
    }
  }
}
