import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/hive/hive_sync_manager.dart';
import 'package:inote/hive/hive_task_box.dart';
import 'package:inote/model/task_model.dart';

extension TasksSync on HiveSyncManager {
  Future<void> syncTasks() async {
    final apiUrl = HiveSyncBox.apiUrl;
    final tasksBox = HiveTaskBox.box;

    final response =
        await http.get(Uri.parse('$apiUrl/tasks'), headers: headers());
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final tasksList = decoded is Map && decoded['data'] is List
          ? decoded['data'] as List
          : decoded is List
              ? decoded
              : <dynamic>[];

      final apiTasks = tasksList
          .map((e) => TaskModel.fromMap(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
          .toList();

      final localTasks = tasksBox.values
          .map((e) => e is TaskModel ? e : TaskModel.fromMap(e))
          .toList();

      for (final apiTask in apiTasks) {
        final localIndex = localTasks.indexWhere((t) => t.id == apiTask.id);

        if (localIndex == -1) {
          await tasksBox.add(apiTask.toMap());
        } else if (apiTask.timestamp
            .isAfter(localTasks[localIndex].timestamp)) {
          await tasksBox.putAt(localIndex, apiTask.toMap());
        }
      }

      for (int i = 0; i < tasksBox.length; i++) {
        final taskMap = tasksBox.getAt(i);
        final taskModel =
            taskMap is TaskModel ? taskMap : TaskModel.fromMap(taskMap);

        if (taskModel.title.isEmpty ||
            taskModel.category.isEmpty ||
            taskModel.by.isEmpty) {
          print(
              "Skipping invalid task with empty fields: ${taskModel.toMap()}");
          continue;
        }

        if (taskModel.id == null) {
          try {
            final res = await http.post(
              Uri.parse('$apiUrl/tasks'),
              headers: headers(json: true),
              body: jsonEncode({
                'title': taskModel.title,
                'category': taskModel.category,
                'by': taskModel.by,
                'task_items':
                    taskModel.checklist.map((c) => c.toMap()).toList(),
              }),
            );

            if (res.statusCode == 200 || res.statusCode == 201) {
              final decoded = jsonDecode(res.body);
              if (decoded is Map && (decoded['data'] ?? decoded) is Map) {
                final returnedTask = TaskModel.fromMap(
                  Map<String, dynamic>.from(
                      (decoded['data'] ?? decoded) as Map),
                );
                final updatedTask = taskModel.copyWith(id: returnedTask.id);
                await tasksBox.putAt(i, updatedTask.toMap());
              }
            } else {
              print(
                  'Failed to POST task (edit case): ${res.statusCode} ${res.body}');
            }
          } catch (e) {
            print('Silent exception POST task (edit case): $e');
          }
        } else {
          try {
            final res = await http.put(
              Uri.parse('$apiUrl/tasks/${taskModel.id}'),
              headers: headers(json: true),
              body: jsonEncode({
                'title': taskModel.title,
                'category': taskModel.category,
                'by': taskModel.by,
                'task_items':
                    taskModel.checklist.map((c) => c.toMap()).toList(),
              }),
            );

            if (res.statusCode == 200 || res.statusCode == 201) {
              print('Task updated successfully on server.');
            } else {
              print('Failed to PUT task: ${res.statusCode} ${res.body}');
            }
          } catch (e) {
            print('Silent exception PUT task: $e');
          }
        }
      }

      final tasksToDelete = localTasks.where((t) => t.isDeleted).toList();

      for (final task in tasksToDelete) {
        if (task.id == null) {
          final index = localTasks.indexOf(task);
          if (index != -1) {
            await tasksBox.deleteAt(index);
          }
          continue;
        }

        try {
          final res = await http.delete(
            Uri.parse('$apiUrl/tasks/${task.id}'),
            headers: headers(),
          );
          if (res.statusCode == 200 ||
              res.statusCode == 202 ||
              res.statusCode == 204) {
            final index = localTasks.indexOf(task);
            if (index != -1) {
              await tasksBox.deleteAt(index);
            }
          } else {
            print('Failed to DELETE task: ${res.statusCode} ${res.body}');
          }
        } catch (e) {
          print('Silent exception DELETE task: $e');
        }
      }
    } else if (response.statusCode == 401) {
      await HiveSyncBox.setApiToken(null);
      lastError = "Session expired. Please log in again.";
    } else {
      lastError =
          "Failed to sync tasks: ${response.statusCode} ${response.body}";
    }
  }
}
