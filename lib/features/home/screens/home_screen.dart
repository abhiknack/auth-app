import 'package:auth_app/features/permissions/screens/location_permission_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../location/providers/location_providers.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserProvider);
    final locationDataAsyncValue = ref.watch(locationProvider);
    final networkStatus = ref.watch(networkStatusProvider);

    final isOnline = networkStatus.maybeWhen(
      data: (status) => status,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      color: isOnline ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(locationProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              userData.when(
                data: (user) {
                  if (user == null) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('User data not available'),
                      ),
                    );
                  }
                  
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user.photoURL != null)
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(user.photoURL!),
                            ),
                          if (user.photoURL == null)
                            const CircleAvatar(
                              radius: 40,
                              child: Icon(Icons.person, size: 40),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'Name: ${user.displayName ?? 'Not set'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${user.email}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (user.phoneNumber != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Phone: ${user.phoneNumber}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: LoadingWidget()),
                error: (error, _) => Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading user data: $error'),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Location Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              locationDataAsyncValue.when(
                data: (location) {
                  final isDefaultOrSavedDueToDenial = location['isDefault'] == true;

                  if (isDefaultOrSavedDueToDenial) {
                    return Card(
                      color: Colors.amber.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text("Location permission not granted. Showing saved/default location."),
                            const SizedBox(height: 8),
                            Text('Address: ${location['address']}', style: const TextStyle(fontSize: 14)),
                            Text('Lat: ${location['latitude']}, Lng: ${location['longitude']}', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LocationPermissionScreen(),
                                  ),
                                ).then((_) {
                                   ref.invalidate(locationProvider);
                                });
                              },
                              child: const Text('Grant Location Permission'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Address: ${location['address']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Latitude: ${location['latitude']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Longitude: ${location['longitude']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                loading: () => const Center(child: LoadingWidget(key: Key('location_loading'))),
                error: (error, stackTrace) {
                  print("Error in locationData provider: $error\n$stackTrace");
                  return Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Error loading location:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('$error'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(locationProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 