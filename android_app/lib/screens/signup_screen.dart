import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:khuthon/config/palette.dart';
import 'package:khuthon/screens/dashboard_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupDialog extends StatefulWidget {
  @override
  _SignupDialogState createState() => _SignupDialogState();
}

Future<String> loadPrivacyPolicy() async {
  return await rootBundle.loadString('assets/terms/privacy_policy.txt');
}

class _SignupDialogState extends State<SignupDialog> {
  final _authentication = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String name = '';
  String password = '';
  String confirmPassword = '';
  bool agreed = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white.withOpacity(0.95),
      insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("회원가입", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text("이미 계정이 있으신가요?"),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("로그인", style: TextStyle(color: Colors.blue)),
                      )
                    ],
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "이메일",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val != null && val.contains('@') ? null : '유효한 이메일을 입력하세요.',
                    onSaved: (val) => email = val ?? '',
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "이름",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val != null && val.length >= 2 ? null : '이름을 2자 이상 입력하세요.',
                    onSaved: (val) => name = val ?? '',
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "비밀번호",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val != null && val.length >= 6 ? null : '6자 이상 입력하세요.',
                    onChanged: (val) => password = val,
                    onSaved: (val) => password = val ?? '',
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "비밀번호 확인",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == password ? null : '비밀번호가 일치하지 않습니다.',
                    onSaved: (val) => confirmPassword = val ?? '',
                  ),
                  SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: agreed,
                    onChanged: (val) => setState(() => agreed = val ?? false),
                    title: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black, fontSize: 12),
                        children: [
                          TextSpan(text: "이용약관과 "),
                          TextSpan(
                            text: "개인정보 처리방침",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.solid,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                final policyText = await loadPrivacyPolicy();
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("개인정보 처리방침"),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      height: 500,
                                      child: SingleChildScrollView(
                                        child: Text(policyText, style: TextStyle(fontSize: 14)),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text("확인"),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                );
                              },
                          ),
                          TextSpan(text: "에 동의합니다."),
                        ],
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (!agreed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('약관에 동의해주세요.')),
                          );
                          return;
                        }
                        _formKey.currentState!.save();
                        try {
                          final newUser = await _authentication.createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                          if (newUser.user != null) {
                            // Firestore에 사용자 정보 저장
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(newUser.user!.uid)
                                .set({
                              'email': email,
                              'userName': name,
                              'createdAt': Timestamp.now(),
                            });

                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => Dashboard()),
                            );
                          }
                        } catch (e) {
                          print(e);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("회원가입 실패: ${e.toString()}")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.activeColor,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("가입하기", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
