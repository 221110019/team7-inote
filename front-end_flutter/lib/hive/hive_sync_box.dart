import 'package:hive/hive.dart';

class HiveSyncBox {
  static const String boxName = 'syncBox';
  static const String apiUrlKey = 'apiUrl';
  static const String apiTokenKey = 'apiToken';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static Box get box => Hive.box(boxName);

  static String get apiUrl =>
      box.get(apiUrlKey, defaultValue: 'http://127.0.0.1:8000/api');
  static Future<void> setApiUrl(String url) async =>
      await box.put(apiUrlKey, url);

  static String? get apiToken => box.get(apiTokenKey);
  static Future<void> setApiToken(String? token) async =>
      await box.put(apiTokenKey, token);
}
