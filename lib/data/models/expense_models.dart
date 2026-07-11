class CategoryModel {
  final int id;
  final String name;
  final String icon;
  final int color;
  final bool isCustom;
  final String type;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isCustom,
    required this.type,
    required this.isActive,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? 'receipt',
      color: map['color'] as int? ?? 0xFF757575,
      isCustom: map['isCustom'] as bool? ?? false,
      type: map['type'] as String? ?? 'expense',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'isCustom': isCustom,
    'type': type,
    'isActive': isActive,
  };
}

class AccountModel {
  final int id;
  final String name;
  final String type;
  final double balance;
  final String icon;
  final int color;
  final bool isActive;

  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.icon,
    required this.color,
    required this.isActive,
  });
}

class ExpenseModel {
  final int id;
  final double amount;
  final int categoryId;
  final DateTime date;
  final String? note;
  final int? accountId;
  final String? paymentMethod;
  final String? receiptPath;
  final List<String> tags;
  final bool isRecurring;
  final String? recurringFrequency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryModel? category;

  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    this.accountId,
    this.paymentMethod,
    this.receiptPath,
    this.tags = const [],
    this.isRecurring = false,
    this.recurringFrequency,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, [CategoryModel? category]) {
    final tagsRaw = map['tags'] as String?;
    return ExpenseModel(
      id: map['id'] as int? ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      categoryId: map['categoryId'] as int? ?? 0,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      note: map['note'] as String?,
      accountId: map['accountId'] as int?,
      paymentMethod: map['paymentMethod'] as String?,
      receiptPath: map['receiptPath'] as String?,
      tags: tagsRaw != null && tagsRaw.isNotEmpty ? tagsRaw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList() : const [],
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurringFrequency: map['recurringFrequency'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
      category: category,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'categoryId': categoryId,
    'date': date.toIso8601String(),
    'note': note,
    'accountId': accountId,
    'paymentMethod': paymentMethod,
    'receiptPath': receiptPath,
    'tags': tags.isNotEmpty ? tags.join(',') : null,
    'isRecurring': isRecurring,
    'recurringFrequency': recurringFrequency,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class IncomeModel {
  final int id;
  final double amount;
  final int categoryId;
  final String? source;
  final DateTime date;
  final String? note;
  final int? accountId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryModel? category;

  const IncomeModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    this.source,
    required this.date,
    this.note,
    this.accountId,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory IncomeModel.fromMap(Map<String, dynamic> map, [CategoryModel? category]) {
    final tagsRaw = map['tags'] as String?;
    return IncomeModel(
      id: map['id'] as int? ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      categoryId: map['categoryId'] as int? ?? 0,
      source: map['source'] as String?,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      note: map['note'] as String?,
      accountId: map['accountId'] as int?,
      tags: tagsRaw != null && tagsRaw.isNotEmpty ? tagsRaw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList() : const [],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
      category: category,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'categoryId': categoryId,
    'source': source,
    'date': date.toIso8601String(),
    'note': note,
    'accountId': accountId,
    'tags': tags.isNotEmpty ? tags.join(',') : null,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class TransferModel {
  final int id;
  final int fromAccountId;
  final int toAccountId;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransferModel({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });
}

class BudgetModel {
  final int id;
  final int? categoryId;
  final int month;
  final int year;
  final double budgetAmount;
  final double spentAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryModel? category;

  const BudgetModel({
    required this.id,
    this.categoryId,
    required this.month,
    required this.year,
    required this.budgetAmount,
    required this.spentAmount,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  double get remaining => budgetAmount - spentAmount;
  double get percentage => budgetAmount > 0 ? (spentAmount / budgetAmount) * 100 : 0;

  factory BudgetModel.fromMap(Map<String, dynamic> map, [CategoryModel? category]) {
    return BudgetModel(
      id: map['id'] as int? ?? 0,
      categoryId: map['categoryId'] as int?,
      month: map['month'] as int? ?? DateTime.now().month,
      year: map['year'] as int? ?? DateTime.now().year,
      budgetAmount: (map['budgetAmount'] as num?)?.toDouble() ?? 0,
      spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
      category: category,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'month': month,
    'year': year,
    'budgetAmount': budgetAmount,
    'spentAmount': spentAmount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class DashboardSummary {
  final double totalToday;
  final double totalThisWeek;
  final double totalThisMonth;
  final double totalIncomeThisMonth;
  final double remainingBudget;
  final String topCategory;
  final double topCategoryAmount;

  const DashboardSummary({
    required this.totalToday,
    required this.totalThisWeek,
    required this.totalThisMonth,
    required this.totalIncomeThisMonth,
    required this.remainingBudget,
    required this.topCategory,
    required this.topCategoryAmount,
  });
}

class SavingsGoal {
  final String id;
  final double targetAmount;
  final DateTime targetDate;
  final String description;
  final double savedAmount;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.targetAmount,
    required this.targetDate,
    required this.description,
    this.savedAmount = 0,
    required this.createdAt,
  });

  double get progress => targetAmount > 0 ? (savedAmount / targetAmount) * 100 : 0;
  double get remaining => targetAmount - savedAmount;
  int get daysLeft => DateTime.now().difference(targetDate).inDays;
  bool get isOverdue => daysLeft > 0;
  double get monthlyTarget {
    final monthsLeft = targetDate.difference(DateTime.now()).inDays / 30.0;
    return monthsLeft > 0 ? remaining / monthsLeft : remaining;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'targetAmount': targetAmount,
    'targetDate': targetDate.toIso8601String(),
    'description': description,
    'savedAmount': savedAmount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
    id: map['id'] as String,
    targetAmount: (map['targetAmount'] as num).toDouble(),
    targetDate: DateTime.parse(map['targetDate'] as String),
    description: map['description'] as String? ?? '',
    savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}
