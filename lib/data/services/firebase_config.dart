/// Firebase (Firestore) settings for the ONLINE leaderboard.
///
/// 1. Create a Firebase project and a Firestore database.
/// 2. Paste the Project ID and Web API key below.
/// 3. Paste the rules from FIREBASE_SETUP.md into Firestore -> Rules.
///
/// While both values are empty the app works in "this phone only" mode.
class FirebaseConfig {
  FirebaseConfig._();

  static const String projectId = 'mathra-pipes-game';
  static const String apiKey = 'AIzaSyB2f0Pg8AIWW-VhoqwoIcXBtphnuAyV2-Y';

  static bool get isConfigured => projectId.isNotEmpty && apiKey.isNotEmpty;
}
