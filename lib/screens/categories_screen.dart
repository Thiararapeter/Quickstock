import 'package:flutter/material.dart';
import '../services/supabase_database.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _categoryController = TextEditingController();
  List<String> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);
      final categories = await SupabaseDatabase.instance.getCategories();
      if (mounted) {
        setState(() {
          if (!categories.contains('Parts')) {
            _categories = ['Parts', ...categories];
          } else {
            _categories = categories;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editCategory(String oldCategory) async {
    if (oldCategory == 'Parts') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System category cannot be modified'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _categoryController.text = oldCategory;
    await showDialog<void>(
      context: context,
      builder: (context) => _buildCategoryDialog(categoryToEdit: oldCategory),
    );
    _categoryController.clear();
  }

  Future<void> _deleteCategory(String category) async {
    if (category == 'Parts') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System category cannot be deleted'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$category"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await SupabaseDatabase.instance.deleteCategory(category);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
        _loadCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting category: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildCategoryTile(String category) {
    final isParts = category == 'Parts';
    
    return Card(
      child: ListTile(
        leading: const Icon(Icons.category),
        title: Row(
          children: [
            Text(category),
            if (isParts) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'System category - Cannot be modified',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: const Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: isParts
            ? const Tooltip(
                message: 'System category cannot be modified',
                child: Icon(Icons.lock, color: Colors.grey),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editCategory(category),
                    tooltip: 'Edit Category',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCategory(category),
                    tooltip: 'Delete Category',
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final sortedCategories = List<String>.from(_categories)
                  ..sort((a, b) {
                    if (a == 'Parts') return -1;
                    if (b == 'Parts') return 1;
                    return a.compareTo(b);
                  });
                final category = sortedCategories[index];
                return _buildCategoryTile(category);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'categories_fab',
        onPressed: () async {
          await showDialog<void>(
            context: context,
            builder: (context) => _buildCategoryDialog(),
          );
          _categoryController.clear();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildCategoryDialog({String? categoryToEdit}) {
    return AlertDialog(
      title: Text(categoryToEdit == null ? 'Add Category' : 'Edit Category'),
      content: TextField(
        controller: _categoryController,
        decoration: const InputDecoration(
          labelText: 'Category Name',
          hintText: 'Enter category name',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () {
            _categoryController.clear();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newName = _categoryController.text.trim();
            if (newName.isEmpty) {
              return;
            }

            try {
              if (categoryToEdit != null) {
                await SupabaseDatabase.instance.updateCategory(categoryToEdit, newName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category updated successfully')),
                  );
                }
              } else {
                await SupabaseDatabase.instance.addCategory(newName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category added successfully')),
                  );
                }
              }
              
              _categoryController.clear();
              Navigator.pop(context);
              _loadCategories();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Text(categoryToEdit == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
} 