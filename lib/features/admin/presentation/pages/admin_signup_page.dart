import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/features/admin/presentation/bloc/admin_permission_cubit.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';

class AdminSignupPage extends StatefulWidget {
  const AdminSignupPage({super.key});

  @override
  State<AdminSignupPage> createState() => _AdminSignupPageState();
}

class _AdminSignupPageState extends State<AdminSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isValidatingCode = false;

  late LanguagePreferenceCubit languageCubit;
  late  SnackBarCubit snackBarCubit;
  late  AuthCubit authCubit;

  @override
  void initState() {
    languageCubit = context.read<LanguagePreferenceCubit>();
    snackBarCubit = context.read<SnackBarCubit>();
    authCubit = context.read<AuthCubit>();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _adminCodeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _validateAdminCode() async {
    if (_adminCodeController.text.trim().isEmpty) return;
    
    setState(() {
      _isValidatingCode = true;
    });
    
    final adminService = context.read<AdminPermissionCubit>();
    final isValid = await adminService.validateAdminCode(_adminCodeController.text.trim());
    
    setState(() {
      _isValidatingCode = false;
    });
    
    if (!isValid && mounted) {
      snackBarCubit.showErrorLocalized(
        korean: '유효하지 않은 관리자 코드입니다.',
        english: 'Invalid admin code.',
      );
    }
  }

  Future<void> _handleAdminSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    final adminService = context.read<AdminPermissionCubit>();
    // Use the class variables initialized in initState instead of watching here
    // Don't use context.watch() in event handlers

    try {
      // First validate the admin code
      final isValidCode = await adminService.validateAdminCode(_adminCodeController.text.trim());
      
      if (!isValidCode) {
        throw Exception(languageCubit.getLocalizedText(
          korean: '유효하지 않은 관리자 코드입니다. 계정이 생성되지 않았습니다.',
          english: 'Invalid admin code. Account was not created.',
        ));
      }
      
      // Register the user
      await authCubit.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      
      // Wait for user to be fully authenticated
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get the user ID after registration
      final userId = authCubit.getCurrentUserId();
      
      if (userId.isEmpty) {
        throw Exception('Failed to get user ID');
      }
      
      // Add them to admin collection
      await adminService.registerUserAsAdmin(
        userId, 
        _adminCodeController.text.trim()
      );
      
      // Show success and navigate
      if (mounted) {
        snackBarCubit.showSuccessLocalized(
          korean: '관리자 계정이 성공적으로 생성되었습니다',
          english: 'Admin account created successfully',
        );
        
        context.go('/home');
      }
    } catch (e) {
      // If we created a user but failed to make them admin, we need to delete the user
      try {
        await authCubit.deleteCurrentUser();
      } catch (_) {
        // If deletion fails, at least try to sign out
        try {
          await authCubit.signOut();
        } catch (_) {} // Ignore any errors during signout
      }
      
      if (mounted) {
        snackBarCubit.showErrorLocalized(
          korean: '오류: ${e.toString()}',
          english: 'Error: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCubit = context.watch<LanguagePreferenceCubit>();
    
    return BlocListener<AdminPermissionCubit, AdminPermissionState>(
      listener: (context, state) {
        if (state is AdminCodeValidationSuccess && !state.isValid) {
          snackBarCubit.showErrorLocalized(
            korean: '유효하지 않은 관리자 코드입니다.',
            english: 'Invalid admin code.',
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            languageCubit.getLocalizedText(
              korean: '관리자 가입',
              english: 'Admin Signup',
              hardWords: ['관리자'],
            ),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: colorScheme.surface,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      languageCubit.getLocalizedText(
                        korean: '관리자 계정 생성',
                        english: 'Create Admin Account',
                        hardWords: ['관리자'],
                      ),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      languageCubit.getLocalizedText(
                        korean: '관리자 권한으로 등록',
                        english: 'Register with admin privileges',
                        hardWords: ['관리자', '권한'],
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Admin registration form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: languageCubit.getLocalizedText(
                                korean: '이름',
                                english: 'Full Name',
                              ),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return languageCubit.getLocalizedText(
                                  korean: '이름을 입력하세요',
                                  english: 'Please enter your name',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: languageCubit.getLocalizedText(
                                korean: '이메일',
                                english: 'Email',
                              ),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return languageCubit.getLocalizedText(
                                  korean: '이메일을 입력하세요',
                                  english: 'Please enter your email',
                                );
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return languageCubit.getLocalizedText(
                                  korean: '유효한 이메일을 입력하세요',
                                  english: 'Please enter a valid email',
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
                                );
                              }
                              if (value.length < 6) {
                                return languageCubit.getLocalizedText(
                                  korean: '비밀번호는 최소 6자 이상이어야 합니다',
                                  english: 'Password must be at least 6 characters',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Admin Code field
                          TextFormField(
                            controller: _adminCodeController,
                            decoration: InputDecoration(
                              labelText: languageCubit.getLocalizedText(
                                korean: '관리자 비밀 코드',
                                english: 'Admin Secret Code',
                                hardWords: ['관리자', '비밀 코드'],
                              ),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.admin_panel_settings),
                              suffixIcon: _isValidatingCode 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: _validateAdminCode,
                                    tooltip: languageCubit.getLocalizedText(
                                      korean: '코드 확인',
                                      english: 'Validate Code',
                                    ),
                                  ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return languageCubit.getLocalizedText(
                                  korean: '관리자 코드를 입력하세요',
                                  english: 'Please enter the admin code',
                                  hardWords: ['관리자 코드'],
                                );
                              }
                              return null;
                            },
                            onChanged: (_) {
                              final currentState = context.read<AdminPermissionCubit>().state;
                              if (currentState is AdminCodeValidationSuccess) {
                                context.read<AdminPermissionCubit>().reset();
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Sign up button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAdminSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.secondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: colorScheme.onSecondary)
                                  : Text(
                                      languageCubit.getLocalizedText(
                                        korean: '관리자 계정 생성',
                                        english: 'CREATE ADMIN ACCOUNT',
                                        hardWords: ['관리자'],
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSecondary,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Return to login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                languageCubit.getLocalizedText(
                                  korean: '이미 계정이 있으신가요?',
                                  english: "Already have an account?",
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.go('/login');
                                },
                                child: Text(
                                  languageCubit.getLocalizedText(
                                    korean: '로그인',
                                    english: 'Sign In',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}