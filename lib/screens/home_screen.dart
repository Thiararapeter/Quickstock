import 'package:flutter/material.dart';
import 'inventory_list_screen.dart';
import 'dashboard_screen.dart';
import 'categories_screen.dart';
import 'parts_management_screen.dart';
import 'repair_management_screen.dart';
import 'assets_list_screen.dart';
import 'expenses_screen.dart';
import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime? _lastActivityTime;
  static const _activityThreshold = Duration(seconds: 1); // Debounce threshold

  final List<Widget> _screens = const [
    DashboardScreen(),
    InventoryListScreen(),
    PartsManagementScreen(),
    CategoriesScreen(),
    RepairManagementScreen(),
    AssetsListScreen(),
    ExpensesScreen(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Products',
    'Parts',
    'Categories',
    'Repairs',
    'Assets',
    'Expenses',
  ];

  void _onItemTapped(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Debounced user activity tracking
  void _handleUserActivity() {
    final now = DateTime.now();
    if (_lastActivityTime == null || 
        now.difference(_lastActivityTime!) > _activityThreshold) {
      _lastActivityTime = now;
      AuthService.instance.userActivity();
    }
  }

  @override
  void initState() {
    super.initState();
    AuthService.instance.sessionTimeoutNotifier.addListener(_showSessionWarning);
  }

  @override
  void dispose() {
    AuthService.instance.sessionTimeoutNotifier.removeListener(_showSessionWarning);
    super.dispose();
  }

  void _showSessionWarning() {
    if (AuthService.instance.sessionTimeoutNotifier.value && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Session Timeout Warning'),
          content: const Text('Your session will expire in 5 minutes. Would you like to stay logged in?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AuthService.instance.signOut();
              },
              child: const Text('Logout'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleUserActivity();
              },
              child: const Text('Stay Logged In'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomNavIndex = _selectedIndex >= 5 ? 0 : _selectedIndex;
    
    return GestureDetector(
      onTap: _handleUserActivity, // Use debounced handler
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
          backgroundColor: colorScheme.inversePrimary,
        ),
        drawer: AppDrawer(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
        body: IndexedStack( // Use IndexedStack instead of AnimatedSwitcher
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          height: 70,
          selectedIndex: bottomNavIndex,
          onDestinationSelected: (index) {
            if (index < 5) {
              _onItemTapped(index);
            }
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          backgroundColor: Colors.transparent,
          indicatorColor: colorScheme.primaryContainer,
          destinations: [
            _buildNavDestination(
              Icons.dashboard_outlined,
              Icons.dashboard,
              'Dashboard',
              0,
            ),
            _buildNavDestination(
              Icons.inventory_outlined,
              Icons.inventory,
              'Products',
              1,
            ),
            _buildNavDestination(
              Icons.build_outlined,
              Icons.build,
              'Parts',
              2,
            ),
            _buildNavDestination(
              Icons.category_outlined,
              Icons.category,
              'Categories',
              3,
            ),
            _buildNavDestination(
              Icons.home_repair_service_outlined,
              Icons.home_repair_service,
              'Repairs',
              4,
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    return NavigationDestination(
      icon: Icon(
        outlinedIcon,
        size: 24,
      ),
      selectedIcon: Icon(
        filledIcon,
        size: 24,
      ),
      label: label,
    );
  }
} 