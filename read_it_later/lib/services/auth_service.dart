import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive',
      'https://www.googleapis.com/auth/script.projects',
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  Future<void> init() async {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
    });
    await _googleSignIn.signInSilently();
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user != null) {
        print('Signed in user: ${user.email}');
        final auth = await user.authentication;
        print('Access Token present: ${auth.accessToken != null}');
        print('ID Token present: ${auth.idToken != null}');
      }
      return user;
    } catch (error) {
      print('Sign in failed: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
  }

  Future<String?> getAccessToken() async {
    if (_currentUser == null) {
      // Try to recover user if null but signed in?
      if (_googleSignIn.currentUser != null) {
         _currentUser = _googleSignIn.currentUser;
      } else {
         return null;
      }
    }
    final auth = await _currentUser!.authentication;
    return auth.accessToken;
  }
  
  Future<String?> getIdToken() async {
    if (_currentUser == null) return null;
    final auth = await _currentUser!.authentication;
    return auth.idToken;
  }
}
