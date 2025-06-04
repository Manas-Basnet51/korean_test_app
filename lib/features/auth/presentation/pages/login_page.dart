// lib/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated || state is AuthAnonymousSignIn) {
            //TODO: do something here or remove it 
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo or app name
                      const Text(
                        'Korean Test App',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      
                      // Login form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: languageCubit.getLocalizedText(
                                  korean: '이메일',
                                  english: 'Email',
                                  hardWords: [],
                                ),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageCubit.getLocalizedText(
                                    korean: '이메일을 입력하세요',
                                    english: 'Please enter your email',
                                    hardWords: [],
                                  );
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return languageCubit.getLocalizedText(
                                    korean: '유효한 이메일을 입력하세요',
                                    english: 'Please enter a valid email',
                                    hardWords: [],
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: languageCubit.getLocalizedText(
                                  korean: '비밀번호',
                                  english: 'Password',
                                  hardWords: [],
                                ),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageCubit.getLocalizedText(
                                    korean: '비밀번호를 입력하세요',
                                    english: 'Please enter your password',
                                    hardWords: [],
                                  );
                                }
                                if (value.length < 6) {
                                  return languageCubit.getLocalizedText(
                                    korean: '비밀번호는 최소 6자 이상이어야 합니다',
                                    english: 'Password must be at least 6 characters',
                                    hardWords: [],
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            
                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  context.push('/forgot-password');
                                },
                                child: Text(
                                  languageCubit.getLocalizedText(
                                    korean: '비밀번호를 잊으셨나요?',
                                    english: 'Forgot Password?',
                                    hardWords: [],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: state is AuthLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          context.read<AuthCubit>().signIn(
                                                _emailController.text.trim(),
                                                _passwordController.text,
                                              );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: state is AuthLoading
                                    ? CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          colorScheme.onPrimary,
                                        ),
                                      )
                                    : Text(
                                        languageCubit.getLocalizedText(
                                          korean: '로그인',
                                          english: 'LOG IN',
                                          hardWords: [],
                                        ),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Sign up options
                            Column(
                              children: [
                                // Regular signup option
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      languageCubit.getLocalizedText(
                                        korean: '계정이 없으신가요?',
                                        english: "Don't have an account?",
                                        hardWords: [],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.push('/register');
                                      },
                                      child: Text(
                                        languageCubit.getLocalizedText(
                                          korean: '회원가입',
                                          english: 'Sign Up',
                                          hardWords: [],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Admin signup option
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      languageCubit.getLocalizedText(
                                        korean: '관리자 계정이 필요하신가요?',
                                        english: "Need admin access?",
                                        hardWords: ['관리자'],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.push('/admin-signup');
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.deepPurple,
                                      ),
                                      child: Text(
                                        languageCubit.getLocalizedText(
                                          korean: '관리자 가입',
                                          english: 'Admin Signup',
                                          hardWords: ['관리자'],
                                        ),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Divider with "or" text
                            Row(
                              children: [
                                Expanded(child: Divider(color: colorScheme.outlineVariant)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    languageCubit.getLocalizedText(
                                      korean: '또는',
                                      english: 'OR',
                                      hardWords: [],
                                    ),
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: colorScheme.outlineVariant)),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Guest login button
                            ElevatedButton.icon(
                              icon: state is AuthAnonymousLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2.0),
                                      ) 
                                    : const Icon(Icons.person_outline),
                              label: Text(
                                languageCubit.getLocalizedText(
                                  korean: '게스트로 계속하기',
                                  english: 'Continue as Guest',
                                  hardWords: [],
                                ),
                              ),
                              onPressed: state is AuthAnonymousLoading
                                    ? null 
                                    : () {
                                        context.read<AuthCubit>().signInAnonymously();
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Google sign in button
                            ElevatedButton.icon(
                              icon: state is AuthGoogleLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2.0),
                                      ) 
                                    : SvgPicture.asset(
                                        'assets/images/google_sign_in.svg',
                                        height: 24.0,
                                        width: 24.0,
                                      ),
                              label: Text(
                                languageCubit.getLocalizedText(
                                  korean: 'Google로 로그인',
                                  english: 'Sign in with Google',
                                  hardWords: [],
                                ),
                              ),
                              onPressed: state is AuthGoogleLoading
                                    ? null 
                                    : () {
                                        context.read<AuthCubit>().signInWithGoogle();
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}