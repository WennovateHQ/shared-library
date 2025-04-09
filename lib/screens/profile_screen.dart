import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../utils/logging_service.dart';
import '../widgets/loading_overlay.dart';

class ProfileScreen extends StatefulWidget {
  final String appType; // 'farmer', 'consumer', or 'driver'
  final Color? primaryColor;
  final List<String>? additionalFields;

  const ProfileScreen({
    super.key,
    required this.appType,
    this.primaryColor,
    this.additionalFields,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _additionalFieldControllers = <String, TextEditingController>{};

  bool _isLoading = false;
  bool _isEditing = false;
  File? _newProfileImage;
  String? _currentProfileImageUrl;
  User? _user;
  final ProfileService _profileService = ProfileService();
  final LoggingService _logger = LoggingService('ProfileScreen');

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers for additional fields if any
    if (widget.additionalFields != null) {
      for (var field in widget.additionalFields!) {
        _additionalFieldControllers[field] = TextEditingController();
      }
    }
    
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    
    // Dispose controllers for additional fields
    for (var controller in _additionalFieldControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _logger.debug('Loading user profile');
      final userData = await _profileService.getUserProfile();
      
      setState(() {
        // Create User model from the response
        _user = User.fromJson(userData);
        
        // Set the field values
        _nameController.text = _user!.fullName;
        _emailController.text = _user!.email;
        _phoneController.text = _user!.phone ?? '';
        _currentProfileImageUrl = _user!.profileImageUrl;
        
        // Set values for additional fields
        if (widget.additionalFields != null && _user!.settings != null) {
          for (var field in widget.additionalFields!) {
            if (_user!.settings!.containsKey(field)) {
              _additionalFieldControllers[field]?.text = _user!.settings![field]?.toString() ?? '';
            }
          }
        }
      });
    } catch (e) {
      _logger.error('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    
    _logger.debug('Picking profile image');
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _newProfileImage = File(image.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _logger.debug('Updating profile');
      
      // Split the name into first and last name
      final nameParts = _nameController.text.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
      
      // Prepare updated user data
      final Map<String, dynamic> updatedData = {
        'firstName': firstName,
        'lastName': lastName,
        'phone': _phoneController.text,
      };
      
      // Add any additional fields
      if (_user?.settings != null) {
        // Create settings map with proper typing
        updatedData['settings'] = <String, dynamic>{};
        
        // Get the settings map with correct typing
        final Map<String, dynamic> settings = updatedData['settings'] as Map<String, dynamic>;
        
        // Add all additional fields to settings
        for (var entry in _additionalFieldControllers.entries) {
          settings[entry.key] = entry.value.text;
        }
      }

      // Upload new profile image if selected
      if (_newProfileImage != null) {
        _logger.debug('Uploading new profile image');
        final imageUrl = await _profileService.uploadProfileImage(_newProfileImage!);
        updatedData['profileImageUrl'] = imageUrl.toString(); // Make sure to assign as String explicitly
      }

      // Update the profile
      final updatedProfile = await _profileService.updateProfile(updatedData);
      
      setState(() {
        _user = User.fromJson(updatedProfile);
        _isEditing = false;
        _newProfileImage = null;
        _currentProfileImageUrl = _user!.profileImageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.error('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        _logger.debug('Logging out');
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.logout();
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        _logger.error('Error during logout: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to log out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _newProfileImage = null;
                  
                  // Reset fields to original values
                  if (_user != null) {
                    _nameController.text = _user!.fullName;
                    _phoneController.text = _user!.phone ?? '';
                    
                    // Reset additional fields
                    if (widget.additionalFields != null && _user!.settings != null) {
                      for (var field in widget.additionalFields!) {
                        if (_user!.settings!.containsKey(field)) {
                          _additionalFieldControllers[field]?.text = 
                              _user!.settings![field]?.toString() ?? '';
                        }
                      }
                    }
                  }
                });
              },
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile image
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!) as ImageProvider
                            : _currentProfileImageUrl != null
                                ? NetworkImage(_currentProfileImageUrl!) as ImageProvider
                                : null,
                        child: _newProfileImage == null && _currentProfileImageUrl == null
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey.shade400,
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // User info
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabled: _isEditing,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabled: false, // Email cannot be changed
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabled: _isEditing,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                
                // Additional fields specific to the app type
                if (widget.additionalFields != null)
                  ...widget.additionalFields!.map((field) {
                    return Column(
                      children: [
                        TextFormField(
                          controller: _additionalFieldControllers[field],
                          decoration: InputDecoration(
                            labelText: field.replaceAll('_', ' ').capitalize(),
                            prefixIcon: const Icon(Icons.input),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabled: _isEditing,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your ${field.replaceAll('_', ' ')}';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                
                const SizedBox(height: 24),
                
                // Update Profile / Change Password buttons
                if (_isEditing)
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/change_password');
                    },
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Change Password'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Logout button
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
