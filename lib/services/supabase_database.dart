import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_item.dart';
import '../models/repair_ticket.dart';
import 'dart:math';
import '../models/asset.dart';
import '../models/expense.dart';
import '../models/warranty.dart';
import '../models/sale.dart';

class SupabaseDatabase {
  static final SupabaseDatabase instance = SupabaseDatabase._init();
  static final _supabase = Supabase.instance.client;

  SupabaseDatabase._init();

  // Categories methods
  Future<List<String>> getCategories() async {
    try {
      developer.log('Fetching categories from Supabase...');
      final response = await _supabase
          .from('categories')
          .select('name')
          .eq('is_system', false)
          .order('name');
      
      final categories = List<String>.from(response.map((row) => row['name'] as String));
      developer.log('Fetched categories: $categories');
      return categories;
    } catch (e) {
      developer.log('Error fetching categories: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      } else if (e.toString().contains('JWTError')) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception('Failed to fetch categories: ${e.toString()}');
    }
  }

  // Inventory methods
  Future<List<InventoryItem>> getAllItems() async {
    try {
      developer.log('Fetching items from Supabase...');
      final response = await _supabase
          .from('inventory')
          .select()
          .order('name');
      
      final items = response.map<InventoryItem>((row) => InventoryItem.fromMap(row)).toList();
      developer.log('Fetched ${items.length} items');
      return items;
    } catch (e) {
      developer.log('Error fetching items: $e', error: e);
      rethrow;
    }
  }

  Future<void> insertItem(InventoryItem item) async {
    try {
      developer.log('Inserting new item: ${item.id}');
      final itemData = item.toMap();
      
      // Allow items to have "Parts" category, but validate other categories exist
      if (item.category != 'Parts') {
        final categories = await getCategories();
        if (!categories.contains(item.category)) {
          throw Exception('Invalid category. Please select a valid category.');
        }
      }

      await _supabase
          .from('inventory')
          .insert(itemData);

    } catch (e) {
      developer.log('Error inserting item: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('foreign key constraint')) {
          throw Exception('Invalid category. Please select a valid category.');
        } else if (e.message.contains('duplicate key')) {
          throw Exception('An item with this ID already exists.');
        } else if (e.message.contains('not-null')) {
          throw Exception('Please fill in all required fields.');
        }
        throw Exception('Database error: ${e.message}');
      } else if (e.toString().contains('JWTError')) {
        throw Exception('Your session has expired. Please log in again.');
      }
      throw Exception('Failed to save item: ${e.toString()}');
    }
  }

