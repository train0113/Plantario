import 'package:flutter/material.dart';
import 'package:khuthon/config/palette.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khuthon/screens/dashboard_screen.dart';
import 'package:khuthon/screens/signup_screen.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authentication = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String userEmail = '';
  String userPassword = '';

  void _tryValidation() {
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      _formKey.currentState!.save();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _authentication.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            'email': user.email,
            'userName': user.displayName,
            'createdAt': Timestamp.now(),
          });
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      }
    } catch (e) {
      print('Google 로그인 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google 로그인 중 오류가 발생했습니다.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.eco, size: 48, color: Palette.appiconColor),
                      SizedBox(height: 12),
                      Text("Welcome Back To Plantario", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("Sign in to your account", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.contains('@') ? null : 'Enter a valid email.',
                  onSaved: (value) => userEmail = value!,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 16),
                Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                TextFormField(
                  obscureText: true,
                  validator: (value) => value!.length >= 6 ? null : 'Password must be 6+ characters.',
                  onSaved: (value) => userPassword = value!,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    _tryValidation();
                    try {
                      final user = await _authentication.signInWithEmailAndPassword(
                        email: userEmail,
                        password: userPassword,
                      );
                      if (user.user != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Dashboard()));
                      }
                    } on FirebaseAuthException catch (e) {
                      String message = '로그인 중 오류가 발생했습니다.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message), backgroundColor: Colors.red),
                      );
                    } catch (e) {
                      print(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('알 수 없는 오류가 발생했습니다.'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  icon: Icon(Icons.login),
                  label: Text("Sign In"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(48),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("Or continue with", style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SignInButton(
                      Buttons.Google,
                      text: "Sign in with Google",
                      onPressed: signInWithGoogle,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: 'SignUp',
                          barrierColor: Colors.black.withOpacity(0.4),
                          transitionDuration: Duration(milliseconds: 300),
                          transitionBuilder: (_, anim, __, child) {
                            return FadeTransition(opacity: anim, child: child);
                          },
                          pageBuilder: (_, __, ___) => SignupDialog(),
                        );
                      },
                      child: Text("Sign up", style: TextStyle(color: Palette.activeColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
