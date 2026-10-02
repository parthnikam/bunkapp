import 'package:shared_preferences/shared_preferences.dart';
void main() async {
  SharedPreferences.setMockInitialValues({}); // This doesn't help read real prefs.
}
