import 'dart:io';
import 'package:process_run/process_run.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  
  factory AdminService() => _instance;
  
  AdminService._internal();
  
  // Check if the app is running with admin privileges
  Future<bool> isRunningAsAdmin() async {
    if (!Platform.isWindows) {
      return false;
    }

    try {
      // Try a PowerShell command that requires admin privileges
      final result = await runExecutableArguments(
        'powershell',
        ['-Command', 'Get-Process -IncludeUserName | Out-Null'],
      );
      
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  // Restart the application with admin privileges
  Future<void> restartAsAdmin() async {
    if (!Platform.isWindows) {
      return;
    }
    
    try {
      // Get the current executable path
      final exePath = Platform.resolvedExecutable;
      
      // Use PowerShell to restart app with admin privileges
      await runExecutableArguments(
        'powershell',
        [
          '-Command', 
          'Start-Process -FilePath "$exePath" -Verb RunAs'
        ],
      );
      
      // Exit the current instance
      exit(0);
    } catch (e) {
      // Failed to restart with admin privileges
      print('Failed to restart with admin privileges: $e');
    }
  }
} 