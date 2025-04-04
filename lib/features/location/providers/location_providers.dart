import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
// Remove Geolocator import if only used in repo
// import 'package:geolocator/geolocator.dart';
import '../repositories/location_repository.dart';
import '../../../core/service_locator.dart'; // Import GetIt locator

// Provider now gets the singleton instance from GetIt
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  // Dependencies (Firestore, AuthRepository) handled by GetIt during creation
  return locator<LocationRepository>();
});

// This provider fetches location using the repository from GetIt
final locationProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final locationRepo = ref.watch(locationRepositoryProvider); // Uses GetIt instance
  if (kDebugMode) {
    print('[LocationProvider] Starting location fetch with new priority...');
  }

  // 1. Try getting last saved location from Firestore
  if (kDebugMode) print('[LocationProvider] 1. Checking saved location...');
  Map<String, dynamic>? location = await locationRepo.getLastSavedUserLocation();
  if (location != null) {
    if (kDebugMode) print('[LocationProvider] Found saved location: $location');
    return location;
  }

  // 2. Try getting location from IP address
  if (kDebugMode) print('[LocationProvider] 2. Checking IP location...');
  location = await locationRepo.getLocationByIp();
  if (location != null) {
    if (kDebugMode) print('[LocationProvider] Found IP location: $location');
    // Optionally save IP location back to Firestore here if desired
    // await locationRepo.saveUserLocation(location['latitude'], location['longitude'], location['address']);
    return location;
  }

  // 3. Try getting current GPS location
  if (kDebugMode) print('[LocationProvider] 3. Checking GPS location...');
  location = await locationRepo.getCurrentGpsLocation(); // This now handles permissions internally and saves if successful
  if (location != null) {
    if (kDebugMode) print('[LocationProvider] Found GPS location: $location');
    // GPS location is already saved within getCurrentGpsLocation()
    return location;
  }

  // 4. Use Default Location
  if (kDebugMode) print('[LocationProvider] 4. Using default location.');
  return locationRepo.getDefaultLocation();

}, name: 'locationProvider'); // Added name for debugging clarity

// This provider fetches location using the repository from GetIt
final locationProviderOld = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final locationRepo = ref.watch(locationRepositoryProvider); // Uses GetIt instance
  if (kDebugMode) {
    print('[LocationProvider] Starting location fetch...');
  }

  try {
    // Check permission first (using repo method)
    if (kDebugMode) {
      print('[LocationProvider] Checking location permission...');
    }
    final permission = await locationRepo.handleLocationPermission();
    if (kDebugMode) {
      print('[LocationProvider] Permission status: $permission');
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      if (kDebugMode) {
        print('[LocationProvider] Permission granted. Getting current location...');
      }
      // Added timeout to prevent indefinite loading
      final locationData = await locationRepo.getCurrentLocation().timeout(
        const Duration(seconds: 20), // Adjust timeout as needed
        onTimeout: () {
            if (kDebugMode) {
              print('[LocationProvider] Get current location timed out.');
            }
            // Fallback logic on timeout
            throw Exception('Getting current location timed out.');
        },
      );
      if (kDebugMode) {
        print('[LocationProvider] Current location fetched: $locationData');
      }
      return locationData;
    } else {
      // If permission denied, get saved location from Firestore
      if (kDebugMode) {
        print('[LocationProvider] Permission denied. Fetching saved user location...');
      }
      final savedLocation = await locationRepo.getUserLocation();
       if (kDebugMode) {
         print('[LocationProvider] Saved location fetched: $savedLocation');
       }
      return savedLocation;
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('[LocationProvider] Error getting current location: $e');
      print('[LocationProvider] StackTrace: $stackTrace');
      print('[LocationProvider] Falling back to saved user location...');
    }
    // Fallback to saved location on ANY error during the process
    try {
      final savedLocation = await locationRepo.getUserLocation();
       if (kDebugMode) {
         print('[LocationProvider] Saved location fetched after error: $savedLocation');
       }
      // Return saved location, but maybe wrap the original error?
      // For now, just return the saved location.
      return savedLocation;
    } catch (fallbackError, fallbackStackTrace) {
       if (kDebugMode) {
         print('[LocationProvider] Error getting saved location during fallback: $fallbackError');
         print('[LocationProvider] Fallback StackTrace: $fallbackStackTrace');
       }
       // If fallback also fails, rethrow the fallback error to show in UI
       throw Exception('Failed to get current or saved location: $fallbackError');
    }
  } finally {
     if (kDebugMode) {
       print('[LocationProvider] Location fetch process finished.');
     }
  }
}); 