import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/network_connectivity_wrapper.dart';
import 'widgets/network_status_handler.dart';
import 'services/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://qnmqoszrryyutkypkbzy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFubXFvc3pycnl5dXRreXBrYnp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI3ODc2NzksImV4cCI6MjA0ODM2MzY3OX0.0_WrVdT6Y3sPJ_xYLsBt_896VqYe4DNJsUYzIKpK9xM',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Stock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const InitialPermissionsWrapper(
        child: NetworkConnectivityWrapper(
          child: NetworkStatusHandler(
            child: AuthWrapper(),
          ),
        ),
      ),
    );
  }
}

class InitialPermissionsWrapper extends StatefulWidget {
  final Widget child;

  const InitialPermissionsWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<InitialPermissionsWrapper> createState() => _InitialPermissionsWrapperState();
}

class _InitialPermissionsWrapperState extends State<InitialPermissionsWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.requestInitialPermissions(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
