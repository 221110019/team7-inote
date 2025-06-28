import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/hive/hive_note_box.dart';
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/hive/hive_sync_manager.dart';
import 'package:inote/hive/hive_task_box.dart';
import 'package:inote/hive/sync/sync_notes.dart';
import 'package:inote/hive/sync/sync_tasks.dart';
import 'package:inote/model/note_model.dart';
import 'package:inote/model/task_model.dart';
import 'package:flutter/foundation.dart';

class NoteProvider extends ChangeNotifier {
  List<NoteModel> _notes = [];

  List<NoteModel> get notes => _notes;

  NoteProvider() {
    loadNotes();
  }

  void loadNotes() {
    _notes = HiveNoteBox.box.values
        .where((e) => e is Map)
        .map((e) => NoteModel.fromMap(Map<String, dynamic>.fromEntries(
            (e as Map)
                .entries
                .map((entry) => MapEntry(entry.key.toString(), entry.value)))))
        .toList();
    notifyListeners();
  }

  void addNote(
    String baseTitle,
    String content,
    String category,
    String by,
  ) {
    String title = baseTitle;
    int counter = 2;
    while (_notes.any((note) => note.title == title)) {
      title = "$baseTitle ($counter)";
      counter++;
    }

    final note = NoteModel(
      title: title,
      content: content,
      category: category.isEmpty ? 'Private' : category,
      by: HiveAuthBox.getActiveUsername() ?? 'Guest',
      timestamp: DateTime.now(),
    );

    HiveNoteBox.box.add(note.toMap()).then((_) {
      loadNotes();
    });

    if (HiveSyncBox.apiToken != null && HiveSyncBox.apiToken!.isNotEmpty) {
      HiveSyncManager().syncNotes();
    }
  }

  void deleteNote(int index) async {
    if (index >= 0 && index < _notes.length) {
      final note = _notes[index];
      _notes.removeAt(index);
      HiveNoteBox.box.deleteAt(index).then((_) {
        loadNotes();
      });

      notifyListeners();

      if (note.id != null) {
        try {
          final apiUrl = HiveSyncBox.apiUrl;
          final res = await http.delete(
            Uri.parse('$apiUrl/notes/${note.id}'),
            headers: HiveSyncManager().headers(),
          );
          if (res.statusCode != 200 &&
              res.statusCode != 202 &&
              res.statusCode != 204) {
            print('Silent error DELETE note: ${res.statusCode} ${res.body}');
          }
        } catch (e) {
          print('Silent exception DELETE note: $e');
        }
      } else {
        print('Note has no id yet → cannot delete on server.');
      }
    }
  }

  void editNote(
    int index,
    String newTitle,
    String newContent,
    String category,
    String by,
  ) async {
    if (index >= 0 && index < _notes.length) {
      final oldNote = _notes[index];

      final updatedNote = oldNote.copyWith(
        title: newTitle,
        content: newContent,
        category: category,
        by: HiveAuthBox.getActiveUsername() ?? 'Guest',
        timestamp: DateTime.now(),
      );

      await HiveNoteBox.box.deleteAt(index);
      await HiveNoteBox.box.add(updatedNote.toMap());
      loadNotes();

      if (oldNote.id != null) {
        try {
          final apiUrl = HiveSyncBox.apiUrl;
          final res = await http.put(
            Uri.parse('$apiUrl/notes/${oldNote.id}'),
            headers: HiveSyncManager().headers(json: true),
            body: jsonEncode(updatedNote.toMap()),
          );
          if (res.statusCode != 200 && res.statusCode != 201) {
            print('Silent error PUT note: ${res.statusCode} ${res.body}');
          }
        } catch (e) {
          print('Silent exception PUT note: $e');
        }
      } else {
        print('Note has no id yet → cannot update on server.');
      }
    }
  }
}

class TaskProvider extends ChangeNotifier {
  List<TaskModel> get tasks => HiveTaskBox.box.values
      .where((e) => e is Map)
      .map((e) => TaskModel.fromMap(Map<String, dynamic>.fromEntries(
            (e as Map).entries.map(
                  (entry) => MapEntry(entry.key.toString(), entry.value),
                ),
          )))
      .toList();

  Future<void> addTask(
    String title,
    String category,
    List<ChecklistItemModel> checklist,
    String by,
  ) async {
    final task = TaskModel(
      title: title,
      category: category,
      by: HiveAuthBox.getActiveUsername() ?? 'Guest',
      checklist: checklist,
      timestamp: DateTime.now(),
    );
    HiveTaskBox.box.add(task.toMap());
    notifyListeners();

    await HiveSyncManager().syncTasks();
  }

  Future<void> deleteTask(int index) async {
    if (index >= 0 && index < HiveTaskBox.box.length) {
      final taskMap = HiveTaskBox.box.getAt(index);
      final taskModel =
          taskMap is TaskModel ? taskMap : TaskModel.fromMap(taskMap);

      HiveTaskBox.box.deleteAt(index);
      notifyListeners();

      if (taskModel.id != null) {
        try {
          final apiUrl = HiveSyncBox.apiUrl;
          final res = await http.delete(
            Uri.parse('$apiUrl/tasks/${taskModel.id}'),
            headers: HiveSyncManager().headers(),
          );
          if (res.statusCode != 200 &&
              res.statusCode != 202 &&
              res.statusCode != 204) {
            print('Silent error DELETE task: ${res.statusCode} ${res.body}');
          }
        } catch (e) {
          print('Silent exception DELETE task: $e');
        }
      } else {
        print('Task has no id yet → cannot delete on server.');
      }
    }
  }

  Future<void> editTask(
    int index,
    String newTitle,
    String newCategory,
    List<ChecklistItemModel> newChecklist,
    String by,
  ) async {
    if (index >= 0 && index < HiveTaskBox.box.length) {
      final oldMap = HiveTaskBox.box.getAt(index);
      final oldTask = oldMap is TaskModel ? oldMap : TaskModel.fromMap(oldMap);

      final updatedTask = oldTask.copyWith(
        title: newTitle,
        category: newCategory,
        checklist: newChecklist,
        timestamp: DateTime.now(),
      );

      HiveTaskBox.box.putAt(index, updatedTask.toMap());
      notifyListeners();

      if (oldTask.id != null) {
        try {
          final apiUrl = HiveSyncBox.apiUrl;
          final res = await http.put(
            Uri.parse('$apiUrl/tasks/${oldTask.id}'),
            headers: HiveSyncManager().headers(json: true),
            body: jsonEncode({
              'title': updatedTask.title,
              'category': updatedTask.category,
              'by': updatedTask.by,
              'task_items': updatedTask.checklist
                  .map((c) => Map<String, dynamic>.from(c.toMap()))
                  .toList(),
            }),
          );
          if (res.statusCode == 200 || res.statusCode == 201) {
            final decoded = jsonDecode(res.body);
            final returnedTask = TaskModel.fromMap(
              Map<String, dynamic>.from(
                (decoded['data'] ?? decoded) as Map,
              ),
            );
            HiveTaskBox.box.putAt(index, returnedTask.toMap());
            notifyListeners();
          } else {
            print('Silent error PUT task: ${res.statusCode} ${res.body}');
          }
        } catch (e) {
          print('Silent exception PUT task: $e');
        }
      }
    }
  }

  Future<void> updateTask(int index, TaskModel updatedTask) async {
    HiveTaskBox.box.putAt(index, updatedTask.toMap());
    notifyListeners();

    await HiveSyncManager().syncTasks();
  }
}
