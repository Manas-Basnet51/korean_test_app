enum TestCategory {
  topikI,
  topikII,
  practice,
  all,
}

extension TestCategoryExtension on TestCategory {
  String get name {
    switch (this) {
      case TestCategory.topikI:
        return 'TOPIK I';
      case TestCategory.topikII:
        return 'TOPIK II';
      case TestCategory.practice:
        return 'Practice';
      case TestCategory.all:
        return 'All';
    }
  }
}