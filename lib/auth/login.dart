import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state/business_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isObscured = true; // Start with the password hidden
late final onSubmitted;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// 🔐 LOGIN → LOAD BUSINESS → NAVIGATE
  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (email.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Email and password are required')),
      );
      return;
    }

    try {
      // 1️⃣ Supabase login
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const AuthException('Invalid credentials');
      }

      // 2️⃣ Load business into global state
      await loadBusiness(ref);

      final business = ref.read(businessProvider);
      if (business == null) {
        throw Exception('Business not linked to this user');
      }

      // 3️⃣ Navigate ONLY after business is ready
      context.go('/dashboard');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Stack(
        children: [
          /// CENTER LOGIN FORM
          Center(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sign in to Continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// EMAIL
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Enter Your Email'),
                  ),

                  const SizedBox(height: 16),

                  /// PASSWORD
                  TextField(
                    controller: passwordController,
                    // Use the variable here
                    obscureText: _isObscured,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_){
                      _login();

                    },

                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Enter Your Password',
                      suffixIcon: IconButton(
                        // Toggle the state when pressed
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                        // Change the icon based on the state
                        icon: Icon(
                          _isObscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white38,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// FORGOT PASSWORD
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: TextButton(
                  //     onPressed: () {},
                  //     child: const Text(
                  //       'Forgot Password?',
                  //       style: TextStyle(
                  //         color: Color(0xFFFFD54F),
                  //         fontSize: 12,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 10),

                  /// LOGIN BUTTON
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// SIGN UP
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: const [
                  //     Text(
                  //       "Don't have an account? ",
                  //       style: TextStyle(color: Colors.white54),
                  //     ),
                  //     Text(
                  //       'Sign up',
                  //       style: TextStyle(
                  //         color: Color(0xFFFFD54F),
                  //         fontWeight: FontWeight.w500,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
