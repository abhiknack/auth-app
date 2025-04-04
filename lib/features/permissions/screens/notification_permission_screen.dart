import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permission_providers.dart';
import '../models/permission_status_model.dart';
import 'location_permission_screen.dart';
import '../../../shared/widgets/loading_widget.dart';

class NotificationPermissionScreen extends ConsumerWidget {
  const NotificationPermissionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enable Notifications'),
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
                    Icons.notifications_active,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Stay Updated',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enable notifications to receive important updates about your account, location alerts, and other important information.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () => _requestPermissionAndNavigate(context, ref),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Allow Notifications'),
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
        .requestPermission(PermissionType.notification);
    
    if (context.mounted) {
      _navigateNext(context, ref);
    }
  }

  Future<void> _skipAndNavigate(BuildContext context, WidgetRef ref) async {
    await ref.read(permissionControllerProvider.notifier)
        .skipPermission(PermissionType.notification);
    
    if (context.mounted) {
      _navigateNext(context, ref);
    }
  }

  Future<void> _navigateNext(BuildContext context, WidgetRef ref) async {
    final shouldShowLocationExplanation = await ref
        .read(permissionControllerProvider.notifier)
        .shouldShowPermissionExplanation(PermissionType.location);
    
    if (context.mounted) {
      if (shouldShowLocationExplanation) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
        );
      } else {
        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }
} 