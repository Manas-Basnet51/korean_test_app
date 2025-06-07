enum QuestionType {
  textQuestion_textAnswers,
  textQuestion_imageAnswers, 
  imageQuestion_textAnswers,
  imageQuestion_imageAnswers,
  textQuestion_mixedAnswers, // Some text, some image answers
}

extension QuestionTypeExtension on QuestionType {
  String get displayName {
    switch (this) {
      case QuestionType.textQuestion_textAnswers:
        return 'Text Question - Text Answers';
      case QuestionType.textQuestion_imageAnswers:
        return 'Text Question - Image Answers';
      case QuestionType.imageQuestion_textAnswers:
        return 'Image Question - Text Answers';
      case QuestionType.imageQuestion_imageAnswers:
        return 'Image Question - Image Answers';
      case QuestionType.textQuestion_mixedAnswers:
        return 'Text Question - Mixed Answers';
    }
  }
  
  bool get hasQuestionImage {
    switch (this) {
      case QuestionType.imageQuestion_textAnswers:
      case QuestionType.imageQuestion_imageAnswers:
        return true;
      default:
        return false;
    }
  }
  
  bool get hasAnswerImages {
    switch (this) {
      case QuestionType.textQuestion_imageAnswers:
      case QuestionType.imageQuestion_imageAnswers:
        return true;
      default:
        return false;
    }
  }
  
  bool get supportsMixedAnswers {
    return this == QuestionType.textQuestion_mixedAnswers;
  }
}

class AnswerOption {
  final String text;
  final String? imageUrl;
  final String? imagePath;
  final bool isImage; // true if this option is image-based
  
  const AnswerOption({
    required this.text,
    this.imageUrl,
    this.imagePath,
    this.isImage = false,
  });
  
  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      text: json['text'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      imagePath: json['imagePath'] as String?,
      isImage: json['isImage'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'isImage': isImage,
    };
  }
  
  AnswerOption copyWith({
    String? text,
    String? imageUrl,
    String? imagePath,
    bool? isImage,
  }) {
    return AnswerOption(
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      isImage: isImage ?? this.isImage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnswerOption &&
        other.text == text &&
        other.imageUrl == imageUrl &&
        other.imagePath == imagePath &&
        other.isImage == isImage;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        imageUrl.hashCode ^
        imagePath.hashCode ^
        isImage.hashCode;
  }

  @override
  String toString() {
    return 'AnswerOption(text: $text, imageUrl: $imageUrl, imagePath: $imagePath, isImage: $isImage)';
  }
}