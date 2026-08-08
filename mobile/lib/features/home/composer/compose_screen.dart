import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/home/providers/feed_provider.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  final WaveModel? editWave;
  final WaveModel? spreadFromWave;

  const ComposeScreen({
    super.key,
    this.editWave,
    this.spreadFromWave,
  });

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _shouldAllowPop = false;

  // Poll creation fields
  bool _isCreatingPoll = false;
  final _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  // Location fields
  bool _isCreatingLocation = false;
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();

  // Media upload fields
  String? _mediaUrl;
  String? _mediaType; // 'image' or 'video'
  bool _uploadingMedia = false;
  String? _uploadError;

  // Autocomplete mentions fields
  List<dynamic> _suggestions = [];
  bool _showSuggestions = false;
  int _mentionTriggerIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.editWave != null) {
      _textController.text = widget.editWave!.content ?? '';
      _mediaUrl = widget.editWave!.mediaUrl;
      _mediaType = widget.editWave!.mediaType;
    }
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _pollQuestionController.dispose();
    for (var c in _pollOptionControllers) {
      c.dispose();
    }
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _onTextChanged() async {
    final val = _textController.text;
    final selectionStart = _textController.selection.start;
    if (selectionStart <= 0) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
      return;
    }

    final textBeforeCursor = val.substring(0, selectionStart);
    final lastAtIdx = textBeforeCursor.lastIndexOf('@');
    if (lastAtIdx != -1) {
      final charBeforeAt = lastAtIdx > 0 ? textBeforeCursor[lastAtIdx - 1] : ' ';
      if (RegExp(r'\s').hasMatch(charBeforeAt)) {
        final queryTerm = textBeforeCursor.substring(lastAtIdx + 1);
        if (!RegExp(r'\s').hasMatch(queryTerm)) {
          _mentionTriggerIndex = lastAtIdx;
          setState(() {
            _showSuggestions = true;
          });
          _fetchSuggestions(queryTerm);
          return;
        }
      }
    }

    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(
        '/explore',
        queryParameters: {
          'q': query.isEmpty ? 'a' : query,
          'kind': 'people',
          'limit': 5,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _suggestions = data['people'] ?? [];
        });
      }
    } catch (_) {
      // Fail silently for autocomplete suggestions
    }
  }

  void _selectSuggestion(Map<String, dynamic> selectedUser) {
    final val = _textController.text;
    final cursor = _textController.selection.start;
    final textBeforeAt = val.substring(0, _mentionTriggerIndex);
    final textAfterCursor = val.substring(cursor);

    final username = selectedUser['username'] as String;
    final newContent = '$textBeforeAt@$username $textAfterCursor';
    _textController.text = newContent;
    _textController.selection = TextSelection.collapsed(offset: textBeforeAt.length + username.length + 2);

    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _focusNode.requestFocus();
  }

  Future<void> _pickAndUploadMedia() async {
    setState(() {
      _uploadError = null;
      _uploadingMedia = true;
    });

    try {
      final picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Photo Library'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        setState(() {
          _uploadingMedia = false;
        });
        return;
      }

      final file = await picker.pickImage(source: source);
      if (file == null) {
        setState(() {
          _uploadingMedia = false;
        });
        return;
      }

      final ext = file.path.split('.').last.toLowerCase();
      if (ext == 'mp4' || ext == 'webm') {
        _mediaType = 'video';
      } else {
        _mediaType = 'image';
      }

      final apiClient = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });

      final response = await apiClient.dio.post(
        '/media/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _mediaUrl = data['url'];
        });
      } else {
        setState(() {
          _uploadError = 'Upload failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = e.toString();
      });
    } finally {
      setState(() {
        _uploadingMedia = false;
      });
    }
  }

  void _removeMedia() {
    setState(() {
      _mediaUrl = null;
      _mediaType = null;
    });
  }

  Future<void> _handleBack() async {
    final hasDraft = _textController.text.isNotEmpty ||
        _pollQuestionController.text.isNotEmpty ||
        _mediaUrl != null;

    if (hasDraft && widget.editWave == null) {
      final confirm = await TarangConfirmDialog.show(
        context: context,
        title: 'Discard Wave',
        message: 'Are you sure you want to discard your draft?',
        confirmText: 'Discard',
      );
      if (confirm == true && mounted) {
        setState(() {
          _shouldAllowPop = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pop();
          }
        });
      }
    } else {
      setState(() {
        _shouldAllowPop = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pop();
        }
      });
    }
  }

  void _addPollOption() {
    if (_pollOptionControllers.length < 6) {
      setState(() {
        _pollOptionControllers.add(TextEditingController());
      });
    }
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length > 2) {
      setState(() {
        _pollOptionControllers[index].dispose();
        _pollOptionControllers.removeAt(index);
      });
    }
  }

  Future<void> _handlePost() async {
    final text = _textController.text.trim();
    if (text.isEmpty && widget.spreadFromWave == null && _mediaUrl == null) {
      TarangSnackbar.show(context, 'Wave cannot be empty', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(waveRepositoryProvider);
      WaveModel result;

      // Extract poll data
      Map<String, dynamic>? pollData;
      if (_isCreatingPoll && _pollQuestionController.text.trim().isNotEmpty) {
        final options = _pollOptionControllers
            .map((c) => {'text': c.text.trim()})
            .where((opt) => (opt['text'] as String).isNotEmpty)
            .toList();

        if (options.length >= 2) {
          pollData = {
            'question': _pollQuestionController.text.trim(),
            'options': options,
            'expires_in_hours': 24,
          };
        }
      }

      if (widget.editWave != null) {
        result = await repo.updateWave(
          widget.editWave!.id,
          content: text.isEmpty ? null : text,
          mediaUrl: _mediaUrl,
          mediaType: _mediaUrl != null ? (_mediaType ?? 'image') : null,
        );
      } else {
        result = await repo.createWave(
          content: text.isEmpty ? null : text,
          spreadFromId: widget.spreadFromWave?.id,
          mediaUrl: _mediaUrl,
          mediaType: _mediaUrl != null ? (_mediaType ?? 'image') : null,
          poll: pollData,
          city: _isCreatingLocation && _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
          state: _isCreatingLocation && _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
          country: _isCreatingLocation && _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
        );
      }

      ref.read(feedProvider.notifier).addOrUpdateWave(result);
      await ref.read(feedProvider.notifier).loadFeed(refresh: true);

      if (mounted) {
        TarangSnackbar.show(
          context,
          widget.editWave != null ? 'Wave saved successfully' : 'Wave posted successfully',
          isSuccess: true,
        );
        setState(() {
          _shouldAllowPop = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        TarangSnackbar.show(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterCount = _textController.text.length;
    final isQuoteSpread = widget.spreadFromWave != null;
    final isEditing = widget.editWave != null;

    final currentUser = ref.watch(authProvider).user;
    final allowLocation = currentUser?.allowLocationTags ?? true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    return PopScope(
      canPop: _shouldAllowPop || (_textController.text.isEmpty && _pollQuestionController.text.isEmpty && _mediaUrl == null),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _handleBack,
          ),
          shape: Border(bottom: BorderSide(color: borderColor)),
          title: Text(
            isEditing
                ? 'Edit Wave'
                : isQuoteSpread
                    ? 'Quote Spread'
                    : 'Compose Wave',
            style: AppTextStyles.h5.copyWith(color: textThemeColor, fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: SizedBox(
                  height: 36,
                  child: TarangButton(
                    text: isEditing ? 'Save' : 'Release',
                    variant: TarangButtonVariant.primary,
                    size: TarangButtonSize.sm,
                    loading: _isLoading,
                    disabled: _isLoading || (_textController.text.trim().isEmpty && widget.spreadFromWave == null && _mediaUrl == null),
                    onPressed: _handlePost,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            maxLines: 8,
                            minLines: 3,
                            autofocus: true,
                            maxLength: 280,
                            style: AppTextStyles.body.copyWith(color: textThemeColor),
                            onChanged: (val) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: "What's creating waves today?",
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              counterText: '', // Hide default counter
                            ),
                          ),

                          // Media Preview Box
                          if (_uploadingMedia || _mediaUrl != null || _uploadError != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_uploadingMedia)
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Uploading attachment to secure cloud...',
                                          style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  if (_uploadError != null)
                                    Text(
                                      _uploadError!,
                                      style: AppTextStyles.metadata.copyWith(color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight, fontWeight: FontWeight.bold),
                                    ),
                                  if (!_uploadingMedia && _mediaUrl != null)
                                    Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: borderColor),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Image.network(
                                            _mediaUrl!,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: TarangIconButton(
                                            icon: const Icon(Icons.close_rounded, size: 16),
                                            size: 28,
                                            backgroundColor: Colors.black.withValues(alpha: 0.6),
                                            foregroundColor: Colors.white,
                                            hasBorder: false,
                                            onPressed: _removeMedia,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],

                          // Embedded Original Wave for Quote Spreads
                          if (isQuoteSpread) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isDark ? AppTheme.darkSurface : AppTheme.lightSurface).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      TarangAvatar(
                                        username: widget.spreadFromWave!.creator.username,
                                        avatarUrl: widget.spreadFromWave!.creator.avatarUrl,
                                        size: TarangAvatarSize.sm,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.spreadFromWave!.creator.fullName ?? widget.spreadFromWave!.creator.username,
                                        style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '@${widget.spreadFromWave!.creator.username}',
                                        style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.spreadFromWave!.content ?? '',
                                    style: AppTextStyles.caption.copyWith(color: textThemeColor),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Poll builder UI
                          if (_isCreatingPoll) ...[
                            const SizedBox(height: 16),
                            TarangCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Text('📊', style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Text('Create Poll', style: AppTextStyles.captionBold.copyWith(color: textThemeColor)),
                                      const Spacer(),
                                      TarangIconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        size: 28,
                                        hasBorder: false,
                                        onPressed: () => setState(() => _isCreatingPoll = false),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _pollQuestionController,
                                    decoration: const InputDecoration(
                                      hintText: 'Ask a question...',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._pollOptionControllers.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final controller = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: controller,
                                              decoration: InputDecoration(
                                                hintText: 'Option ${idx + 1}',
                                              ),
                                            ),
                                          ),
                                          if (_pollOptionControllers.length > 2)
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                              onPressed: () => _removePollOption(idx),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (_pollOptionControllers.length < 6)
                                    TextButton.icon(
                                      onPressed: _addPollOption,
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Add Option'),
                                    ),
                                ],
                              ),
                            ),
                          ],

                          // Location builder UI
                          if (_isCreatingLocation) ...[
                            const SizedBox(height: 16),
                            TarangCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Text('📍', style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Text('Add Location Tag', style: AppTextStyles.captionBold.copyWith(color: textThemeColor)),
                                      const Spacer(),
                                      TarangIconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        size: 28,
                                        hasBorder: false,
                                        onPressed: () => setState(() => _isCreatingLocation = false),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _cityController,
                                          decoration: const InputDecoration(hintText: 'City'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _stateController,
                                          decoration: const InputDecoration(hintText: 'State'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _countryController,
                                    decoration: const InputDecoration(hintText: 'Country'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom Toolbar Bar (Icons)
                  if (!isEditing && !isQuoteSpread)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.poll_outlined, color: AppTheme.primaryTeal),
                            onPressed: () {
                              setState(() {
                                _isCreatingPoll = !_isCreatingPoll;
                              });
                            },
                          ),
                          if (allowLocation)
                            IconButton(
                              icon: Icon(Icons.location_on_outlined, color: _isCreatingLocation ? AppTheme.primaryTeal : AppTheme.textMuted),
                              onPressed: () {
                                setState(() {
                                  _isCreatingLocation = !_isCreatingLocation;
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.image_outlined, color: AppTheme.primaryTeal),
                            onPressed: _pickAndUploadMedia,
                          ),
                          const Spacer(),
                          Text(
                            '$characterCount / 280',
                            style: AppTextStyles.metadata.copyWith(
                              color: characterCount > 250 ? Colors.red : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Mentions Autocomplete Box Overlay
              if (_showSuggestions && _suggestions.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 60,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                        itemBuilder: (context, index) {
                          final item = _suggestions[index] as Map<String, dynamic>;
                          return ListTile(
                            leading: TarangAvatar(
                              username: item['username'] ?? '?',
                              avatarUrl: item['avatar_url'],
                              size: TarangAvatarSize.sm,
                            ),
                            title: Text(
                              item['full_name'] ?? item['username'] ?? '',
                              style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
                            ),
                            subtitle: Text(
                              '@${item['username']}',
                              style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                            ),
                            onTap: () => _selectSuggestion(item),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
