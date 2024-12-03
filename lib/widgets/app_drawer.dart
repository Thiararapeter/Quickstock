import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/warranty_list_screen.dart';
import '../screens/about_screen.dart';
import '../screens/sales_screen.dart';
import '../screens/pos_settings_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/sales_report_screen.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
            ),
            child: Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Stock',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (currentUser?.email ?? 'Not signed in').length > 10
                        ? '${(currentUser?.email ?? 'Not signed in').substring(0, 10)}...'
                        : (currentUser?.email ?? 'Not signed in'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Overview Section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'OVERVIEW',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  label: 'Dashboard',
                  index: 0,
                  context: context,
                ),

                // Sales Section - Moved here before Inventory
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'SALES',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.point_of_sale),
                  title: const Text('POS'),
                  selected: selectedIndex == 1,
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    onItemTapped(1);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const SalesScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('All Sales'),
                  selected: selectedIndex == 2,
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    onItemTapped(2);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const SalesReportScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  index: 9,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const POSSettingsScreen()),
                    );
                  },
                  context: context,
                ),

                // Inventory Section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'INVENTORY',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2,
                  label: 'Products',
                  index: 3,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.build_outlined,
                  selectedIcon: Icons.build,
                  label: 'Parts',
                  index: 4,
                  context: context,
                ),
                _buildDrawerItem(
                  icon: Icons.category_outlined,
                  selectedIcon: Icons.category,
                  label: 'Categories',
                  index: 5,
                  context: context,
                ),

                // Services Section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'SERVICES',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.home_repair_service_outlined,
                  selectedIcon: Icons.home_repair_service,
                  label: 'Repairs',
                  index: 6,
                  context: context,
                ),

                // Add Reports Section before Finances
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'REPORTS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.assessment_outlined,
                  selectedIcon: Icons.assessment,
                  label: 'Reports',
                  index: 10,  // New index for reports
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportsScreen(),
                      ),
                    );
                  },
                  context: context,
                ),

                // Add Finances Section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'FINANCES',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet,
                  label: 'Expenses',
                  index: 7,
                  context: context,
                ),

                // Assets Section Header
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'ASSETS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Assets menu item
                _buildDrawerItem(
                  icon: Icons.precision_manufacturing_outlined,
                  selectedIcon: Icons.precision_manufacturing,
                  label: 'Assets',
                  index: 8,
                  context: context,
                ),

                // Add Warranty Management item
                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: const Text('Warranty Management'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const WarrantyListScreen(),
                      ),
                    );
                  },
                ),

                // Add About item
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout & Exit',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context); // Close drawer first
              await AuthService.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required BuildContext context,
    Function()? onTap,
  }) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.transparent, // Remove default selected color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap ?? () => onItemTapped(index),
      ),
    );
  }

  String _formatLastLogin(DateTime? lastLogin) {
    if (lastLogin == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(lastLogin);
    }
  }
} 