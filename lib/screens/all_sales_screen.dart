import 'package:flutter/material.dart';
import '../services/supabase_database.dart';
import '../models/sale.dart';
import '../widgets/sale_receipt.dart';
import '../models/cart_item.dart';
import '../models/inventory_item.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart'; // Import AppDrawer

class AllSalesScreen extends StatefulWidget {
  const AllSalesScreen({Key? key}) : super(key: key);

  @override
  _AllSalesScreenState createState() => _AllSalesScreenState();
}

class _AllSalesScreenState extends State<AllSalesScreen> {
  late Future<List<Sale>> _salesFuture;

  @override
  void initState() {
    super.initState();
    _salesFuture = SupabaseDatabase.instance.getSales();
  }

  void _printReceipt(Sale sale) {
    // Convert Sale to CartItem
    final item = InventoryItem(
      id: sale.itemId,
      name: sale.itemName,
      serialNumber: '',  // Add appropriate serial number if available
      purchasePrice: 0,  // Add appropriate purchase price if needed
      sellingPrice: sale.sellingPrice,
      category: sale.category,
      quantity: sale.quantitySold,
      condition: 'New',  // Add appropriate condition if available
      dateAdded: sale.saleDate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaleReceipt(
          cart: [CartItem(item: item, quantity: sale.quantitySold)],
          customerName: sale.customerName ?? 'Walk-in Customer',
          customerPhone: sale.customerPhone ?? '-',
          paymentMethod: sale.paymentMethod,
          receiptNumber: sale.receiptId,
          saleDate: sale.saleDate,
        ),
      ),
    );
  }

  void _showSaleDetails(Sale sale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sale Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Sale ID:', sale.id),
                _detailRow('Item:', sale.itemName),
                _detailRow('Category:', sale.category),
                _detailRow('Quantity:', '${sale.quantitySold}'),
                _detailRow('Price per Item:', 'KSH ${sale.sellingPrice}'),
                _detailRow('Total:', 'KSH ${sale.totalPrice}'),
                _detailRow('Date:', DateFormat('MMM dd, yyyy').format(sale.saleDate)),
                _detailRow('Payment Method:', sale.paymentMethod),
                if (sale.customerName != null)
                  _detailRow('Customer:', sale.customerName!),
                if (sale.customerPhone != null)
                  _detailRow('Phone:', sale.customerPhone!),
                if (sale.transactionCode != null)
                  _detailRow('Transaction Code:', sale.transactionCode!),
                if (sale.notes != null && sale.notes!.isNotEmpty)
                  _detailRow('Notes:', sale.notes!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _printReceipt(sale);
              },
              child: const Text('Print Receipt'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Sales'),
      ),
      drawer: AppDrawer(
        selectedIndex: 2,  // Index for All Sales
        onItemTapped: (index) {
          // Handle drawer item selection
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Sale>>(
          future: _salesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No sales found.'));
            }

            final sales = snapshot.data!;
            return ListView.builder(
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.blue),
                    title: Text(
                      sale.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: KSH ${sale.totalPrice}'),
                        Text(
                          'Date: ${DateFormat('MMM dd, yyyy').format(sale.saleDate)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _showSaleDetails(sale),
                          tooltip: 'View Details',
                        ),
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.green),
                          onPressed: () => _printReceipt(sale),
                          tooltip: 'Print Receipt',
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
