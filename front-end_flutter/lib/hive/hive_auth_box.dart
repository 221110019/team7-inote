import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/hive/hive_sync_manager.dart';
import 'package:inote/model/user_model.dart';
import 'package:inote/hive/hive_note_box.dart';
import 'package:inote/hive/hive_task_box.dart';

class HiveAuthBox {
  static const String boxName = 'authBox';
  static const String usersKey = 'users';
  static const String loggedInKey = 'loggedIn';
  static const String activeUserKey = 'activeUser';
  static const String activeUserPasswordKey = 'activeUserPassword';
  static const String activeUserEmailKey = 'activeUserEmail';

  static Future<void> init() async {
    await Hive.openBox(boxName);
    final box = Hive.box(boxName);
    if (box.get(usersKey) == null) {
      await box.put(usersKey, <String, Map>{});
    }
  }

  static Future<bool> register(
      String username, String email, String password) async {
    final box = Hive.box(boxName);
    final users =
        Map<String, dynamic>.from(box.get(usersKey, defaultValue: {}));
    if (users.containsKey(username)) {
      return false;
    }
    final user =
        UserModel(username: username, email: email, password: password);
    users[username] = user.toMap();
    await box.put(usersKey, users);
    await setActiveUsername(username);
    await setActiveUserPassword(password);
    await setActiveUserEmail(email);
    await setLoggedIn(true);
    return true;
  }

