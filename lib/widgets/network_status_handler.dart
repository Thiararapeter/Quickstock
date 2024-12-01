import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatusHandler extends StatefulWidget {
  final Widget child;

  const NetworkStatusHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NetworkStatusHandler> createState() => _NetworkStatusHandlerState();
}

class _NetworkStatusHandlerState extends State<NetworkStatusHandler> {
  bool? _previousConnectionStatus;
  SnackBar? _currentSnackBar;

  @override
  void initState() {
    super.initState();
    // Initial connection check
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    _updateConnectionStatus(results);
    
    // Then listen for subsequent changes
    connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (!mounted) return;

    // Consider connected if any result is not 'none'
    final isConnected = results.any((result) => result != ConnectivityResult.none);

    // Only show message if the connection status has actually changed
    if (_previousConnectionStatus != isConnected) {
      _previousConnectionStatus = isConnected;
      
      // Hide any existing snackbar before showing a new one
      if (_currentSnackBar != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      _showConnectionMessage(
        isConnected ? 'Internet connection restored' : 'No internet connection',
        isConnected ? Colors.green : Colors.red,
      );
    }
  }

  void _showConnectionMessage(String message, Color backgroundColor) {
    _currentSnackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      duration: const Duration(seconds: 3),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(_currentSnackBar!);
  }

  @override
  Widget build(BuildContext context) => widget.child;
} 