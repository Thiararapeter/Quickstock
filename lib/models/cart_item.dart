import 'inventory_item.dart';

class CartItem {
  final InventoryItem item;
  int quantity;
  double get total => item.sellingPrice * quantity;

  CartItem({required this.item, this.quantity = 1});
} 