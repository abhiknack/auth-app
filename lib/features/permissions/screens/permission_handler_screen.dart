import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permission_providers.dart';
import '../models/permission_status_model.dart';
import 'notification_permission_screen.dart';
import 'location_permission_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../../shared/widgets/loading_widget.dart';

class PermissionHandlerScreen extends ConsumerStatefulWidget {
  const PermissionHandlerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PermissionHandlerScreen> createState() => _PermissionHandlerScreenState();
}

class _PermissionHandlerScreenState extends ConsumerState<PermissionHandlerScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final shouldShowNotification = await ref
        .read(permissionControllerProvider.notifier)
        .shouldShowPermissionExplanation(PermissionType.notification);

    if (shouldShowNotification) {
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToNotificationScreen();
        return;
      }
    }

    final shouldShowLocation = await ref
        .read(permissionControllerProvider.notifier)
        .shouldShowPermissionExplanation(PermissionType.location);

    if (shouldShowLocation) {
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToLocationScreen();
        return;
      }
    }

    // If no permission screens needed, go to home
    if (mounted) {
      setState(() => _isLoading = false);
      _navigateToHome();
    }
  }

  void _navigateToNotificationScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const NotificationPermissionScreen()),
    );
  }

  void _navigateToLocationScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingWidget()
          : const Center(child: Text('Redirecting...')),
    );
  }
} 