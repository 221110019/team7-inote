import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/hive/hive_note_box.dart';
import 'package:inote/model/note_model.dart';
import '../hive_sync_manager.dart';

extension NotesSync on HiveSyncManager {
  Future<void> syncNotes() async {
    final apiUrl = HiveSyncBox.apiUrl;
    final notesBox = HiveNoteBox.box;

    final response =
        await http.get(Uri.parse('$apiUrl/notes'), headers: headers());
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final notesList = decoded is Map && decoded['data'] is List
          ? decoded['data'] as List
          : decoded is List
              ? decoded
              : <dynamic>[];

      final apiNotes = notesList
          .map((e) => NoteModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      final apiNotesById = {
        for (var n in apiNotes)
          if (n.id != null) n.id: n,
      };

      final localNotes = notesBox.values
          .map((e) => e is NoteModel ? e : NoteModel.fromMap(e))
          .toList();

      for (final apiNote in apiNotes) {
        int localIndex = localNotes.indexWhere((n) => n.id == apiNote.id);

        if (localIndex == -1) {
          localIndex = localNotes.indexWhere(
            (n) =>
                n.id == null &&
                n.title == apiNote.title &&
                n.content == apiNote.content &&
                n.by == apiNote.by,
          );
        }

        if (localIndex == -1) {
          await notesBox.add(apiNote.toMap());
        } else {
          if (apiNote.timestamp.isAfter(localNotes[localIndex].timestamp)) {
            await notesBox.putAt(localIndex, apiNote.toMap());
          } else {
            if (localNotes[localIndex].id == null && apiNote.id != null) {
              final updatedNote =
                  localNotes[localIndex].copyWith(id: apiNote.id);
              await notesBox.putAt(localIndex, updatedNote.toMap());
            }
          }
        }
      }

      for (int i = 0; i < notesBox.length; i++) {
        final noteMap = notesBox.getAt(i);
        final noteModel =
            noteMap is NoteModel ? noteMap : NoteModel.fromMap(noteMap);

        if (noteModel.id == null) {
          try {
            final res = await http.post(
              Uri.parse('$apiUrl/notes'),
              headers: headers(json: true),
              body: jsonEncode(noteModel.toMap()),
            );
            if (res.statusCode == 200 || res.statusCode == 201) {
              final decoded = jsonDecode(res.body);
              final returnedNote = NoteModel.fromMap(
                Map<String, dynamic>.from(decoded['data'] ?? decoded),
              );
              final updatedNote = noteModel.copyWith(id: returnedNote.id);
              await notesBox.putAt(i, updatedNote.toMap());
            } else {
              print('Failed to POST note: ${res.statusCode} ${res.body}');
            }
          } catch (e) {
            print('Silent exception POST note: $e');
          }
        } else if (!apiNotesById.containsKey(noteModel.id)) {
        } else {
          final apiNote = apiNotesById[noteModel.id];
          if (noteModel.timestamp.isAfter(apiNote!.timestamp)) {
            try {
              final res = await http.put(
                Uri.parse('$apiUrl/notes/${noteModel.id}'),
                headers: headers(json: true),
                body: jsonEncode(noteModel.toMap()),
              );
              if (res.statusCode != 200 && res.statusCode != 201) {
                print('Failed to PUT note: ${res.statusCode} ${res.body}');
              }
            } catch (e) {
              print('Silent exception PUT note: $e');
            }
          }
        }
      }

      final notesToDelete = localNotes.where((n) => n.isDeleted).toList();
      for (final note in notesToDelete) {
        if (note.id == null) {
          final index = localNotes.indexOf(note);
          if (index != -1) {
            await notesBox.deleteAt(index);
          }
          continue;
        }

        try {
          final res = await http.delete(
            Uri.parse('$apiUrl/notes/${note.id}'),
            headers: headers(),
          );
          if (res.statusCode == 200 ||
              res.statusCode == 202 ||
              res.statusCode == 204) {
            final index = localNotes.indexOf(note);
            if (index != -1) {
              await notesBox.deleteAt(index);
            }
          } else {
            print('Failed to DELETE note: ${res.statusCode} ${res.body}');
          }
        } catch (e) {
          print('Silent exception DELETE note: $e');
        }
      }
    } else if (response.statusCode == 401) {
      await HiveSyncBox.setApiToken(null);
      lastError = "Session expired. Please log in again.";
    } else {
      lastError =
          "Failed to sync notes: ${response.statusCode} ${response.body}";
    }
  }
}
