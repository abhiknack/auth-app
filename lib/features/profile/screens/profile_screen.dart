import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/widgets/loading_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final userData = await ref.read(currentUserProvider.future);
    if (userData != null) {
      _displayNameController.text = userData.displayName ?? '';
      _phoneController.text = userData.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final userData = await ref.read(currentUserProvider.future);
      if (userData != null) {
        final updatedUser = userData.copyWith(
          displayName: _displayNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
        
        await ref.read(authControllerProvider.notifier).updateUserProfile(updatedUser);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final userData = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: userData.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User data not available'));
          }
          
          return authState.isLoading 
            ? const LoadingWidget()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: user.photoURL != null 
                            ? NetworkImage(user.photoURL!) 
                            : null,
                          child: user.photoURL == null 
                            ? const Icon(Icons.person, size: 50) 
                            : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Email: ${user.email}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a display name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Update Profile'),
                      ),
                      
                      if (authState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            authState.error.toString(),
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(
          child: Text('Error loading user data: $error'),
        ),
      ),
    );
  }
} 