import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/presentation/language_preference/enums/language_mode.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';

class LanguagePreferencePage extends StatelessWidget {
  const LanguagePreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Language Preferences',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<LanguagePreferenceCubit, LanguagePreferenceState>(
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Explanation section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues( alpha : 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Your Learning Mode',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select how you want Korean text to be displayed throughout the app based on your proficiency level.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Language mode options
                    Text(
                      'Display Mode',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Beginner mode
                    _buildPreferenceCard(
                      context: context,
                      title: 'Beginner',
                      description: 'Mostly English with basic Korean vocabulary',
                      icon: Icons.star_outline,
                      isSelected: state.mode == LanguageMode.beginner,
                      onTap: () => context.read<LanguagePreferenceCubit>().setLanguageMode(LanguageMode.beginner),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Intermediate mode
                    _buildPreferenceCard(
                      context: context,
                      title: 'Intermediate',
                      description: 'Equal mix of Korean and English',
                      icon: Icons.star_half_outlined,
                      isSelected: state.mode == LanguageMode.intermediate,
                      onTap: () => context.read<LanguagePreferenceCubit>().setLanguageMode(LanguageMode.intermediate),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Advanced mode
                    _buildPreferenceCard(
                      context: context,
                      title: 'Advanced',
                      description: 'Mostly Korean with English support',
                      icon: Icons.star,
                      isSelected: state.mode == LanguageMode.advanced,
                      onTap: () => context.read<LanguagePreferenceCubit>().setLanguageMode(LanguageMode.advanced),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Full Korean mode
                    _buildPreferenceCard(
                      context: context,
                      title: 'Full Korean',
                      description: 'App interface entirely in Korean',
                      icon: Icons.auto_awesome,
                      isSelected: state.mode == LanguageMode.fullKorean,
                      onTap: () => context.read<LanguagePreferenceCubit>().setLanguageMode(LanguageMode.fullKorean),
                    ),
                    
                    const SizedBox(height: 24,),
                    
                    // Current setting indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Setting',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.mode.label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreferenceCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues( alpha : 0.2) : colorScheme.surface,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues( alpha : 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary.withValues( alpha : 0.2) : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

}