import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network_service.dart';
import 'dart:developer' as developer;

class AuthService {
  static final AuthService instance = AuthService._init();
  static final _supabase = Supabase.instance.client;
  Timer? _authTimer;
  Timer? _activityTimer;
  Timer? _warningTimer;
  final _inactivityDuration = const Duration(minutes: 30);
  final _warningDuration = const Duration(minutes: 25);
  bool _keepLoggedIn = false;
  final _sessionTimeoutNotifier = ValueNotifier<bool>(false);
  final _loadingNotifier = ValueNotifier<bool>(false);
  final _prefs = SharedPreferences.getInstance();
  
  ValueNotifier<bool> get sessionTimeoutNotifier => _sessionTimeoutNotifier;
  ValueNotifier<bool> get loadingNotifier => _loadingNotifier;

  AuthService._init() {
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      _loadingNotifier.value = true;
      final preferences = await SharedPreferences.getInstance();
      _keepLoggedIn = preferences.getBool('keepLoggedIn') ?? false;

      // Listen to auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        if (event == AuthChangeEvent.signedIn) {
          _startAuthTimer();
        } else if (event == AuthChangeEvent.signedOut) {
          _stopAuthTimer();
        }
      });
      
      // Check current session
      if (!_keepLoggedIn && _supabase.auth.currentUser != null) {
        await signOut(closeApp: false);
      }
    } catch (e) {
      print('Error initializing session: $e');
    } finally {
      _loadingNotifier.value = false;
    }
  }

  Future<void> signOut({bool closeApp = true}) async {
    if (!NetworkService.instance.hasConnection) {
      // Force logout even without internet
      await _forceLogout(closeApp);
      return;
    }

    try {
      _loadingNotifier.value = true;
      _stopAuthTimer();
      
      final preferences = await SharedPreferences.getInstance();
      await preferences.clear();
      
      await _supabase.auth.signOut();
      
      if (closeApp) {
        await Future.delayed(const Duration(milliseconds: 100));
        await _exitApp();
      }
    } catch (e) {
      print('Error signing out: $e');
      await _forceLogout(closeApp);
    } finally {
      _loadingNotifier.value = false;
    }
  }

  Future<void> _forceLogout(bool closeApp) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.clear();
      
      if (closeApp) {
        await _exitApp();
      }
    } catch (e) {
      print('Error during force logout: $e');
      if (closeApp) {
        await _exitApp();
      }
    }
  }

  Future<void> _exitApp() async {
    if (Platform.isAndroid) {
      await SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }

  Future<void> setKeepLoggedIn(bool value) async {
    try {
      _keepLoggedIn = value;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('keepLoggedIn', value);
      
      if (!value) {
        _startAuthTimer();
      } else {
        _stopAuthTimer();
      }
    } catch (e) {
      print('Error setting keep logged in: $e');
    }
  }

  Future<void> signIn(String email, String password, {bool keepLoggedIn = false}) async {
    if (!NetworkService.instance.hasConnection) {
      throw Exception('No internet connection. Please check your network settings.');
    }

    try {
      _loadingNotifier.value = true;
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Login failed');
      }
      
      await setKeepLoggedIn(keepLoggedIn);
      await updateLastLogin();
    } on AuthException catch (e) {
      print('Auth error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error signing in: $e');
      if (e.toString().contains('connection failed')) {
        throw Exception('Connection failed. Please check your internet connection.');
      }
      throw Exception('Failed to sign in: ${e.toString()}');
    } finally {
      _loadingNotifier.value = false;
    }
  }

  void _startAuthTimer() {
    _stopAuthTimer();
    if (!_keepLoggedIn) {
      _authTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _checkSession();
      });
      _resetActivityTimer();
    }
  }

  void _stopAuthTimer() {
    _authTimer?.cancel();
    _authTimer = null;
    _activityTimer?.cancel();
    _activityTimer = null;
    _warningTimer?.cancel();
    _warningTimer = null;
    _sessionTimeoutNotifier.value = false;
  }

  void _resetActivityTimer() {
    _activityTimer?.cancel();
    _warningTimer?.cancel();
    _sessionTimeoutNotifier.value = false;

    if (!_keepLoggedIn) {
      _warningTimer = Timer(_warningDuration, () {
        _sessionTimeoutNotifier.value = true;
      });

      _activityTimer = Timer(_inactivityDuration, () async {
        try {
          await signOut();
          print('Auto-logged out due to inactivity');
        } catch (e) {
          print('Error during auto-logout: $e');
        }
      });
    }
  }

  void userActivity() {
    if (_supabase.auth.currentUser != null && !_keepLoggedIn) {
      _resetActivityTimer();
    }
  }

  Future<void> _checkSession() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await signOut();
      }
    } catch (e) {
      print('Error checking session: $e');
      await signOut();
    }
  }

  bool get isAuthenticated => _supabase.auth.currentUser != null;
  User? get currentUser => _supabase.auth.currentUser;

  Future<DateTime?> getLastLogin() async {
    try {
      final prefs = await _prefs;
      final lastLoginStr = prefs.getString('last_login');
      return lastLoginStr != null ? DateTime.parse(lastLoginStr) : null;
    } catch (e) {
      developer.log('Error getting last login: $e', error: e);
      return null;
    }
  }

  Future<void> updateLastLogin() async {
    try {
      final prefs = await _prefs;
      await prefs.setString('last_login', DateTime.now().toIso8601String());
    } catch (e) {
      developer.log('Error updating last login: $e', error: e);
    }
  }
} 