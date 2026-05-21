import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  const SessionService._();

  static Future<Map<String, String?>> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
    };
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_name', user['name']?.toString() ?? '');
    await prefs.setString('user_email', user['email']?.toString() ?? '');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