  static Future<bool> login(String username, String password) async {
    final box = Hive.box(boxName);
    final users =
        Map<String, dynamic>.from(box.get(usersKey, defaultValue: {}));

    if (users.containsKey(username)) {
      final user = UserModel.fromMap(users[username]);
      if (user.password == password) {
        await setActiveUsername(username);
        await setActiveUserPassword(password);
        await setActiveUserEmail(user.email);
        await setLoggedIn(true);
        return true;
      }
    }

    try {
      final apiUrl = HiveSyncBox.apiUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        headers: {"Accept": "application/json"},
        body: {
          "name": username,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final userMap = Map<String, dynamic>.from(data['user']);

        final user = UserModel.fromMap(userMap);

        users[username] = user.toMap();
        await box.put(usersKey, users);

        await HiveSyncBox.setApiToken(token);
        await setActiveUsername(username);
        await setActiveUserPassword(password);
        await setActiveUserEmail(user.email);
        await setLoggedIn(true);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Login API error: $e");
      return false;
    }
  }

  static Future<void> logout() async {
    final box = Hive.box(boxName);
    await setLoggedIn(false);
    await box.delete(activeUserKey);
    await box.delete(activeUserPasswordKey);
    await box.delete(activeUserEmailKey);
  }

  static Future<void> updateUser(
    UserModel user, {
    String? password,
    String? passwordConfirmation,
  }) async {
    final box = Hive.box(boxName);
    final users =
        Map<String, dynamic>.from(box.get(usersKey, defaultValue: {}));
    final oldUsername = getActiveUsername();
    if (oldUsername == null) return;

    final Map<String, dynamic> body = {
      "name": user.username,
      "email": user.email,
    };

    if (password != null && passwordConfirmation != null) {
      body["old_password"] = getActiveUserPassword();
      body["password"] = password;
      body["password_confirmation"] = passwordConfirmation;
    }

    if (body.isNotEmpty) {
      try {
        final apiUrl = HiveSyncBox.apiUrl;
        final response = await http.put(
          Uri.parse('$apiUrl/user/edit'),
          headers: HiveSyncManager().headers(json: true),
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final updatedUser = UserModel.fromMap(
            Map<String, dynamic>.from(jsonDecode(response.body)['user']),
          );

          if (oldUsername != updatedUser.username) {
            users.remove(oldUsername);
            await setActiveUsername(updatedUser.username);
          }
          users[updatedUser.username] = updatedUser.toMap();
          await box.put(usersKey, users);
          await setActiveUserEmail(updatedUser.email);
          await setActiveUserPassword('');
        } else {
          print(
              'Silent updateUser API error: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        print('Silent updateUser API exception: $e');
      }
    }

    if (oldUsername != user.username) {
      final notesBox = HiveNoteBox.box;
      for (int i = 0; i < notesBox.length; i++) {
        final note = notesBox.getAt(i);
        if (note is Map && note['by'] == oldUsername) {
          final updatedNote = Map<String, dynamic>.from(note);
          updatedNote['by'] = user.username;
          notesBox.putAt(i, updatedNote);
        }
      }
      final tasksBox = HiveTaskBox.box;
      for (int i = 0; i < tasksBox.length; i++) {
        final task = tasksBox.getAt(i);
        if (task is Map && task['by'] == oldUsername) {
          final updatedTask = Map<String, dynamic>.from(task);
          updatedTask['by'] = user.username;
          tasksBox.putAt(i, updatedTask);
        }
      }
      await setActiveUsername(user.username);
      users.remove(oldUsername);
    }

    users[user.username] = user.toMap();
    await box.put(usersKey, users);
  }

  static Future<void> deleteActiveUser() async {
    final box = Hive.box(boxName);
    final username = getActiveUsername();
    if (username == null) return;
    final users =
        Map<String, dynamic>.from(box.get(usersKey, defaultValue: {}));
    users.remove(username);
    await box.put(usersKey, users);
    await logout();
  }

  static Future<void> deleteActiveUserAndPrivateData() async {
    final box = Hive.box(boxName);
    final username = getActiveUsername();
    if (username == null) return;

    final users =
        Map<String, dynamic>.from(box.get(usersKey, defaultValue: {}));
    users.remove(username);
    await box.put(usersKey, users);

    final notesBox = HiveNoteBox.box;
    final notesToDelete = <int>[];
    for (int i = 0; i < notesBox.length; i++) {
      final note = notesBox.getAt(i);
      if (note is Map &&
          note['category'] == 'Private' &&
          note['by'] == username) {
        notesToDelete.add(i);
      }
    }
    for (final i in notesToDelete.reversed) {
      notesBox.deleteAt(i);
    }

    final tasksBox = HiveTaskBox.box;
    final tasksToDelete = <int>[];
    for (int i = 0; i < tasksBox.length; i++) {
      final task = tasksBox.getAt(i);
      if (task is Map &&
          task['category'] == 'Private' &&
          task['by'] == username) {
        tasksToDelete.add(i);
      }
    }
    for (final i in tasksToDelete.reversed) {
      tasksBox.deleteAt(i);
    }

    await logout();
  }

  static Future<void> setLoggedIn(bool value) async {
    final box = Hive.box(boxName);
    await box.put(loggedInKey, value);
  }

  static bool isLoggedIn() {
    final box = Hive.box(boxName);
    return box.get(loggedInKey, defaultValue: false);
  }

  static UserModel? getUser() {
    final box = Hive.box(boxName);
    final username = getActiveUsername();
    if (username == null) return null;
    final users =
        Map<String, dynamic>.from(box.get(usersKey, defaultValue: {}));
    if (users.containsKey(username)) {
      return UserModel.fromMap(users[username]);
    }
    return null;
  }

  static UserModel? getActiveUser() {
    final box = Hive.box(boxName);
    final username = box.get(activeUserKey);
    if (username == null) return null;
    final users =
        Map<String, dynamic>.from(box.get(usersKey, defaultValue: {}));
    if (users.containsKey(username)) {
      return UserModel.fromMap(users[username]);
    }
    return null;
  }

  static Future<void> setActiveUser(UserModel user) async {
    final box = Hive.box(boxName);
    final users =
        Map<String, dynamic>.from(box.get(usersKey, defaultValue: {}));
    users[user.username] = user.toMap();
    await box.put(usersKey, users);
    await box.put(activeUserKey, user.username);
    await box.put(activeUserEmailKey, user.email);
    await box.put(activeUserPasswordKey, user.password);
  }

  static List<UserModel> getAllUsers() {
    final box = Hive.box(boxName);
    final users =
        Map<String, dynamic>.from(box.get(usersKey, defaultValue: {}));
    return users.values.map((e) => UserModel.fromMap(e)).toList();
  }

  static Future<void> setActiveUsername(String username) async {
    final box = Hive.box(boxName);
    await box.put(activeUserKey, username);
  }

  static String? getActiveUsername() {
    final box = Hive.box(boxName);
    return box.get(activeUserKey);
  }

  static Future<void> setActiveUserPassword(String password) async {
    final box = Hive.box(boxName);
    await box.put(activeUserPasswordKey, password);
  }

  static String? getActiveUserPassword() {
    final box = Hive.box(boxName);
    return box.get(activeUserPasswordKey);
  }

  static Future<void> setActiveUserEmail(String email) async {
    final box = Hive.box(boxName);
    await box.put(activeUserEmailKey, email);
  }

  static String? getActiveUserEmail() {
    final box = Hive.box(boxName);
    return box.get(activeUserEmailKey);
  }

  static Box get box => Hive.box(boxName);
}

final localUsers = HiveAuthBox.getAllUsers();
