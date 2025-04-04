import 'dart:convert'; // For jsonDecode
import 'package:http/http.dart' as http; // Import http package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/repositories/auth_repository.dart'; // Import AuthRepository

class LocationRepository {
  static const String _lastLatKey = 'last_latitude';
  static const String _lastLngKey = 'last_longitude';
  static const String _lastAddressKey = 'last_address';
  
  // Default location (Mumbai, India)
  static const double defaultLat = 19.0760;
  static const double defaultLng = 72.8777;
  static const String defaultAddress = 'Default Location (Mumbai, India)';

  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository; // Inject AuthRepository

  // Constructor Injection
  LocationRepository(this._firestore, this._authRepository);

  // Get address from location
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
      return 'Unknown location';
    } catch (e) {
      return 'Unable to get address';
    }
  }

  // Save location to SharedPreferences
  Future<void> saveLocationLocally(Position position, String address, SharedPreferences prefs) async {
    await prefs.setDouble(_lastLatKey, position.latitude);
    await prefs.setDouble(_lastLngKey, position.longitude);
    await prefs.setString(_lastAddressKey, address);
  }

  // Get last saved location from SharedPreferences
  Future<Map<String, dynamic>?> getLastSavedLocation(SharedPreferences prefs) async {
    final hasLat = prefs.containsKey(_lastLatKey);
    final hasLng = prefs.containsKey(_lastLngKey);
    final hasAddress = prefs.containsKey(_lastAddressKey);

    if (hasLat && hasLng) {
      final lat = prefs.getDouble(_lastLatKey)!;
      final lng = prefs.getDouble(_lastLngKey)!;
      final address = hasAddress ? prefs.getString(_lastAddressKey)! : 'Unknown location';

      return {
        'latitude': lat,
        'longitude': lng,
        'address': address,
      };
    }
    return null;
  }

  // Convert Position to GeoPoint for Firestore
  GeoPoint positionToGeoPoint(Position position) {
    return GeoPoint(position.latitude, position.longitude);
  }

  Future<Map<String, dynamic>> getCurrentLocation() async {
    // Permission check should ideally happen *before* calling this,
    // e.g., in the provider or calling widget, using handleLocationPermission.
    // But keeping a basic check here for robustness is okay too.
    LocationPermission permission = await checkLocationPermission();
     if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
       // Throwing an error might be better handled by the provider
       throw Exception('Location permission not granted.');
     }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    String address = placemarks.isNotEmpty
        ? '${placemarks[0].street}, ${placemarks[0].locality}, ${placemarks[0].postalCode}, ${placemarks[0].country}'
        : 'Unknown Address';

    // Save location to Firestore
    await saveUserLocation(position.latitude, position.longitude, address);

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address,
      'isDefault': false, // Indicate it's a fetched location
    };
  }

  Future<void> saveUserLocation(double lat, double lon, String address) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({ // Use set with merge:true
          'latitude': lat,
          'longitude': lon,
          'address': address,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Merge ensures we don't overwrite other fields
        print("User location saved to Firestore.");
      } catch (e) {
         print("Error saving user location to Firestore: $e");
      }
    } else {
      print("User not logged in, cannot save location.");
    }
  }

  Future<Map<String, dynamic>> getUserLocation() async {
    final user = _authRepository.currentUser; // Use injected AuthRepository
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists &&
          doc.data()!.containsKey('latitude') &&
          doc.data()!.containsKey('longitude')) {
        return {
          'latitude': doc.data()!['latitude'],
          'longitude': doc.data()!['longitude'],
          'address': doc.data()!['address'] ?? 'No address saved',
          'isDefault': false, // Indicate it's a saved location
        };
      }
    }
    // Return default/fallback if no user or no location saved
    return {
      'latitude': defaultLat, // Use defined default
      'longitude': defaultLng, // Use defined default
      'address': 'Default Location (Not Set)',
      'isDefault': true, // Indicate it's a default/fallback
    };
  }

  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle denied case (e.g., show message)
        print('Location permissions are denied');
        return permission;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Handle permanently denied case (e.g., show message, guide to settings)
      print('Location permissions are permanently denied, we cannot request permissions.');
      return permission;
    }
    return permission;
  }

  /// 1. Get Last Saved Location (from Firestore)
  Future<Map<String, dynamic>?> getLastSavedUserLocation() async {
    final user = _authRepository.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get(
             // Try server first, then cache if offline
             const GetOptions(source: Source.serverAndCache)
        );
        if (doc.exists &&
            doc.data()!.containsKey('latitude') &&
            doc.data()!.containsKey('longitude')) {
          return {
            'latitude': doc.data()!['latitude'],
            'longitude': doc.data()!['longitude'],
            'address': doc.data()!['address'] ?? 'Saved location (no address)',
            'isDefault': false,
            'source': 'firestore', // Add source for debugging
          };
        }
      } catch (e) {
        print("Error fetching saved location from Firestore: $e");
        // Optionally try cache only if server fetch failed?
        // For simplicity, we'll proceed to the next step if error occurs.
      }
    }
    return null; // No user or no location saved
  }

  /// 2. Get Location By IP Address
  Future<Map<String, dynamic>?> getLocationByIp() async {
    try {
      // Using a free, simple IP API (replace if you have a preferred one)
      // Note: IP location can be inaccurate.
      final response = await http.get(Uri.parse('http://ip-api.com/json/?fields=status,message,lat,lon,city,regionName,country'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final lat = data['lat'];
          final lon = data['lon'];
          final address = "${data['city']}, ${data['regionName']}, ${data['country']}";

           if (lat != null && lon != null) {
             // Save this less accurate location to Firestore as well? Optional.
             // Consider if you want IP location to overwrite GPS location.
             // await saveUserLocation(lat, lon, address);

              return {
                'latitude': lat,
                'longitude': lon,
                'address': address.isNotEmpty ? address : 'IP Location (Unknown Address)',
                'isDefault': false,
                'source': 'ip-api', // Add source for debugging
              };
           }
        } else {
           print("IP API Error: ${data['message']}");
        }
      } else {
         print("IP API HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching location by IP: $e");
    }
    return null; // Failed to get location via IP
  }


  /// 3. Get Current Location (GPS)
  Future<Map<String, dynamic>?> getCurrentGpsLocation() async {
     // Check permission first
    LocationPermission permission = await handleLocationPermission();
     if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
       print("GPS Location permission not granted.");
       return null; // Return null if permission denied
     }

    try {
       Position position = await Geolocator.getCurrentPosition(
           desiredAccuracy: LocationAccuracy.high,
           // Add time limit to prevent indefinite hang
           timeLimit: const Duration(seconds: 20)
       );

      // Get address from coordinates
      String address = await _getAddressFromCoordinates(position.latitude, position.longitude);

      // Save the accurate GPS location to Firestore
      await saveUserLocation(position.latitude, position.longitude, address);

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'isDefault': false,
        'source': 'gps', // Add source for debugging
      };
    } catch (e) {
       print("Error getting GPS location: $e");
       return null; // Failed to get location via GPS
    }
  }

  /// 4. Default Location
  Map<String, dynamic> getDefaultLocation() {
    return {
      'latitude': defaultLat,
      'longitude': defaultLng,
      'address': defaultAddress,
      'isDefault': true,
      'source': 'default', // Add source for debugging
    };
  }

  // --- Helper and Utility Methods ---

  /// Helper to get address from coordinates (used by GPS method)
  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Construct a readable address
        return [
           if (place.street != null && place.street!.isNotEmpty) place.street,
           if (place.locality != null && place.locality!.isNotEmpty) place.locality,
           if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea,
           if (place.postalCode != null && place.postalCode!.isNotEmpty) place.postalCode,
           if (place.country != null && place.country!.isNotEmpty) place.country,
        ].where((s) => s != null).join(', ');
      }
      return 'Unknown location';
    } catch (e) {
      print("Error getting address from coordinates: $e");
      return 'Unable to get address';
    }
  }
} 