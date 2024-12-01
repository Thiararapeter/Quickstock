import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;

class NetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._init();
  
  final _connectivity = Connectivity();
  final _networkStatusController = StreamController<bool>.broadcast();
  bool _hasConnection = true;
  Timer? _retryTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isInitialized = false;
  bool _isRetrying = false;

  NetworkService._init() {
    _initConnectivity();
  }

  bool get hasConnection => _hasConnection;
  Stream<bool> get networkStatusStream => _networkStatusController.stream;

  Future<void> _initConnectivity() async {
    if (_isInitialized) return;

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result.first);

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
        _updateConnectionStatus(result.first);
      });

      _isInitialized = true;
    } catch (e) {
      developer.log('Error initializing connectivity: $e', error: e);
      _hasConnection = false;
      _networkStatusController.add(false);
      _startRetryTimer();
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final bool isConnected = result != ConnectivityResult.none;
    _hasConnection = isConnected;
    _networkStatusController.add(isConnected);
    
    if (isConnected) {
      _retryTimer?.cancel();
      _isRetrying = false;
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result.first);
    } catch (e) {
      developer.log('Error checking connectivity: $e', error: e);
      _hasConnection = false;
      _networkStatusController.add(false);
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _networkStatusController.close();
    _retryTimer?.cancel();
  }

  void showReconnectedMessage(BuildContext context) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Internet connection restored'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void showNetworkError(BuildContext context) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No internet connection'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _startRetryTimer() {
    if (_isRetrying) return;
    _isRetrying = true;
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> retryConnection() {
    return _checkConnectivity();
  }

  Future<bool> checkInternetConnection(BuildContext context) async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      _updateConnectionStatus(results.first);
      return hasConnection;
    } catch (e) {
      developer.log('Error checking internet connection: $e', error: e);
      return false;
    }
  }

  Future<void> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results.first);
    } catch (e) {
      developer.log('Error checking connectivity: $e', error: e);
      _hasConnection = false;
      _networkStatusController.add(false);
    }
  }
} 