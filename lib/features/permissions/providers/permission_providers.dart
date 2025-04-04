import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/permission_repository.dart';
import '../models/permission_status_model.dart';
import '../../../core/service_locator.dart'; // Import GetIt locator

// Provider now gets the singleton instance from GetIt
final permissionRepositoryProvider = Provider<PermissionRepository>((ref) {
  // SharedPreferences dependency is handled by GetIt during PermissionRepository creation
  return locator<PermissionRepository>();
});

final permissionControllerProvider = StateNotifierProvider<PermissionController, AsyncValue<void>>((ref) {
  return PermissionController(ref);
});

class PermissionController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  
  PermissionController(this._ref) : super(const AsyncValue.data(null));
  
  // Use ref.read to get the provider, which internally uses GetIt instance
  PermissionRepository get _permissionRepo => _ref.read(permissionRepositoryProvider);
  
  // Check if permission needs to be requested
  Future<bool> shouldShowPermissionExplanation(PermissionType type) async {
    // Use the getter
    final systemStatus = await _permissionRepo.checkSystemPermissionStatus(type);
    
    // If the permission is already granted or permanently denied by the system,
    // update our stored status and don't show explanation
    if (systemStatus == AppPermissionStatus.granted || 
        systemStatus == AppPermissionStatus.deniedPermanently) {
      await _permissionRepo.savePermissionStatus(type, systemStatus);
      return false;
    }
    
    // Get the stored status
    final storedStatus = _permissionRepo.getStoredPermissionStatus(type);
    
    // Show explanation if it's not asked yet or was skipped previously
    return storedStatus == AppPermissionStatus.notAskedYet || 
           storedStatus == AppPermissionStatus.askedAndSkipped;
  }
  
  // Mark permission as skipped
  Future<void> skipPermission(PermissionType type) async {
    await _permissionRepo.savePermissionStatus(type, AppPermissionStatus.askedAndSkipped);
  }
  
  // Request permission from system
  Future<AppPermissionStatus> requestPermission(PermissionType type) async {
    state = const AsyncValue.loading();
    try {
      final status = await _permissionRepo.requestPermission(type);
      await _permissionRepo.savePermissionStatus(type, status);
      state = const AsyncValue.data(null);
      return status;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      // Consider saving askedAndSkipped on error? Or let it retry?
      // await _permissionRepo.savePermissionStatus(type, AppPermissionStatus.askedAndSkipped);
      return AppPermissionStatus.askedAndSkipped; // Or rethrow maybe
    }
  }
} 