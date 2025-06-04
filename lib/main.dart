import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'translator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Переводчик',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('AuthWrapper snapshot: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, user=${snapshot.data}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return TranslatorScreen();
        }
        return SignInScreen();
      },
    );
  }
}


class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Вход')),
      body: Center(
        child: _user == null
            ? FilledButton.icon(
                icon: Image.asset('assets/google_logo.png', width: 24, height: 24),
                label: Text('Войти через Google'),
                onPressed: () async {
                  try {
                    await _signInWithGoogle();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка входа: $e')),
                    );
                  }
                },
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Вы уже вошли как ${_user?.email ?? _user?.displayName ?? 'пользователь'}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      await _googleSignIn.signOut();
                      await _auth.signOut();
                    },
                    child: const Text('Выйти'),
                  ),
                ],
              ),
      ),
    );
  }
}