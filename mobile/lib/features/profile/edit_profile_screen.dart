import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a Photo'),
              onTap: () {
                context.pop();
                _pickImage(isAvatar, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    if (user == null) {
      return const Scaffold(body: Center(child: TarangLoading()));
    }

    return Scaffold(
      appBar: AppBar(
        shape: Border(bottom: BorderSide(color: borderColor)),
        title: Text(
          'Edit Profile',
          style: AppTextStyles.h5.copyWith(color: textThemeColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (editState.isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.check_rounded, color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal),
              onPressed: _save,
            ),
        ],
      ),
      body: SafeArea(
        child: editState.isSubmitting
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(value: editState.uploadProgress, color: AppTheme.primaryTeal),
                      const SizedBox(height: 16),
                      Text(
                        'Uploading media & saving profile details... ${(editState.uploadProgress * 100).toInt()}%',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
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
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            border: Border(bottom: BorderSide(color: borderColor)),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_selectedBannerPath != null)
                                Image.file(File(_selectedBannerPath!), fit: BoxFit.cover)
                              else if (user.coverUrl != null && user.coverUrl!.isNotEmpty)
                                Image.network(user.coverUrl!, fit: BoxFit.cover)
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        isDark ? AppTheme.primaryTeal.withValues(alpha: 0.1) : AppTheme.primaryTeal.withValues(alpha: 0.2),
                                        isDark ? AppTheme.primaryTealLight.withValues(alpha: 0.2) : AppTheme.primaryTeal.withValues(alpha: 0.3),
                                      ],
                                    ),
                                  ),
                                ),
                              Container(
                                color: Colors.black.withValues(alpha: 0.3),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
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
                                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                  child: CircleAvatar(
                                    radius: 42,
                                    backgroundImage: _selectedAvatarPath != null
                                        ? FileImage(File(_selectedAvatarPath!))
                                        : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                            ? NetworkImage(user.avatarUrl!)
                                            : null) as ImageProvider?,
                                    child: _selectedAvatarPath == null && (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                        ? Text(
                                            user.username[0].toUpperCase(),
                                            style: AppTextStyles.h4.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                    onPressed: () => _showImageSourceDialog(true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Text input fields
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            if (editState.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  editState.errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            TarangTextField(
                              controller: _fullNameController,
                              label: 'Display Name',
                              hint: 'Enter display name',
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Display name cannot be empty';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TarangTextField(
                              controller: _usernameController,
                              label: 'Username',
                              hint: 'Enter username',
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Username cannot be empty';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TarangTextField(
                              controller: _bioController,
                              label: 'Bio',
                              hint: 'Tell us about yourself...',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 24),
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
