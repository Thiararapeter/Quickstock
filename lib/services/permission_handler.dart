import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PermissionService {
  static bool _hasStoragePermission = false;

  static bool get hasStoragePermission => _hasStoragePermission;

  static Future<bool> checkStoragePermission() async {
    if (kIsWeb) {
      // Web platform doesn't need storage permission
      return true;
    }
    
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) {
      // Web platform doesn't need storage permission
      return true;
    }
    
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<void> requestInitialPermissions(BuildContext context) async {
    // First check if we already have permissions
    if (await checkStoragePermission()) {
      _hasStoragePermission = true;
      return;
    }

    // Request storage permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    // Update storage permission status
    _hasStoragePermission = statuses.values.any((status) => status.isGranted);

    // Only show dialog if permissions were denied
    if (!_hasStoragePermission && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Storage Permission'),
            content: const Text(
              'Storage permission is required for saving PDFs. You can continue using the app, but PDF export will not be available.\n\nYou can grant permission later in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue Anyway'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  AppSettings.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
    }
  }
} 