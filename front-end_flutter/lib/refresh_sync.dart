import 'package:flutter/material.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/hive/hive_sync_manager.dart';

Future<void> refreshSync(
    BuildContext context, AnimationController refreshController) async {
  refreshController.repeat();

  final username = HiveAuthBox.getActiveUsername() ?? '';
  final password = HiveAuthBox.getActiveUserPassword() ?? '';
  final email = HiveAuthBox.getActiveUserEmail() ?? '';

  if (username.isEmpty) {
    refreshController.reset();
    debugPrint('$username $password');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Missing credentials. Please log in again.')),
    );
    return;
  }

  try {
    final success = await HiveSyncManager().ensureUserRegisteredAndLoggedIn(
      username: username,
      password: password,
      email: email,
    );

    if (!success) {
      refreshController.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(HiveSyncManager().lastError ??
                'Registration or login failed.')),
      );
      return;
    }

    await HiveSyncManager().syncAll();

    if (HiveSyncManager().lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: const Text('Sync error')),
      );
      print(HiveSyncManager().lastError);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync successful!')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unexpected error: $e')),
    );
  } finally {
    refreshController.reset();
  }
}
