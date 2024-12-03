import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/inventory_item.dart';
import '../services/supabase_database.dart';
import 'categories_screen.dart';
import 'dart:developer' as developer;
import '../models/warranty.dart';
import 'package:intl/intl.dart';

String generateUniqueId() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

class AddEditItemScreen extends StatefulWidget {
  final InventoryItem? item;
  final bool isPart;

  const AddEditItemScreen({super.key, this.item, this.isPart = false});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _serialNumberController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _quantityController;
  String? _selectedCategory;
  String _condition = 'New';
  bool _isLoading = false;
  List<String> _categories = [];
  final _newCategoryController = TextEditingController();
  bool _attachToProduct = false;
  final _warrantySupplierController = TextEditingController();
  final _warrantyTermsController = TextEditingController();
  DateTime? _warrantyStartDate;
  DateTime? _warrantyEndDate;
  String _warrantyPeriod = '1 year';
  bool _hasWarranty = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _serialNumberController = TextEditingController(text: widget.item?.serialNumber ?? '');
    _purchasePriceController = TextEditingController(text: widget.item?.purchasePrice.toString() ?? '');
    _sellingPriceController = TextEditingController(text: widget.item?.sellingPrice.toString() ?? '');
    _quantityController = TextEditingController(text: widget.item?.quantity.toString() ?? '1');
    _condition = widget.item?.condition ?? 'New';
    
    if (!widget.isPart) {
      _loadCategories();
    } else {
      setState(() {
        _categories = ['Parts'];
        _selectedCategory = 'Parts';
      });
    }
    
