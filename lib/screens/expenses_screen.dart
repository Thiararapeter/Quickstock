import 'package:flutter/material.dart';
import 'dart:async';
import '../models/expense.dart';
import '../services/supabase_database.dart';
import 'package:intl/intl.dart';
import '../widgets/add_edit_expense_dialog.dart';
import 'expense_details_screen.dart';
import '../services/network_service.dart';

enum SortOption {
  nameAZ('Name (A-Z)'),
  nameZA('Name (Z-A)'),
  amountHighLow('Amount (High-Low)'),
  amountLowHigh('Amount (Low-High)'),
  recentlyUpdated('Recently Updated'),
  oldestFirst('Oldest First');

  const SortOption(this.label);
  final String label;
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _searchController = TextEditingController();
  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = false;
  final _currencyFormat = NumberFormat.currency(symbol: 'KSH ', decimalDigits: 2);
  String _sortBy = 'date';  // Default sort
  bool _sortAscending = false;  // Default to most recent first
  StreamSubscription? _networkSubscription;
  bool _wasOffline = false;  // Track previous connection state

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    
    // Modified network status handling
    _networkSubscription = NetworkService.instance.networkStatusStream.listen((hasConnection) {
      if (!mounted) return;
      
      // Only show reconnection message if we were previously offline
      if (hasConnection && _wasOffline) {
        NetworkService.instance.showReconnectedMessage(context);
        _loadExpenses();  // Reload data when connection is restored
        _wasOffline = false;
      } else if (!hasConnection) {
        NetworkService.instance.showNetworkError(context);
        _wasOffline = true;
      }
    });
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();  // Clean up subscription
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: isError
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _loadExpenses,
              )
            : null,
      ),
    );
  }

  void _filterExpenses() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredExpenses = List.from(_allExpenses);
      } else {
        _filteredExpenses = _allExpenses.where((expense) =>
              expense.name.toLowerCase().contains(searchTerm) ||
              expense.category.toLowerCase().contains(searchTerm) ||
              (expense.description?.toLowerCase() ?? '').contains(searchTerm)
            ).toList();
      }
      _sortExpenses();
    });
  }

  Future<void> _loadExpenses() async {
    if (!mounted) return;

    // Check for internet connection before loading
    final hasConnection = await NetworkService.instance.checkInternetConnection(context);
    if (!hasConnection) return;

    setState(() => _isLoading = true);
    try {
      final expenses = await SupabaseDatabase.instance.getAllExpenses();
      if (mounted) {
        setState(() {
          _allExpenses = expenses;
          _filteredExpenses = List.from(expenses);
          _sortExpenses();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading expenses: ${e.toString()}', true);
      }
    }
  }

  Future<void> _addEditExpense([Expense? expense]) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AddEditExpenseDialog(expense: expense),
      );

      if (result == true) {
        _showSnackBar(
          expense == null
              ? 'Expense added successfully'
              : 'Expense updated successfully',
          false,
        );
        _loadExpenses();
      }
    } catch (e) {
      _showSnackBar(
        'Error ${expense == null ? 'adding' : 'updating'} expense: ${e.toString()}',
        true,
      );
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Expense'),
          content: Text('Are you sure you want to delete "${expense.name}"?'),
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
        await SupabaseDatabase.instance.deleteExpense(expense.id);
        _showSnackBar('Expense deleted successfully', false);
        _loadExpenses();
      }
    } catch (e) {
      _showSnackBar('Error deleting expense: ${e.toString()}', true);
    }
  }

  void _sortExpenses() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredExpenses.sort((a, b) => _sortAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name));
          break;
        case 'amount':
          _filteredExpenses.sort((a, b) => _sortAscending
              ? a.amount.compareTo(b.amount)
              : b.amount.compareTo(a.amount));
          break;
        case 'date':
          _filteredExpenses.sort((a, b) => _sortAscending
              ? a.date.compareTo(b.date)
              : b.date.compareTo(a.date));
          break;
      }
    });
  }

  void _handleSort(SortOption option) {
    setState(() {
      switch (option) {
        case SortOption.nameAZ:
          _sortBy = 'name';
          _sortAscending = true;
          break;
        case SortOption.nameZA:
          _sortBy = 'name';
          _sortAscending = false;
          break;
        case SortOption.amountHighLow:
          _sortBy = 'amount';
          _sortAscending = false;
          break;
        case SortOption.amountLowHigh:
          _sortBy = 'amount';
          _sortAscending = true;
          break;
        case SortOption.recentlyUpdated:
          _sortBy = 'date';
          _sortAscending = false;
          break;
        case SortOption.oldestFirst:
          _sortBy = 'date';
          _sortAscending = true;
          break;
      }
      _sortExpenses();
    });
  }

  String _getSortType(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.nameZA:
        return 'name';
      case SortOption.amountHighLow:
      case SortOption.amountLowHigh:
        return 'amount';
      case SortOption.recentlyUpdated:
      case SortOption.oldestFirst:
        return 'date';
    }
  }

  bool _isAscending(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.amountLowHigh:
      case SortOption.oldestFirst:
        return true;
      case SortOption.nameZA:
      case SortOption.amountHighLow:
      case SortOption.recentlyUpdated:
        return false;
    }
  }

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
      case SortOption.nameZA:
        return Icons.sort_by_alpha;
      case SortOption.amountHighLow:
      case SortOption.amountLowHigh:
        return Icons.attach_money;
      case SortOption.recentlyUpdated:
      case SortOption.oldestFirst:
        return Icons.calendar_today;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: _handleSort,
            itemBuilder: (BuildContext context) {
              return SortOption.values.map((SortOption option) {
                return PopupMenuItem<SortOption>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        _getSortIcon(option),
                        color: _sortBy == _getSortType(option) &&
                                _sortAscending == _isAscending(option)
                            ? Theme.of(context).primaryColor
                            : null,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(option.label),
                      if (_sortBy == _getSortType(option) &&
                          _sortAscending == _isAscending(option))
                        const Spacer()
                      else
                        const SizedBox.shrink(),
                      if (_sortBy == _getSortType(option) &&
                          _sortAscending == _isAscending(option))
                        Icon(
                          Icons.check,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterExpenses();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => _filterExpenses(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = _filteredExpenses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: Text(expense.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(expense.category),
                              Text(DateFormat('MMM d, y').format(expense.date)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currencyFormat.format(expense.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  switch (action) {
                                    case 'edit':
                                      _addEditExpense(expense);
                                      break;
                                    case 'delete':
                                      _deleteExpense(expense);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpenseDetailsScreen(expenseId: expense.id),
                              ),
                            ).then((result) {
                              if (result == true) {
                                _loadExpenses();
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expenses_fab',
        onPressed: _addEditExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
} 