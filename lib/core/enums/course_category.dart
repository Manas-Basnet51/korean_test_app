enum CourseCategory {
  korean,
  nepali,
  test,
  global,
  favorite
}

extension CourseCategoryExtension on CourseCategory {
  String get name {
    switch (this) {
      case CourseCategory.korean:
        return 'korean';
      case CourseCategory.nepali:
        return 'nepali';
      case CourseCategory.test:
        return 'test';
      case CourseCategory.global:
        return 'global';
      case CourseCategory.favorite:
        return 'favorite';
    }
  }
  
  String getFlagAsset() {
    switch (this) {
      case CourseCategory.korean:
        return 'assets/flags/south_korea.png';
      case CourseCategory.nepali:
        return 'assets/flags/nepal.png';
      case CourseCategory.test:
        return 'assets/flags/test_icon.png';
      case CourseCategory.global:
        return 'assets/flags/global.png';
      case CourseCategory.favorite:
        return 'assets/flags/favorite_icon.png';
    }
  }
}