  Future<void> updateItem(InventoryItem item) async {
    try {
      developer.log('Updating item: ${item.id}');
      // First check if item exists
      final existing = await _supabase
          .from('inventory')
          .select()
          .eq('id', item.id)
          .single();
          
      if (existing == null) {
        throw Exception('Item not found');
      }

      // Create map without updated_at since it's handled by trigger
      final itemData = {
        'id': item.id,
        'name': item.name,
        'serial_number': item.serialNumber,
        'purchase_price': item.purchasePrice,
        'selling_price': item.sellingPrice,
        'category': item.category,
        'quantity': item.quantity,
        'condition': item.condition,
        'date_added': item.dateAdded.toIso8601String(),
        // updated_at is handled by database trigger
      };
      
      // Allow items to have "Parts" category, but validate other categories exist
      if (item.category != 'Parts') {
        final categories = await getCategories();
        if (!categories.contains(item.category)) {
          throw Exception('Invalid category. Please select a valid category.');
        }
      }

      // Track changes for history
      final oldItem = InventoryItem.fromMap(existing);
      
      // Update the item
      await _supabase
          .from('inventory')
          .update(itemData)
          .eq('id', item.id);

      // Record price changes if any
      if (oldItem.purchasePrice != item.purchasePrice) {
        await recordPriceChange(
          item.id,
          oldItem.purchasePrice,
          item.purchasePrice,
          'purchase',
        );
      }
      
      if (oldItem.sellingPrice != item.sellingPrice) {
        await recordPriceChange(
          item.id,
          oldItem.sellingPrice,
          item.sellingPrice,
          'selling',
        );
      }

      // Record quantity changes if any
      if (oldItem.quantity != item.quantity) {
        await recordQuantityChange(
          item.id,
          oldItem.quantity,
          item.quantity,
        );
      }

    } catch (e) {
      developer.log('Error updating item: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('foreign key constraint')) {
          throw Exception('Invalid category. Please select a valid category.');
        } else if (e.message.contains('duplicate key')) {
          throw Exception('An item with this ID already exists.');
        } else if (e.message.contains('not-null')) {
          throw Exception('Please fill in all required fields.');
        }
        throw Exception('Database error: ${e.message}');
      } else if (e.toString().contains('JWTError')) {
        throw Exception('Your session has expired. Please log in again.');
      }
      throw Exception('Failed to update item: ${e.toString()}');
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      // Start a transaction
      await _supabase.rpc('begin_transaction');

      // Check if item exists and get its details
      final existing = await _supabase
          .from('inventory')
          .select()
          .eq('id', id)
          .single();
          
      if (existing == null) {
        throw Exception('Item not found. It may have been deleted.');
      }

      // If it's a product with parts, restore all parts first
      if (existing['category'] != 'Parts') {
        // Get all attached parts
        final attachedParts = await _supabase
            .from('product_parts')
            .select('part_id, inventory!part_id(*)')
            .eq('product_id', id);

        // Restore each part's quantity and remove the product-part relationship
        for (final partData in attachedParts) {
          final part = InventoryItem.fromMap(partData['inventory']);
          
          // Increase part quantity by 1
          await _supabase
              .from('inventory')
              .update({'quantity': part.quantity + 1})
              .eq('id', partData['part_id']);

          // Add history record for the part
          await addHistory(
            partData['part_id'],
            'PRODUCT_DELETED',
            'Part restored due to product deletion',
          );
        }

        // Remove all product-part relationships
        await _supabase
            .from('product_parts')
            .delete()
            .eq('product_id', id);
      }

      // Finally delete the item
      await _supabase
          .from('inventory')
          .delete()
          .eq('id', id);

      await _supabase.rpc('commit_transaction');
    } catch (e) {
      await _supabase.rpc('rollback_transaction');
      developer.log('Error deleting item: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('foreign key constraint')) {
          throw Exception('Cannot delete this item as it is referenced by other items.');
        }
        throw Exception('Database error: ${e.message}');
      } else if (e.toString().contains('JWTError')) {
        throw Exception('Your session has expired. Please log in again.');
      }
      throw Exception('Failed to delete item: ${e.toString()}');
    }
  }

  // Product Parts methods
  Future<List<InventoryItem>> getProductParts(String productId) async {
    final response = await _supabase
        .from('product_parts')
        .select('''
          inventory!part_id(*),
          parts_category
        ''')
        .eq('product_id', productId);
    
    return response.map<InventoryItem>((row) {
      final item = InventoryItem.fromMap(row['inventory']);
      // You might want to add parts_category to your InventoryItem model
      return item;
    }).toList();
  }

  Future<void> addPartToProduct(String productId, String partId, {String partsCategory = 'Component'}) async {
    try {
      // Get the part to check its quantity
      final partResponse = await _supabase
          .from('inventory')
          .select()
          .eq('id', partId)
          .single();
      
      final part = InventoryItem.fromMap(partResponse);
      
      if (part.quantity <= 0) {
        throw Exception('Part is out of stock');
      }

      // Add the part to product_parts
      await _supabase
          .from('product_parts')
          .insert({
            'product_id': productId,
            'part_id': partId,
            'parts_category': partsCategory,
          });

      // Decrease the part's quantity by 1
      await _supabase
          .from('inventory')
          .update({'quantity': part.quantity - 1})
          .eq('id', partId);

      // Add to history
      await addHistory(
        productId,
        'PART_ADDED',
        'Added part to product',
        partId: partId,
      );

    } catch (e) {
      developer.log('Error adding part to product: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('duplicate key')) {
          throw Exception('This part is already attached to the product');
        } else if (e.message.contains('foreign key constraint')) {
          throw Exception('Invalid product or part ID');
        }
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to add part: ${e.toString()}');
    }
  }

  Future<void> removePartFromProduct(String productId, String partId) async {
    try {
      // Remove the product-part relationship
      await _supabase
          .from('product_parts')
          .delete()
          .eq('product_id', productId)
          .eq('part_id', partId);

      // Update the part's quantity (increment by 1 since it's no longer used)
      final part = await getItem(partId);
      if (part != null) {
        await _supabase
            .from('inventory')
            .update({'quantity': part.quantity + 1})
            .eq('id', partId);
      }

      // Add history record for part removal
      await addHistory(
        productId,
        'PART_REMOVED',
        'Part removed from product',
        partId: partId,
      );

    } catch (e) {
      developer.log('Error removing part from product: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to remove part: ${e.toString()}');
    }
  }

  // Product History methods
  Future<void> addHistory(
    String productId,
    String actionType,
    String description, {
    String? partId,
    double? oldPrice,
    double? newPrice,
  }) async {
    try {
      await _supabase.from('product_history').insert({
        'product_id': productId,
        'part_id': partId,
        'action_type': actionType,
        'description': description,
        'old_price': oldPrice,
        'new_price': newPrice,
        // Let Postgres handle the date
      });
    } catch (e) {
      developer.log('Error adding history: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to add history: ${e.toString()}');
    }
  }

  // Add this method
  Future<void> addCategory(String name) async {
    try {
      // Only check for exact "Parts" category name
      if (name == 'Parts') {
        throw Exception('Cannot create "Parts" as it is a reserved category name');
      }

      await _supabase
          .from('categories')
          .insert({
            'name': name,
            'is_system': false,
          });
      
      developer.log('Category added successfully: $name');
    } catch (e) {
      developer.log('Error adding category: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('duplicate key')) {
          throw Exception('A category with this name already exists');
        }
      }
      rethrow;
    }
  }

  Future<bool> hasData() async {
    try {
      final response = await _supabase
          .from('inventory')
          .select('id')
          .limit(1);
      return response.isNotEmpty;
    } catch (e) {
      developer.log('Error checking for data: $e', error: e);
      return false;
    }
  }

  Future<bool> isPartUsedInProduct(String partId) async {
    try {
      final response = await _supabase
          .from('product_parts')
          .select()
          .eq('part_id', partId)
          .limit(1);
      return response.isNotEmpty;
    } catch (e) {
      developer.log('Error checking if part is used: $e', error: e);
      rethrow;
    }
  }

  Future<List<InventoryItem>> getUnattachedProducts() async {
    try {
      // First get all part IDs that are attached to products
      final attachedPartsResponse = await _supabase
          .from('product_parts')
          .select('part_id');
      
      final attachedPartIds = attachedPartsResponse
          .map((row) => row['part_id'] as String)
          .toList();

      // Then get all parts that are not in the attached parts list
      final response = await _supabase
          .from('inventory')
          .select()
          .eq('category', 'Parts')
          .not('id', 'in', attachedPartIds.isEmpty ? [''] : attachedPartIds);

      return response.map<InventoryItem>((row) => InventoryItem.fromMap(row)).toList();
    } catch (e) {
      developer.log('Error getting unattached products: $e', error: e);
      rethrow;
    }
  }

  Future<List<InventoryItem>> getProductsWithoutPart() async {
    try {
      final response = await _supabase
          .from('inventory')
          .select()
          .neq('category', 'Parts');
      
      return response.map<InventoryItem>((row) => InventoryItem.fromMap(row)).toList();
    } catch (e) {
      developer.log('Error fetching products: $e', error: e);
      rethrow;
    }
  }

  Future<InventoryItem?> getItem(String id) async {
    try {
      final response = await _supabase
          .from('inventory')
          .select()
          .eq('id', id)
          .single();
      
      return InventoryItem.fromMap(response);
    } catch (e) {
      developer.log('Error getting item: $e', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPartHistory(String productId) async {
    try {
      final response = await _supabase
          .from('product_history')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('Error getting part history: $e', error: e);
      rethrow;
    }
  }

  Future<void> deleteCategory(String name) async {
    try {
      // Check if any items are using this category
      final items = await _supabase
          .from('inventory')
          .select('id')
          .eq('category', name);
      
      if (items.isNotEmpty) {
        throw Exception('Cannot delete category that is in use');
      }

      await _supabase
          .from('categories')
          .delete()
          .eq('name', name)
          .eq('is_system', false);  // Only allow deleting user-created categories
    } catch (e) {
      developer.log('Error deleting category: $e', error: e);
      rethrow;
    }
  }

  Future<void> updateCategory(String oldName, String newName) async {
    try {
      // Check if new category name is reserved
      if (newName.toLowerCase() == 'parts') {
        throw Exception('Cannot rename to "Parts" as it is a reserved category name');
      }

      await _supabase
          .from('categories')
          .update({'name': newName})
          .eq('name', oldName)
          .eq('is_system', false);  // Only allow updating user-created categories
    } catch (e) {
      developer.log('Error updating category: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('duplicate key')) {
          throw Exception('A category with this name already exists');
        }
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getProductHistory(String productId) async {
    try {
      // First, get the creation history
      final creationHistory = await _supabase
          .from('product_history')
          .select('''
            id,
            action_type,
            description,
            old_price,
            new_price,
            created_at,
            inventory!part_id (
              id,
              name,
              serial_number
            )
          ''')
          .eq('product_id', productId)
          .eq('action_type', 'PRODUCT_CREATED')
          .order('created_at', ascending: false);

      // Then get the last 3 non-creation history items
      final recentHistory = await _supabase
          .from('product_history')
          .select('''
            id,
            action_type,
            description,
            old_price,
            new_price,
            created_at,
            inventory!part_id (
              id,
              name,
              serial_number
            )
          ''')
          .eq('product_id', productId)
          .neq('action_type', 'PRODUCT_CREATED')
          .order('created_at', ascending: false)
          .limit(3);
      
      // Combine both lists with creation history first
      final combinedHistory = [
        ...List<Map<String, dynamic>>.from(creationHistory),
        ...List<Map<String, dynamic>>.from(recentHistory),
      ];

      // Sort by created_at in descending order
      combinedHistory.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });
      
      return combinedHistory;
    } catch (e) {
      developer.log('Error getting product history: $e', error: e);
      rethrow;
    }
  }

  // Add method to record price changes
  Future<void> recordPriceChange(
    String productId, 
    double oldPrice, 
    double newPrice,
    String priceType
  ) async {
    try {
      await addHistory(
        productId,
        'PRICE_CHANGED',
        '${priceType.toUpperCase()} price changed from KSH ${oldPrice.toStringAsFixed(2)} to KSH ${newPrice.toStringAsFixed(2)}',
        oldPrice: oldPrice,
        newPrice: newPrice,
      );
    } catch (e) {
      developer.log('Error recording price change: $e', error: e);
      rethrow;
    }
  }

  // Add method to record quantity changes
  Future<void> recordQuantityChange(
    String productId,
    int oldQuantity,
    int newQuantity,
  ) async {
    try {
      await addHistory(
        productId,
        'QUANTITY_CHANGED',
        'Quantity changed from $oldQuantity to $newQuantity',
      );
    } catch (e) {
      developer.log('Error recording quantity change: $e', error: e);
      rethrow;
    }
  }

  Future<List<InventoryItem>> getParts() async {
    try {
      final response = await _supabase
          .from('inventory')
          .select()
          .eq('category', 'Parts')
          .order('name');
      
      return response.map<InventoryItem>((row) => InventoryItem.fromMap(row)).toList();
    } catch (e) {
      developer.log('Error fetching parts: $e', error: e);
      rethrow;
    }
  }

  Future<List<InventoryItem>> getProducts() async {
    try {
      final response = await _supabase
          .from('inventory')
          .select()
          .neq('category', 'Parts')
          .order('name');
      
      return response.map<InventoryItem>((row) => InventoryItem.fromMap(row)).toList();
    } catch (e) {
      developer.log('Error fetching products: $e', error: e);
      rethrow;
    }
  }

  // Repair Management Methods
  Future<String> generateTicketNumber() async {
    try {
      // Get the current highest ticket number
      final response = await _supabase
          .from('repair_tickets')
          .select('ticket_number')
          .order('ticket_number', ascending: false)
          .limit(1)
          .single();

      if (response != null) {
        final lastNumber = int.parse(response['ticket_number'].substring(7));
        return 'TICKET${(lastNumber + 1).toString().padLeft(7, '0')}';
      }
      
      return 'TICKET0000001';
    } catch (e) {
      return 'TICKET0000001';
    }
  }

  String generateTrackingId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<RepairTicket> createRepairTicket(RepairTicket ticket) async {
    try {
      final response = await _supabase
          .from('repair_tickets')
          .insert(ticket.toMap())
          .select()
          .single();
      
      return RepairTicket.fromMap(response);
    } catch (e) {
      developer.log('Error creating repair ticket: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to create repair ticket: ${e.toString()}');
    }
  }

  Future<RepairTicket> updateRepairTicket(RepairTicket ticket) async {
    try {
      final response = await _supabase
          .from('repair_tickets')
          .update(ticket.toMap())
          .eq('id', ticket.id)
          .select()
          .single();
      
      return RepairTicket.fromMap(response);
    } catch (e) {
      developer.log('Error updating repair ticket: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to update repair ticket: ${e.toString()}');
    }
  }

  Future<List<RepairTicket>> getAllRepairTickets() async {
    try {
      developer.log('Fetching repair tickets from Supabase...');
      final response = await _supabase
          .from('repair_tickets')
          .select()
          .order('date_created', ascending: false);
      
      final tickets = response.map<RepairTicket>((row) => RepairTicket.fromMap(row)).toList();
      developer.log('Fetched ${tickets.length} repair tickets');
      return tickets;
    } catch (e) {
      developer.log('Error fetching repair tickets: $e', error: e);
      rethrow;
    }
  }

  Future<RepairTicket?> getRepairTicketByTrackingId(String trackingId) async {
    try {
      final response = await _supabase
          .from('repair_tickets')
          .select()
          .eq('tracking_id', trackingId)
          .single();
      
      return RepairTicket.fromMap(response);
    } catch (e) {
      developer.log('Error fetching repair ticket: $e', error: e);
      return null;
    }
  }

  Future<void> addPartToRepair(String repairId, String partId) async {
    try {
      // First, check if the part exists and has enough quantity
      final part = await getItem(partId);
      if (part == null || part.quantity <= 0) {
        throw Exception('Part not available in inventory');
      }

      // Add part to repair ticket's used parts
      final ticket = await _supabase
          .from('repair_tickets')
          .select()
          .eq('id', repairId)
          .single();
      
      final currentParts = List<String>.from(ticket['used_part_ids'] ?? []);
      if (!currentParts.contains(partId)) {
        currentParts.add(partId);
        
        await _supabase
            .from('repair_tickets')
            .update({'used_part_ids': currentParts})
            .eq('id', repairId);

        // Decrease part quantity
        await _supabase
            .from('inventory')
            .update({'quantity': part.quantity - 1})
            .eq('id', partId);
      }
    } catch (e) {
      developer.log('Error adding part to repair: $e', error: e);
      rethrow;
    }
  }

  Future<void> removePartFromRepair(String repairId, String partId) async {
    try {
      // Get the current repair ticket
      final ticket = await _supabase
          .from('repair_tickets')
          .select()
          .eq('id', repairId)
          .single();
      
      final currentParts = List<String>.from(ticket['used_part_ids'] ?? []);
      if (currentParts.contains(partId)) {
        currentParts.remove(partId);
        
        await _supabase
            .from('repair_tickets')
            .update({'used_part_ids': currentParts})
            .eq('id', repairId);

        // Increase part quantity back in inventory
        final part = await getItem(partId);
        if (part != null) {
          await _supabase
              .from('inventory')
              .update({'quantity': part.quantity + 1})
              .eq('id', partId);
        }
      }
    } catch (e) {
      developer.log('Error removing part from repair: $e', error: e);
      rethrow;
    }
  }

  Future<void> deleteRepairTicket(String ticketId) async {
    try {
      await _supabase
          .from('repair_tickets')
          .delete()
          .eq('id', ticketId);
    } catch (e) {
      developer.log('Error deleting repair ticket: $e', error: e);
      rethrow;
    }
  }

  // Asset management methods
  Future<List<Asset>> getAssets() async {
    try {
      final response = await _supabase
          .from('assets')
          .select()
          .order('name');
      
      return (response as List)
          .map((json) => Asset.fromMap(json))
          .toList();
    } catch (e) {
      developer.log('Error fetching assets: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to fetch assets');
    }
  }

  Future<void> addAsset(Asset asset) async {
    try {
      await _supabase.from('assets').insert(asset.toMap());
    } catch (e) {
      developer.log('Error adding asset: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('not-null')) {
          throw Exception('Please fill in all required fields');
        }
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to add asset');
    }
  }

  Future<void> updateAsset(Asset asset) async {
    try {
      await _supabase
          .from('assets')
          .update(asset.toMap())
          .eq('id', asset.id);
    } catch (e) {
      developer.log('Error updating asset: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('not-null')) {
          throw Exception('Please fill in all required fields');
        }
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to update asset');
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      await _supabase.from('assets').delete().eq('id', id);
    } catch (e) {
      developer.log('Error deleting asset: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to delete asset');
    }
  }

  Future<List<Expense>> getExpenses() async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .order('date', ascending: false);
      
      return (response as List)
          .map((json) => Expense.fromJson(json))
          .toList();
    } catch (e) {
      developer.log('Error fetching expenses: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to fetch expenses');
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _supabase.from('expenses').insert(expense.toJson());
    } catch (e) {
      developer.log('Error adding expense: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('not-null')) {
          throw Exception('Please fill in all required fields');
        }
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to add expense');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _supabase
          .from('expenses')
          .update(expense.toJson())
          .eq('id', expense.id);
    } catch (e) {
      developer.log('Error updating expense: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('not-null')) {
          throw Exception('Please fill in all required fields');
        }
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to update expense');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _supabase.from('expenses').delete().eq('id', id);
    } catch (e) {
      developer.log('Error deleting expense: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to delete expense');
    }
  }

  Future<List<RepairTicket>> getRepairTickets() async {
    try {
      developer.log('Fetching repair tickets from Supabase...');
      final response = await _supabase
          .from('repair_tickets')
          .select()
          .order('date_created', ascending: false);
      
      final tickets = response.map<RepairTicket>((data) => RepairTicket.fromMap(data)).toList();
      developer.log('Fetched ${tickets.length} repair tickets');
      return tickets;
    } catch (e) {
      developer.log('Error fetching repair tickets: $e', error: e);
      rethrow;
    }
  }

  Future<Asset?> getAsset(String id) async {
    try {
      final response = await _supabase
          .from('assets')
          .select()
          .eq('id', id)
          .single();
      
      if (response == null) {
        return null;
      }
      
      return Asset.fromMap(response);
    } catch (e) {
      developer.log('Error fetching asset: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to fetch asset');
    }
  }

  Future<Expense?> getExpense(String id) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('id', id)
          .single();
      
      return Expense.fromJson(response);
    } catch (e) {
      developer.log('Error fetching expense: $e', error: e);
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to fetch expense');
    }
  }

  // Add this method to the SupabaseDatabase class
  Future<List<Expense>> getAllExpenses() async {
    try {
      developer.log('Fetching expenses from Supabase...');
      final response = await _supabase
          .from('expenses')
          .select()
          .order('date', ascending: false);
      
      final expenses = response.map<Expense>((row) => Expense.fromJson(row)).toList();
      developer.log('Fetched ${expenses.length} expenses');
      return expenses;
    } catch (e) {
      developer.log('Error fetching expenses: $e', error: e);
      if (e is PostgrestException) {
        if (e.message.contains('JWT')) {
          throw Exception('Session expired. Please log in again.');
        }
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to fetch expenses: ${e.toString()}');
    }
  }

  // Warranty methods
  Future<void> addWarranty(Warranty warranty) async {
    try {
      // First check if warranty exists for this item
      final existing = await getWarranty(warranty.itemId);
      
      if (existing != null) {
        // Update existing warranty
        await updateWarranty(warranty);
      } else {
        // Insert new warranty
        await _supabase
            .from('warranties')
            .insert(warranty.toMap());
      }
    } catch (e) {
      developer.log('Error adding warranty: $e', error: e);
      rethrow;
    }
  }

  Future<void> updateWarranty(Warranty warranty) async {
    try {
      await _supabase
          .from('warranties')
          .update({
            'start_date': warranty.startDate.toIso8601String(),
            'end_date': warranty.endDate.toIso8601String(),
            'period': warranty.period,
            'supplier': warranty.supplier,
            'terms': warranty.terms,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('item_id', warranty.itemId); // Change from id to item_id
    } catch (e) {
      developer.log('Error updating warranty: $e', error: e);
      rethrow;
    }
  }

  Future<Warranty?> getWarranty(String itemId) async {
    try {
      final response = await _supabase
          .from('warranties')
          .select()
          .eq('item_id', itemId)
          .maybeSingle();
      
      return response != null ? Warranty.fromMap(response) : null;
    } catch (e) {
      developer.log('Error getting warranty: $e', error: e);
      return null;
    }
  }

  Future<List<Warranty>> getAllWarranties() async {
    try {
      final response = await _supabase
          .from('warranties')
          .select()
          .order('end_date');
      
      if (response == null) return [];
      
      return response.map<Warranty>((row) => Warranty.fromMap(row)).toList();
    } catch (e) {
      developer.log('Error getting warranties: $e', error: e);
      return [];
    }
  }

  Future<List<Warranty>> getExpiringWarranties() async {
    try {
      final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
      final response = await _supabase
          .from('warranties')
          .select()
          .lte('end_date', thirtyDaysFromNow.toIso8601String())
          .gte('end_date', DateTime.now().toIso8601String())
          .order('end_date');
      
      return response.map<Warranty>((row) => Warranty.fromMap(row)).toList();
    } catch (e) {
      developer.log('Error getting expiring warranties: $e', error: e);
      rethrow;
    }
  }

  Future<bool> hasWarranty(String itemId) async {
    try {
      final response = await _supabase
          .from('warranties')
          .select('id')
          .eq('item_id', itemId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      developer.log('Error checking warranty: $e', error: e);
      return false;
    }
  }

  // Add this method to the SupabaseDatabase class
  Future<void> deleteWarranty(String id) async {
    try {
      await _supabase
          .from('warranties')
          .delete()
          .eq('id', id);
    } catch (e) {
      developer.log('Error deleting warranty: $e', error: e);
      rethrow;
    }
  }

  Future<void> addSale(Sale sale) async {
    try {
      // First, update the inventory quantity
      final item = await getItem(sale.itemId);
      if (item == null) throw Exception('Item not found');
      
      final newQuantity = item.quantity - sale.quantitySold;
      if (newQuantity < 0) throw Exception('Not enough items in stock');
      
      // Start a transaction
      await _supabase.rpc('begin_transaction');
      
      // Update inventory
      await _supabase
          .from('inventory')
          .update({'quantity': newQuantity})
          .eq('id', sale.itemId);
      
      // Record the sale
      await _supabase
          .from('sales')
          .insert(sale.toJson());
      
      await _supabase.rpc('commit_transaction');
    } catch (e) {
      await _supabase.rpc('rollback_transaction');
      throw Exception('Failed to record sale: $e');
    }
  }

  Future<List<Sale>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      var query = _supabase
          .from('sales')
          .select();
      
      if (startDate != null) {
        query = query.gte('sale_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('sale_date', endDate.toIso8601String());
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      
      final response = await query.order('sale_date', ascending: false);
      return (response as List)
          .map((json) => Sale.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch sales: $e');
    }
  }
} 