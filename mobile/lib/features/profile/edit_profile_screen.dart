import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/profile/providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedAvatarPath;
  String? _selectedBannerPath;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _fullNameController.text = user.fullName ?? '';
      _usernameController.text = user.username;
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isAvatar, ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1000,
      );
      if (pickedFile != null) {
        setState(() {
          if (isAvatar) {
            _selectedAvatarPath = pickedFile.path;
          } else {
            _selectedBannerPath = pickedFile.path;
          }
        });
      }
    } catch (_) {}
  }

  void _showImageSourceDialog(bool isAvatar) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusM)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                context.pop();
                _pickImage(isAvatar, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                context.pop();
                _pickImage(isAvatar, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    await ref.read(editProfileProvider.notifier).updateProfile(
          fullName: _fullNameController.text.trim(),
          username: _usernameController.text.trim(),
          bio: _bioController.text.trim(),
          avatarPath: _selectedAvatarPath,
          bannerPath: _selectedBannerPath,
        );

    final editState = ref.read(editProfileProvider);
    if (editState.isSuccess) {
      // Reload current logged in session user inside AuthNotifier
      await ref.read(authProvider.notifier).checkSession();
      if (mounted) {
        context.pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(editProfileProvider);
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (editState.isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: AppTheme.primaryTeal),
              onPressed: _save,
            ),
        ],
      ),
      body: SafeArea(
        child: editState.isSubmitting
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          value: editState.uploadProgress),
                      const SizedBox(height: AppTheme.spaceM),
                      Text(
                        'Uploading media & saving profile details... ${(editState.uploadProgress * 100).toInt()}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner picker area
                      GestureDetector(
                        onTap: () => _showImageSourceDialog(false),
                        child: Container(
                          height: 140,
                          color: Colors.grey.shade300,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_selectedBannerPath != null)
                                Image.file(File(_selectedBannerPath!),
                                    fit: BoxFit.cover)
                              else if (user.coverUrl != null &&
                                  user.coverUrl!.isNotEmpty)
                                Image.network(user.coverUrl!, fit: BoxFit.cover)
                              else
                                Container(
                                    color: AppTheme.primaryTeal
                                        .withValues(alpha: 0.15)),
                              Container(
                                color: Colors.black.withValues(alpha: 0.3),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 36),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Avatar picker area (overlaps banner slightly)
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showImageSourceDialog(true),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: CircleAvatar(
                                    radius: 42,
                                    backgroundImage: _selectedAvatarPath != null
                                        ? FileImage(File(_selectedAvatarPath!))
                                        : (user.avatarUrl != null &&
                                                user.avatarUrl!.isNotEmpty
                                            ? NetworkImage(user.avatarUrl!)
                                            : null) as ImageProvider?,
                                    child: _selectedAvatarPath == null &&
                                            (user.avatarUrl == null ||
                                                user.avatarUrl!.isEmpty)
                                        ? const Icon(Icons.person, size: 40)
                                        : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppTheme.primaryTeal,
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt,
                                        size: 12, color: Colors.white),
                                    onPressed: () =>
                                        _showImageSourceDialog(true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Text input fields
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceM),
                        child: Column(
                          children: [
                            if (editState.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppTheme.spaceM),
                                child: Text(
                                  editState.errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Display Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Display name cannot be empty';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Username cannot be empty';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            TextFormField(
                              controller: _bioController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
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
