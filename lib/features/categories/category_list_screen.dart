import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/database/local_database.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/models/expense_models.dart';
import '../../core/utils/icons_helper.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  List<CategoryModel> _categories = [];
  late ExpenseRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = RepositoryProvider.of<ExpenseRepository>(context);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _repo.getCategories();
    debugPrint('[CategoryList] loaded ${cats.length} categories');
    setState(() => _categories = cats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: _categories.isEmpty
          ? const Center(child: Text('No categories yet.'))
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final color = Color(cat.color);
                return Dismissible(
                  key: ValueKey(cat.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _onDeleteRequested(cat),
                  onDismissed: (_) => _deleteCategory(cat),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.2),
                      child: Icon(
                        _iconFromName(cat.icon),
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Text(cat.name),
                    subtitle: Text(cat.type == 'expense' ? UiLabels.expenseLabel : UiLabels.incomeLabel),
                    trailing: cat.isCustom
                        ? null
                        : const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    onTap: () => _showAddEditDialog(category: cat),
                    onLongPress: cat.isCustom
                        ? () async {
                            final confirmed = await _showDeleteConfirmation(cat);
                            if (confirmed == true) _deleteCategory(cat);
                          }
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool?> _onDeleteRequested(CategoryModel cat) async {
    if (!cat.isCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.categoryDefaultCannotDelete)),
      );
      return false;
    }
    return _showDeleteConfirmation(cat);
  }

  Future<bool> _showDeleteConfirmation(CategoryModel category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(UiLabels.deleteCategoryTitle),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    debugPrint('[CategoryList] deleting category id=${category.id} name=${category.name}');
    RepositoryProvider.of<LocalDatabase>(context).delete('categories', category.id);
    await _loadCategories();
  }

  Future<void> _showAddEditDialog({CategoryModel? category}) async {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedType = category?.type ?? 'expense';
    String selectedIcon = category?.icon ?? 'receipt';
    int selectedColor = category?.color ?? 0xFFE53935;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? PageTitles.editCategory : PageTitles.addCategory),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'expense', child: Text(UiLabels.expenseLabel)),
                        DropdownMenuItem(value: 'income', child: Text(UiLabels.incomeLabel)),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedType = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedIcon,
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        border: OutlineInputBorder(),
                      ),
                      items: _iconOptions.map((e) => DropdownMenuItem(
                        value: e.$1,
                        child: Row(
                          children: [Icon(e.$2, size: 20), const SizedBox(width: 12), Text(e.$1)],
                        ),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedIcon = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Color', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions.map((e) {
                        final clr = Color(e.$2);
                        final selected = selectedColor == e.$2;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = e.$2),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: clr,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: selected
                                  ? [BoxShadow(color: clr.withValues(alpha: 0.6), blurRadius: 8)]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(AppMessages.nameRequired)),
                      );
                      return;
                    }
                    if (isEditing) {
                      final db = RepositoryProvider.of<LocalDatabase>(context);
                      final existing = db.getById('categories', category.id);
                      if (existing != null) {
                        existing['name'] = name;
                        existing['icon'] = selectedIcon;
                        existing['color'] = selectedColor;
                        existing['type'] = selectedType;
                        db.update('categories', category.id, existing);
                      }
                    } else {
                      await _repo.addCategory(name, selectedIcon, selectedColor, selectedType);
                    }
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _loadCategories();
    }
  }
}

IconData _iconFromName(String name) {
  switch (name) {
    case 'restaurant': return Icons.restaurant;
    case 'directions_car': return Icons.directions_car;
    case 'shopping_bag': return Icons.shopping_bag;
    case 'receipt': return Icons.receipt;
    case 'movie': return Icons.movie;
    case 'local_hospital': return Icons.local_hospital;
    case 'school': return Icons.school;
    case 'work': return Icons.work;
    case 'computer': return Icons.computer;
    case 'trending_up': return Icons.trending_up;
    case 'card_giftcard': return Icons.card_giftcard;
    case 'more_horiz': return Icons.more_horiz;
    case 'savings': return Icons.savings;
    case 'fitness_center': return Icons.fitness_center;
    case 'flight': return Icons.flight;
    case 'pets': return Icons.pets;
    case 'music_note': return Icons.music_note;
    case 'photo_camera': return Icons.photo_camera;
    default: return iconFromString(name);
  }
}

const List<(String, IconData)> _iconOptions = [
  ('restaurant', Icons.restaurant),
  ('directions_car', Icons.directions_car),
  ('shopping_bag', Icons.shopping_bag),
  ('receipt', Icons.receipt),
  ('movie', Icons.movie),
  ('local_hospital', Icons.local_hospital),
  ('school', Icons.school),
  ('work', Icons.work),
  ('computer', Icons.computer),
  ('trending_up', Icons.trending_up),
  ('card_giftcard', Icons.card_giftcard),
  ('more_horiz', Icons.more_horiz),
  ('savings', Icons.savings),
  ('fitness_center', Icons.fitness_center),
  ('flight', Icons.flight),
  ('pets', Icons.pets),
  ('music_note', Icons.music_note),
  ('photo_camera', Icons.photo_camera),
];

const List<(String, int)> _colorOptions = [
  ('Red', 0xFFE53935),
  ('Blue', 0xFF1E88E5),
  ('Green', 0xFF43A047),
  ('Purple', 0xFF8E24AA),
  ('Orange', 0xFFFB8C00),
  ('Teal', 0xFF00897B),
  ('Pink', 0xFFD81B60),
  ('Indigo', 0xFF3949AB),
  ('Lime', 0xFFC0CA33),
  ('Brown', 0xFF8D6E63),
];
