import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/permission_status_model.dart';

class PermissionRepository {
  final SharedPreferences _prefs;
  
  // Keys for SharedPreferences
  static const String _notificationPermissionKey = 'notification_permission_status';
  static const String _locationPermissionKey = 'location_permission_status';
  
  PermissionRepository(this._prefs);
  
  // Get stored permission status
  AppPermissionStatus getStoredPermissionStatus(PermissionType type) {
    final key = _getKeyForPermissionType(type);
    final statusString = _prefs.getString(key);
    
    if (statusString == null) {
      return AppPermissionStatus.notAskedYet;
    }
    
    return AppPermissionStatus.values.firstWhere(
      (status) => status.toString() == statusString,
      orElse: () => AppPermissionStatus.notAskedYet,
    );
  }
  
  // Save permission status
  Future<void> savePermissionStatus(PermissionType type, AppPermissionStatus status) async {
    final key = _getKeyForPermissionType(type);
    await _prefs.setString(key, status.toString());
  }
  
  // Check current system permission status
  Future<AppPermissionStatus> checkSystemPermissionStatus(PermissionType type) async {
    final permission = _getPermissionFromType(type);
    final status = await permission.status;
    
    if (status.isGranted) {
      return AppPermissionStatus.granted;
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      return AppPermissionStatus.deniedPermanently;
    }
    
    // Get stored status for other cases
    return getStoredPermissionStatus(type);
  }
  
  // Request permission from system
  Future<AppPermissionStatus> requestPermission(PermissionType type) async {
    final permission = _getPermissionFromType(type);
    final result = await permission.request();
    
    if (result.isGranted) {
      return AppPermissionStatus.granted;
    } else if (result.isPermanentlyDenied || result.isRestricted) {
      return AppPermissionStatus.deniedPermanently;
    }
    
    return AppPermissionStatus.askedAndSkipped;
  }
  
  // Helper methods
  String _getKeyForPermissionType(PermissionType type) {
    switch (type) {
      case PermissionType.notification:
        return _notificationPermissionKey;
      case PermissionType.location:
        return _locationPermissionKey;
    }
  }
  
  Permission _getPermissionFromType(PermissionType type) {
    switch (type) {
      case PermissionType.notification:
        return Permission.notification;
      case PermissionType.location:
        return Permission.location;
    }
  }
} 