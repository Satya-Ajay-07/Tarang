import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/providers/core_providers.dart';
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
  bool _isLoading = false;
  bool _shouldAllowPop = false;

  // Poll creation fields
  bool _isCreatingPoll = false;
  final _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editWave != null) {
      _textController.text = widget.editWave!.content ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _pollQuestionController.dispose();
    for (var c in _pollOptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleBack() async {
    final hasDraft = _textController.text.isNotEmpty ||
        _pollQuestionController.text.isNotEmpty;
    if (hasDraft) {
      final confirm = await AppDialogs.showConfirmation(
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
    if (text.isEmpty && widget.spreadFromWave == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wave cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(waveRepositoryProvider);
      WaveModel result;

      // Extract poll data if active
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
        // Edit wave API
        result = await repo.updateWave(widget.editWave!.id, content: text);
      } else {
        // Create or Quote Spread wave API
        result = await repo.createWave(
          content: text.isEmpty ? null : text,
          spreadFromId: widget.spreadFromWave?.id,
          poll: pollData,
        );
      }

      // Add to UI feed state
      ref.read(feedProvider.notifier).addOrUpdateWave(result);

      // Refresh feed to get latest updates
      await ref.read(feedProvider.notifier).loadFeed(refresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(widget.editWave != null ? 'Wave saved' : 'Wave posted')),
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
        AppDialogs.showError(
          context: context,
          title: 'Failed to Post',
          message: e.toString(),
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

  @override
  Widget build(BuildContext context) {
    final characterCount = _textController.text.length;
    final isQuoteSpread = widget.spreadFromWave != null;
    final isEditing = widget.editWave != null;

    return PopScope(
      canPop: _shouldAllowPop ||
          (_textController.text.isEmpty &&
              _pollQuestionController.text.isEmpty),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleBack,
          ),
          title: Text(isEditing
              ? 'Edit Wave'
              : isQuoteSpread
                  ? 'Quote Spread'
                  : 'Compose Wave'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: (_isLoading ||
                        (_textController.text.trim().isEmpty &&
                            widget.spreadFromWave == null))
                    ? null
                    : _handlePost,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primaryTeal),
                      )
                    : Text(
                        isEditing ? 'Save' : 'Post',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (_textController.text.trim().isEmpty &&
                                  widget.spreadFromWave == null)
                              ? Colors.grey
                              : AppTheme.primaryTeal,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: 8,
                        minLines: 3,
                        autofocus: true,
                        maxLength: 280,
                        onChanged: (val) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: "What's creating waves today?",
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterText: '', // Hide default counter
                        ),
                      ),

                      // Character limit counter row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$characterCount / 280',
                            style: TextStyle(
                              color: characterCount > 250
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceM),

                      // Embedded original Wave for Quote Spreads
                      if (isQuoteSpread) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceM),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomAvatar(
                                    url: widget
                                        .spreadFromWave!.creator.avatarUrl,
                                    radius: 12,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.spreadFromWave!.creator.fullName ??
                                        widget.spreadFromWave!.creator.username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '@${widget.spreadFromWave!.creator.username}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(widget.spreadFromWave!.content ?? ''),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                      ],

                      // Poll builder UI
                      if (_isCreatingPoll) ...[
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spaceM),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.poll_outlined,
                                        color: AppTheme.primaryTeal),
                                    const SizedBox(width: 8),
                                    const Text('Create Poll',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          size: 20),
                                      onPressed: () => setState(
                                          () => _isCreatingPoll = false),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spaceS),
                                TextField(
                                  controller: _pollQuestionController,
                                  decoration: const InputDecoration(
                                    hintText: 'Ask a question...',
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spaceM),
                                ..._pollOptionControllers
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final idx = entry.key;
                                  final controller = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppTheme.spaceS),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: controller,
                                            decoration: InputDecoration(
                                              hintText: 'Option ${idx + 1}',
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        if (_pollOptionControllers.length > 2)
                                          IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _removePollOption(idx),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                if (_pollOptionControllers.length < 6)
                                  TextButton.icon(
                                    onPressed: _addPollOption,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Option'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Actions Bar
              if (!isEditing && !isQuoteSpread)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border:
                        Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.poll_outlined,
                            color: AppTheme.primaryTeal),
                        onPressed: () {
                          setState(() {
                            _isCreatingPoll = !_isCreatingPoll;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.image_outlined,
                            color: Colors.grey),
                        onPressed: () {}, // Future ready placeholder
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
