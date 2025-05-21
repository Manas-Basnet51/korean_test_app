import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
part 'snackbar_state.dart';

class SnackBarCubit extends Cubit<SnackBarState> {
  final LanguagePreferenceCubit languageCubit;
  SnackBarCubit({required this.languageCubit}) : super(SnackBarInitial());

  // Show information snackbar
  void showInfo({
    required String message,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
    String? id,
  }) {
    emit(SnackBarShow(
      message: message,
      type: SnackBarType.info,
      duration: duration ?? const Duration(seconds: 3),
      action: action,
      actionLabel: actionLabel,
      id: id,
    ));
    
    _autoDismiss(duration ?? const Duration(seconds: 3));
  }

  // Show success snackbar
  void showSuccess({
    required String message,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
    String? id,
  }) {
    emit(SnackBarShow(
      message: message,
      type: SnackBarType.success,
      duration: duration ?? const Duration(seconds: 3),
      action: action,
      actionLabel: actionLabel,
      id: id,
    ));
    
    _autoDismiss(duration ?? const Duration(seconds: 3));
  }

  // Show error snackbar
  void showError({
    required String message,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
    String? id,
  }) {
    emit(SnackBarShow(
      message: message,
      type: SnackBarType.error,
      duration: duration ?? const Duration(seconds: 5),
      action: action,
      actionLabel: actionLabel,
      id: id,
    ));
    
    _autoDismiss(duration ?? const Duration(seconds: 5));
  }

  // Show warning snackbar
  void showWarning({
    required String message,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
    String? id,
  }) {
    emit(SnackBarShow(
      message: message,
      type: SnackBarType.warning,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
      actionLabel: actionLabel,
      id: id,
    ));
    
    _autoDismiss(duration ?? const Duration(seconds: 4));
  }

  // Show progress snackbar (won't auto-dismiss)
  void showProgress({
    required String message,
    VoidCallback? action,
    String? actionLabel,
    String? id,
  }) {
    emit(SnackBarShow(
      message: message,
      type: SnackBarType.progress,
      action: action,
      actionLabel: actionLabel,
      id: id,
    ));
  }

  // Update progress to success
  void updateProgressToSuccess({
    required String message,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
  }) {
    showSuccess(
      message: message,
      duration: duration,
      action: action,
      actionLabel: actionLabel,
    );
  }

  // Update progress to error
  void updateProgressToError({
    required String message,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
  }) {
    showError(
      message: message,
      duration: duration,
      action: action,
      actionLabel: actionLabel,
    );
  }

  // Dismiss currently showing snackbar
  void dismiss() {
    emit(SnackBarDismiss());
    emit(SnackBarInitial());
  }
  
  // Helper to auto-dismiss snackbars after duration
  void _autoDismiss(Duration duration) {
    Timer(duration, () {
      if (state is SnackBarShow) {
        dismiss();
      }
    });
  }

  //Localized Snackbars


  void showInfoLocalized({
    required String korean,
    required String english,
    List<String> hardWords = const [],
    Duration? duration,
    VoidCallback? action,
    String? actionLabelKorean,
    String? actionLabelEnglish,
    String? id,
  }) {
    
    final message = languageCubit.getLocalizedText(
      korean: korean,
      english: english,
      hardWords: hardWords,
    );
    
    String? actionLabel;
    if (actionLabelKorean != null && actionLabelEnglish != null) {
      actionLabel = languageCubit.getLocalizedText(
        korean: actionLabelKorean,
        english: actionLabelEnglish,
        hardWords: const [],
      );
    }
    
    showInfo(
      message: message,
      duration: duration,
      action: action,
      actionLabel: actionLabel,
      id: id,
    );
  }
  
  // Show localized success snackbar
  void showSuccessLocalized({
    required String korean,
    required String english,
    List<String> hardWords = const [],
    Duration? duration,
    VoidCallback? action,
    String? actionLabelKorean,
    String? actionLabelEnglish,
    String? id,
  }) {
    
    final message = languageCubit.getLocalizedText(
      korean: korean,
      english: english,
      hardWords: hardWords,
    );
    
    String? actionLabel;
    if (actionLabelKorean != null && actionLabelEnglish != null) {
      actionLabel = languageCubit.getLocalizedText(
        korean: actionLabelKorean,
        english: actionLabelEnglish,
        hardWords: const [],
      );
    }
    
    showSuccess(
      message: message,
      duration: duration,
      action: action,
      actionLabel: actionLabel,
      id: id,
    );
  }
  
  // Show localized error snackbar
  void showErrorLocalized({
    required String korean,
    required String english,
    List<String> hardWords = const [],
    Duration? duration,
    VoidCallback? action,
    String? actionLabelKorean,
    String? actionLabelEnglish,
    String? id,
  }) {
    
    final message = languageCubit.getLocalizedText(
      korean: korean,
      english: english,
      hardWords: hardWords,
    );
    
    String? actionLabel;
    if (actionLabelKorean != null && actionLabelEnglish != null) {
      actionLabel = languageCubit.getLocalizedText(
        korean: actionLabelKorean,
        english: actionLabelEnglish,
        hardWords: const [],
      );
    }
    
    showError(
      message: message,
      duration: duration,
      action: action,
      actionLabel: actionLabel,
      id: id,
    );
  }
  
  // Show localized warning snackbar
  void showWarningLocalized({
    required String korean,
    required String english,
    List<String> hardWords = const [],
    Duration? duration,
    VoidCallback? action,
    String? actionLabelKorean,
    String? actionLabelEnglish,
    String? id,
  }) {
    
    final message = languageCubit.getLocalizedText(
      korean: korean,
      english: english,
      hardWords: hardWords,
    );
    
    String? actionLabel;
    if (actionLabelKorean != null && actionLabelEnglish != null) {
      actionLabel = languageCubit.getLocalizedText(
        korean: actionLabelKorean,
        english: actionLabelEnglish,
        hardWords: const [],
      );
    }
    
    showWarning(
      message: message,
      duration: duration,
      action: action,
      actionLabel: actionLabel,
      id: id,
    );
  }
  
  // Show localized progress snackbar
  void showProgressLocalized({
    required String korean,
    required String english,
    List<String> hardWords = const [],
    VoidCallback? action,
    String? actionLabelKorean,
    String? actionLabelEnglish,
    String? id,
  }) {
    
    final message = languageCubit.getLocalizedText(
      korean: korean,
      english: english,
      hardWords: hardWords,
    );
    
    String? actionLabel;
    if (actionLabelKorean != null && actionLabelEnglish != null) {
      actionLabel = languageCubit.getLocalizedText(
        korean: actionLabelKorean,
        english: actionLabelEnglish,
        hardWords: const [],
      );
    }
    
    showProgress(
      message: message,
      action: action,
      actionLabel: actionLabel,
      id: id,
    );
  }

}
