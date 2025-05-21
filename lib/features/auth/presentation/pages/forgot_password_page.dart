import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/routes/app_router.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageCubit = context.read<LanguagePreferenceCubit>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageCubit.getLocalizedText(
            korean: '비밀번호 재설정',
            english: 'Reset Password',
            hardWords: [],
          ),
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  languageCubit.getLocalizedText(
                    korean: '비밀번호 재설정 이메일이 전송되었습니다.',
                    english: 'Password reset email has been sent',
                    hardWords: [],
                  ),
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate back to login page
            context.go(Routes.login);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    languageCubit.getLocalizedText(
                      korean: '이메일 주소를 입력하면 비밀번호 재설정 링크를 보내드립니다.',
                      english: 'Enter your email address and we will send you a password reset link.',
                      hardWords: [],
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: languageCubit.getLocalizedText(
                        korean: '이메일',
                        english: 'Email',
                        hardWords: [],
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return languageCubit.getLocalizedText(
                          korean: '이메일을 입력해주세요',
                          english: 'Please enter your email',
                          hardWords: [],
                        );
                      }
                      // Add email validation if needed
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthCubit>().resetPassword(_emailController.text.trim());
                            }
                          },
                    child: state is AuthLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            languageCubit.getLocalizedText(
                              korean: '비밀번호 재설정 링크 보내기',
                              english: 'Send Reset Link',
                              hardWords: [],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}