    if (widget.item != null) {
      _checkPartAttachment();
    }
    _loadWarrantyData();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await SupabaseDatabase.instance.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories.where((cat) => cat != 'Parts').toList();
        });
      }
    } catch (e) {
      developer.log('Error loading categories: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNoCategoriesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Categories Found'),
          content: const Text(
            'You need to create at least one category before adding items. '
            'Would you like to create a category now?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToCategoriesScreen();
              },
              child: const Text('Create Category'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToCategoriesScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoriesScreen(),
      ),
    );
    _loadCategories(); // Reload categories when returning
  }

  Future<void> _checkPartAttachment() async {
    if (widget.item?.category == 'Parts') {
      final isAttached = await SupabaseDatabase.instance.isPartUsedInProduct(widget.item!.id);
      if (isAttached && mounted) {
        // Show warning about limited editing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This part is attached to a product. Some fields cannot be modified.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildCategoryField() {
    if (_categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('No categories available'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await _navigateToCategoriesScreen();
                },
                child: const Text('Add Categories'),
              ),
            ],
          ),
        ),
      );
    }

    String? dropdownValue = _categories.contains(_selectedCategory) ? _selectedCategory : null;

    return DropdownButtonFormField<String>(
      value: dropdownValue,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (String? value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        if (!widget.isPart && value == 'Parts') {
          return 'Cannot use Parts category for products';
        }
        return null;
      },
    );
  }

  void _showCreateCategoryDialog() {
    _newCategoryController.text = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a name for the new category',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newCategoryController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newCategoryController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _newCategoryController.text.trim();
              if (name.isEmpty) return;

              try {
                setState(() => _isLoading = true);
                await SupabaseDatabase.instance.addCategory(name);
                
                // Reload categories immediately
                await _loadCategories();
                
                if (mounted) {
                  // Close dialog and show success message
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Set the newly created category as selected and rebuild the page
                  setState(() {
                    _selectedCategory = name;
                    _isLoading = false;  // Reset loading state
                  });

                  // Force a rebuild of the entire screen
                  if (mounted) {
                    setState(() {});
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // Add this method to force reload
  Future<void> _reloadScreen() async {
    setState(() => _isLoading = true);
    await _loadCategories();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialNumberController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _newCategoryController.dispose();
    _warrantySupplierController.dispose();
    _warrantyTermsController.dispose();
    super.dispose();
  }

  Future<void> _loadWarrantyData() async {
    if (widget.item != null) {
      final warranty = await SupabaseDatabase.instance.getWarranty(widget.item!.id);
      if (warranty != null) {
        setState(() {
          _hasWarranty = true;
          _warrantyStartDate = warranty.startDate;
          _warrantyEndDate = warranty.endDate;
          _warrantyPeriod = warranty.period;
          _warrantySupplierController.text = warranty.supplier;
          _warrantyTermsController.text = warranty.terms;
        });
      }
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Check if category is 'Parts'
        if (_selectedCategory == 'Parts') {
          throw Exception('Cannot create product with Parts category');
        }

        // Create the item object
        final item = InventoryItem(
          id: widget.item?.id ?? generateUniqueId(),
          name: _nameController.text.trim(),
          serialNumber: _serialNumberController.text.trim(),
          purchasePrice: double.parse(_purchasePriceController.text),
          sellingPrice: double.parse(_sellingPriceController.text),
          category: _selectedCategory!,
          quantity: int.parse(_quantityController.text),
          condition: _condition,
          dateAdded: widget.item?.dateAdded ?? DateTime.now(),
        );

        if (widget.item != null) {
          // Update existing item
          await SupabaseDatabase.instance.updateItem(item);
          
          // Add history record for update
          await SupabaseDatabase.instance.addHistory(
            item.id,
            'PRODUCT_UPDATED',
            'Product details updated',
          );
        } else {
          // Create new item
          await SupabaseDatabase.instance.insertItem(item);
          
          // Add history record for creation
          await SupabaseDatabase.instance.addHistory(
            item.id,
            'PRODUCT_CREATED',
            'Product created',
          );
        }

        // Save warranty if enabled
        if (_hasWarranty && _warrantyStartDate != null && _warrantyEndDate != null) {
          try {
            final warranty = Warranty(
              itemId: item.id,
              startDate: _warrantyStartDate!,
              endDate: _warrantyEndDate!,
              period: _warrantyPeriod,
              supplier: _warrantySupplierController.text.trim(),
              terms: _warrantyTermsController.text.trim(),
            );

            await SupabaseDatabase.instance.addWarranty(warranty);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Warranty saved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Warning: Failed to save warranty: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else if (!_hasWarranty) {
          // If warranty is disabled, try to delete any existing warranty
          try {
            final existingWarranty = await SupabaseDatabase.instance.getWarranty(item.id);
            if (existingWarranty != null) {
              await SupabaseDatabase.instance.deleteWarranty(existingWarranty.id);
            }
          } catch (e) {
            developer.log('Error removing warranty: $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.item == null ? 'Product created successfully' : 'Product updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Pop and return true to indicate successful save
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
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
  }

  Widget _buildWarrantySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Warranty Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _hasWarranty,
                  onChanged: (value) => setState(() => _hasWarranty = value),
                ),
              ],
            ),
            if (_hasWarranty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _warrantyStartDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _warrantyStartDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_warrantyStartDate != null
                          ? 'Start: ${DateFormat('MMM dd, yyyy').format(_warrantyStartDate!)}'
                          : 'Select Start Date'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _warrantyEndDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _warrantyEndDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_warrantyEndDate != null
                          ? 'End: ${DateFormat('MMM dd, yyyy').format(_warrantyEndDate!)}'
                          : 'Select End Date'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _warrantyPeriod,
                decoration: const InputDecoration(
                  labelText: 'Warranty Period',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '6 months', child: Text('6 Months')),
                  DropdownMenuItem(value: '1 year', child: Text('1 Year')),
                  DropdownMenuItem(value: '2 years', child: Text('2 Years')),
                  DropdownMenuItem(value: '3 years', child: Text('3 Years')),
                  DropdownMenuItem(value: '5 years', child: Text('5 Years')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _warrantyPeriod = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _warrantySupplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier/Manufacturer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _warrantyTermsController,
                decoration: const InputDecoration(
                  labelText: 'Warranty Terms & Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add New Item' : 'Edit Item'),
        actions: [
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadScreen,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Basic Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Item Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _serialNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Serial Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.qr_code),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a serial number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pricing',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _purchasePriceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Purchase Price',
                                      border: OutlineInputBorder(),
                                      prefixText: 'KSH ',
                                      prefixIcon: Icon(Icons.attach_money),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _sellingPriceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Selling Price',
                                      border: OutlineInputBorder(),
                                      prefixText: 'KSH ',
                                      prefixIcon: Icon(Icons.sell),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryField(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a quantity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: ['New', 'Used', 'Refurbished']
                        .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _condition = newValue!;
                        });
                      },
                    ),
                    if (widget.isPart) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: CheckboxListTile(
                          title: const Text('Attach to Product'),
                          subtitle: const Text('Add this part to an existing product'),
                          value: _attachToProduct,
                          onChanged: (bool? value) {
                            setState(() {
                              _attachToProduct = value ?? false;
                            });
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildWarrantySection(),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _categories.isEmpty ? null : _saveItem,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading
                            ? 'Processing...'
                            : (widget.item == null 
                                ? (widget.isPart ? 'Save Part' : 'Save Product')
                                : (widget.isPart ? 'Update Part' : 'Update Product')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 