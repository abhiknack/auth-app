import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permission_providers.dart';
import '../models/permission_status_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../home/screens/home_screen.dart';

class LocationPermissionScreen extends ConsumerWidget {
  const LocationPermissionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enable Location'),
        automaticallyImplyLeading: false,
      ),
      body: permissionState.isLoading
          ? const LoadingWidget()
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Enable Location',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Allow location access to provide you with personalized local information, accurate navigation, and relevant content based on your location.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () => _requestPermissionAndNavigate(context, ref),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Allow Location'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _skipAndNavigate(context, ref),
                    child: const Text('Skip for Now'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _requestPermissionAndNavigate(BuildContext context, WidgetRef ref) async {
    await ref.read(permissionControllerProvider.notifier)
        .requestPermission(PermissionType.location);
    
    if (context.mounted) {
      _navigateToHome(context);
    }
  }

  Future<void> _skipAndNavigate(BuildContext context, WidgetRef ref) async {
    await ref.read(permissionControllerProvider.notifier)
        .skipPermission(PermissionType.location);
    
    if (context.mounted) {
      _navigateToHome(context);
    }
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
} 