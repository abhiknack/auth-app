import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../features/auth/repositories/auth_repository.dart';
import '../features/location/repositories/location_repository.dart';
import '../features/permissions/repositories/permission_repository.dart';
// Import other necessary services or repositories if you have them

// Global instance of GetIt
final locator = GetIt.instance;

Future<void> setupLocator() async {
  // --- External Packages ---

  // SharedPreferences (Async Singleton)
  // Registering as Future since it needs to be awaited
  locator.registerSingletonAsync<SharedPreferences>(() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs;
  });

  // Firebase & Google Sign In (Registering instances directly)
  locator.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  locator.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  locator.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  // Geolocation/Geocoding (Can register instances or factories if needed)
  // For now, let's assume LocationRepository handles these internally

  // --- Repositories (Lazy Singletons) ---

  // Auth Repository
  locator.registerLazySingleton<AuthRepository>(() => AuthRepository(
        locator<FirebaseAuth>(), // Get registered instance
        locator<FirebaseFirestore>(),
        locator<GoogleSignIn>(),
      ));

  // Permission Repository
  // Depends on SharedPreferences, so we ensure SharedPreferences is ready
  locator.registerLazySingleton<PermissionRepository>(() => PermissionRepository(
        locator<SharedPreferences>(), // Get registered instance
      ));

  // Location Repository
  // Depends on Firestore and Auth, ensure they are available if needed directly
  // Assuming LocationRepository gets user ID via AuthRepository instance
  locator.registerLazySingleton<LocationRepository>(() => LocationRepository(
        locator<FirebaseFirestore>(),
        locator<AuthRepository>(), // Inject AuthRepository
      ));

  // --- Services / Use Cases (if any) ---
  // Register other services here

  // Ensure all asynchronous singletons are ready
  await locator.allReady();
} 