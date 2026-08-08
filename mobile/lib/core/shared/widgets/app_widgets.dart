import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';

// ════════════════════════════════════════════════════════════════════════════
// 1. TarangLogo
//    Reproduces the SVG wave mark from the Web Application's Logo.tsx:
//    Two curved paths forming a subtle 'T' shape.
//    Path 1: M15 30 C 45 10, 55 50, 85 30  (horizontal wave)
//    Path 2: M50 30 C 50 55, 30 75, 50 85  (vertical stem)
// ════════════════════════════════════════════════════════════════════════════

class TarangLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const TarangLogo({super.key, this.size = 40.0, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal;

    final svgMark = CustomPaint(
      size: Size(size, size),
      painter: _TarangLogoPainter(color: color),
    );

    if (!showText) return svgMark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        svgMark,
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) => (isDark
                  ? AppTheme.waveGradientDark
                  : AppTheme.waveGradient)
              .createShader(bounds),
          child: Text(
            'Tarang',
            style: GoogleFonts.outfit(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white, // masked by shader
            ),
          ),
        ),
      ],
    );
  }
}

class _TarangLogoPainter extends CustomPainter {
  final Color color;
  const _TarangLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    // Scale SVG viewBox (0,0,100,100) to actual widget size
    final scaleX = size.width / 100;
    final scaleY = size.height / 100;

    // Path 1: Horizontal wave — M15 30 C 45 10, 55 50, 85 30
    final wave = Path()
      ..moveTo(15 * scaleX, 30 * scaleY)
      ..cubicTo(
        45 * scaleX, 10 * scaleY,
        55 * scaleX, 50 * scaleY,
        85 * scaleX, 30 * scaleY,
      );

    // Path 2: Vertical stem — M50 30 C 50 55, 30 75, 50 85
    final stem = Path()
      ..moveTo(50 * scaleX, 30 * scaleY)
      ..cubicTo(
        50 * scaleX, 55 * scaleY,
        30 * scaleX, 75 * scaleY,
        50 * scaleX, 85 * scaleY,
      );

    canvas.drawPath(wave, paint);
    canvas.drawPath(stem, paint);
  }

  @override
  bool shouldRepaint(_TarangLogoPainter old) => old.color != color;
}

// ════════════════════════════════════════════════════════════════════════════
// 2. TarangAvatar
//    Matches Avatar.tsx: gradient initials fallback (from-ocean to-aqua),
//    optional online presence dot, four sizes.
// ════════════════════════════════════════════════════════════════════════════

enum TarangAvatarSize { sm, md, lg, xl }

class TarangAvatar extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final bool? isOnline;
  final TarangAvatarSize size;
  final VoidCallback? onTap;

  const TarangAvatar({
    super.key,
    required this.username,
    this.avatarUrl,
    this.isOnline,
    this.size = TarangAvatarSize.md,
    this.onTap,
  });

  static const _pixelMap = {
    TarangAvatarSize.sm: 32.0,
    TarangAvatarSize.md: 40.0,
    TarangAvatarSize.lg: 48.0,
    TarangAvatarSize.xl: 64.0,
  };

  static const _dotMap = {
    TarangAvatarSize.sm: 8.0,
    TarangAvatarSize.md: 10.0,
    TarangAvatarSize.lg: 12.0,
    TarangAvatarSize.xl: 14.0,
  };

  static const _fontMap = {
    TarangAvatarSize.sm: 12.0,
    TarangAvatarSize.md: 14.0,
    TarangAvatarSize.lg: 16.0,
    TarangAvatarSize.xl: 22.0,
  };

  @override
  Widget build(BuildContext context) {
    final diameter = _pixelMap[size]!;
    final dotSize = _dotMap[size]!;
    final fontSize = _fontMap[size]!;
    final initials = username.isNotEmpty ? username[0].toUpperCase() : '?';

    Widget avatar = Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.avatarGradient,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              memCacheWidth: size == TarangAvatarSize.lg ? 200 : 100,
              memCacheHeight: size == TarangAvatarSize.lg ? 200 : 100,
              placeholder: (context, url) => Container(color: Colors.transparent),
              errorWidget: (_, __, ___) => _initials(initials, fontSize),
            )
          : _initials(initials, fontSize),
    );

    if (isOnline != null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline!
                    ? const Color(0xFF4ADE80) // green-400
                    : (isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1)),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _initials(String text, double fontSize) => Center(
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// 3. TarangButton
//    Matches Button.tsx: 4 variants × 3 sizes, gradient primary,
//    loading spinner, active scale animation.
// ════════════════════════════════════════════════════════════════════════════

enum TarangButtonVariant { primary, secondary, ghost, danger }

enum TarangButtonSize { sm, md, lg }

class TarangButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final TarangButtonVariant variant;
  final TarangButtonSize size;
  final bool loading;
  final bool disabled;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;

  const TarangButton({
    super.key,
    this.text,
    this.child,
    this.variant = TarangButtonVariant.primary,
    this.size = TarangButtonSize.md,
    this.loading = false,
    this.disabled = false,
    this.onPressed,
    this.padding,
  }) : assert(text != null || child != null, 'Provide text or child');

  @override
  State<TarangButton> createState() => _TarangButtonState();
}

class _TarangButtonState extends State<TarangButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  EdgeInsetsGeometry get _padding {
    if (widget.padding != null) return widget.padding!;
    return switch (widget.size) {
      TarangButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      TarangButtonSize.md => const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      TarangButtonSize.lg => const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    };
  }

  TextStyle get _textStyle {
    return switch (widget.size) {
      TarangButtonSize.sm => AppTextStyles.buttonSm,
      TarangButtonSize.md => AppTextStyles.button,
      TarangButtonSize.lg => AppTextStyles.buttonLg,
    };
  }

  bool get _isDisabled => widget.disabled || widget.loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _spinnerColor(isDark),
              ),
            ),
          ),
        widget.child ??
            Text(
              widget.text!,
              style: _textStyle.copyWith(color: _foregroundColor(isDark)),
            ),
      ],
    );

    Widget button = GestureDetector(
      onTapDown: _isDisabled ? null : (_) => _scaleCtrl.reverse(),
      onTapUp: _isDisabled ? null : (_) => _scaleCtrl.forward(),
      onTapCancel: _isDisabled ? null : () => _scaleCtrl.forward(),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedOpacity(
          opacity: _isDisabled ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: _buildSurface(isDark, content),
        ),
      ),
    );

    return button;
  }

  Widget _buildSurface(bool isDark, Widget content) {
    final p = _padding;

    switch (widget.variant) {
      case TarangButtonVariant.primary:
        return Container(
          padding: p,
          decoration: BoxDecoration(
            gradient: isDark ? AppTheme.waveGradientDark : AppTheme.waveGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            boxShadow: _isDisabled ? [] : AppTheme.shadowMd,
          ),
          child: content,
        );

      case TarangButtonVariant.secondary:
        final borderColor =
            isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;
        return Container(
          padding: p,
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.darkSurface : AppTheme.lightSurface)
                .withValues(alpha: 0.4),
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
          child: content,
        );

      case TarangButtonVariant.ghost:
        return Container(
          padding: p,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
          child: content,
        );

      case TarangButtonVariant.danger:
        return Container(
          padding: p,
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.dangerDark : AppTheme.dangerLight)
                .withValues(alpha: 0.1),
            border: Border.all(
              color: (isDark ? AppTheme.dangerDark : AppTheme.dangerLight)
                  .withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
          child: content,
        );
    }
  }

  Color _foregroundColor(bool isDark) {
    return switch (widget.variant) {
      TarangButtonVariant.primary => Colors.white,
      TarangButtonVariant.secondary =>
        isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
      TarangButtonVariant.ghost =>
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
      TarangButtonVariant.danger =>
        isDark ? AppTheme.dangerDark : AppTheme.dangerLight,
    };
  }

  Color _spinnerColor(bool isDark) {
    return switch (widget.variant) {
      TarangButtonVariant.primary => Colors.white,
      _ => isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
    };
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 4. TarangIconButton
//    Circle icon button with hover/press feedback
// ════════════════════════════════════════════════════════════════════════════

class TarangIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final String? tooltip;
  final bool hasBorder;

  const TarangIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 40.0,
    this.tooltip,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;
    final defaultBg = isDark
        ? AppTheme.darkSurface.withValues(alpha: 0.0)
        : AppTheme.lightSurface.withValues(alpha: 0.0);

    Widget btn = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? defaultBg,
        border: hasBorder ? Border.all(color: borderColor) : null,
      ),
      child: IconTheme(
        data: IconThemeData(
          color: foregroundColor ??
              (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
          size: size * 0.45,
        ),
        child: Center(child: icon),
      ),
    );

    btn = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: btn,
      ),
    );

    if (tooltip != null) {
      btn = Tooltip(message: tooltip!, child: btn);
    }

    return btn;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 5. TarangCard
//    Matches Card.tsx: rounded-card (24px), card-border, card-bg,
//    optional hover elevation.
// ════════════════════════════════════════════════════════════════════════════

class TarangCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool hoverable;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  final Color? backgroundColor;

  const TarangCard({
    super.key,
    required this.child,
    this.padding,
    this.hoverable = true,
    this.onTap,
    this.shadow,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppTheme.darkCard : AppTheme.lightCard);
    final border = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;
    final shadows = shadow ?? AppTheme.shadowSm;

    Widget card;

    if (onTap != null) {
      card = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: shadows,
        ),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Container(
              padding: padding ?? const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: border),
              ),
              child: child,
            ),
          ),
        ),
      );
    } else {
      card = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: shadows,
        ),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppTheme.spaceM),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: border),
            ),
            child: child,
          ),
        ),
      );
    }

    return card;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 6. TarangTextField
//    Matches Input.tsx: small-caps label, focus ring primary/30,
//    leftIcon / rightIcon slots, error state with danger border.
// ════════════════════════════════════════════════════════════════════════════

class TarangTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? error;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final TextCapitalization textCapitalization;

  const TarangTextField({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.leftIcon,
    this.rightIcon,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: labelColor),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
          enabled: enabled,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          focusNode: focusNode,
          autofocus: autofocus,
          readOnly: readOnly,
          textCapitalization: textCapitalization,
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: error,
            prefixIcon: leftIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: IconTheme(
                      data: IconThemeData(color: AppTheme.textMuted, size: 18),
                      child: leftIcon!,
                    ),
                  )
                : null,
            prefixIconConstraints:
                leftIcon != null ? const BoxConstraints(minWidth: 44) : null,
            suffixIcon: rightIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: IconTheme(
                      data: IconThemeData(color: AppTheme.textMuted, size: 18),
                      child: rightIcon!,
                    ),
                  )
                : null,
            suffixIconConstraints:
                rightIcon != null ? const BoxConstraints(minWidth: 44) : null,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: AppTextStyles.metadata.copyWith(
              color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 7. TarangSkeleton
//    Matches Skeleton.tsx: animate-pulse, card-border/40 base color,
//    three shape variants.
// ════════════════════════════════════════════════════════════════════════════

enum TarangSkeletonVariant { rect, circle, text }

class TarangSkeleton extends StatelessWidget {
  final TarangSkeletonVariant variant;
  final double? width;
  final double? height;
  final double? borderRadius;

  const TarangSkeleton({
    super.key,
    this.variant = TarangSkeletonVariant.rect,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppTheme.darkCardBorder.withValues(alpha: 0.4)
        : AppTheme.lightCardBorder.withValues(alpha: 0.8);
    final highlightColor = isDark
        ? AppTheme.darkSurface.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.9);

    double resolvedRadius;
    switch (variant) {
      case TarangSkeletonVariant.circle:
        resolvedRadius = (width ?? height ?? 40) / 2;
        break;
      case TarangSkeletonVariant.text:
        resolvedRadius = borderRadius ?? 6.0;
        break;
      case TarangSkeletonVariant.rect:
        resolvedRadius = borderRadius ?? AppTheme.radiusS;
        break;
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: variant == TarangSkeletonVariant.text
            ? (width ?? double.infinity)
            : width,
        height: variant == TarangSkeletonVariant.text ? (height ?? 14) : height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(resolvedRadius),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 8. TarangLoading
//    Premium teal circular progress with optional label.
// ════════════════════════════════════════════════════════════════════════════

class TarangLoading extends StatelessWidget {
  final double size;
  final String? label;
  final bool fullScreen;

  const TarangLoading({
    super.key,
    this.size = 40.0,
    this.label,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal;

    Widget spinner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: size * 0.08,
            strokeCap: StrokeCap.round,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: AppTheme.spaceM),
          Text(
            label!,
            style: AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: Center(child: spinner),
      );
    }

    return Center(child: spinner);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 9. TarangEmptyState
// ════════════════════════════════════════════════════════════════════════════

class TarangEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? body;
  final Widget? action;

  const TarangEmptyState({
    super.key,
    this.emoji = '🌊',
    required this.title,
    this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
                        .withValues(alpha: 0.15),
                    (isDark ? AppTheme.foam : AppTheme.foamDark)
                        .withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: AppTheme.spaceS),
              Text(
                body!,
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.spaceL),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 10. TarangErrorState
// ════════════════════════════════════════════════════════════════════════════

class TarangErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const TarangErrorState({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = isDark ? AppTheme.dangerDark : AppTheme.dangerLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: danger.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.error_outline_rounded, color: danger, size: 36),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spaceL),
              TarangButton(
                text: retryLabel,
                variant: TarangButtonVariant.secondary,
                size: TarangButtonSize.sm,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 11. TarangDialog
//    Matches Modal.tsx: backdrop-blur, rounded-dialog (32px), close button,
//    optional title/description header, body slot.
// ════════════════════════════════════════════════════════════════════════════

class TarangDialog extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget child;
  final double maxWidth;
  final bool showClose;

  const TarangDialog({
    super.key,
    this.title,
    this.description,
    required this.child,
    this.maxWidth = 480,
    this.showClose = true,
  });

  /// Helper to show the dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? description,
    required Widget child,
    double maxWidth = 480,
    bool showClose = true,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => TarangDialog(
        title: title,
        description: description,
        maxWidth: maxWidth,
        showClose: showClose,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
              border: Border.all(color: borderColor),
              boxShadow: AppTheme.shadowLg,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null || description != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 48, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title != null)
                              Text(
                                title!,
                                style: AppTextStyles.h5.copyWith(
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                              ),
                            if (description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                description!,
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Divider(height: 1, color: borderColor),
                    ],
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: child,
                    ),
                  ],
                ),
                if (showClose)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: TarangIconButton(
                      icon: const Icon(Icons.close_rounded),
                      size: 36,
                      hasBorder: false,
                      onPressed: () => Navigator.of(context).pop(),
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

/// Quick confirmation dialog
class TarangConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final TarangButtonVariant confirmVariant;

  const TarangConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmVariant = TarangButtonVariant.primary,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    TarangButtonVariant confirmVariant = TarangButtonVariant.danger,
  }) {
    return TarangDialog.show<bool>(
      context: context,
      title: title,
      description: message,
      showClose: false,
      child: TarangConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmVariant: confirmVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TarangButton(
          text: cancelText,
          variant: TarangButtonVariant.ghost,
          size: TarangButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: AppTheme.spaceS),
        TarangButton(
          text: confirmText,
          variant: confirmVariant,
          size: TarangButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 12. TarangBottomSheet
//    Drag handle, rounded top (24px), consistent padding.
// ════════════════════════════════════════════════════════════════════════════

class TarangBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showDragHandle;
  final EdgeInsetsGeometry? padding;

  const TarangBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showDragHandle = true,
    this.padding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool showDragHandle = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => TarangBottomSheet(
        title: title,
        showDragHandle: showDragHandle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final border = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusCard),
        ),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle) ...[
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTextStyles.h5.copyWith(
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  TarangIconButton(
                    icon: const Icon(Icons.close_rounded),
                    size: 36,
                    hasBorder: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 16, color: border),
          ],
          Flexible(
            child: Padding(
              padding: padding ??
                  EdgeInsets.fromLTRB(
                    24,
                    title != null ? 0 : AppTheme.spaceM,
                    24,
                    MediaQuery.of(context).viewInsets.bottom +
                        AppTheme.spaceL,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 13. TarangSnackbar
//    Helper for showing a branded snackbar.
// ════════════════════════════════════════════════════════════════════════════

class TarangSnackbar {
  TarangSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    if (isError) {
      bg = (isDark ? AppTheme.dangerDark : AppTheme.dangerLight).withValues(alpha: 0.95);
      fg = Colors.white;
    } else if (isSuccess) {
      bg = (isDark ? AppTheme.successDark : AppTheme.successLight).withValues(alpha: 0.95);
      fg = Colors.white;
    } else {
      bg = isDark ? AppTheme.darkForeground : AppTheme.lightForeground;
      fg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w500),
        ),
        backgroundColor: bg,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COMPATIBILITY ALIASES
// These keep all existing screens compiling without modification.
// They delegate to the new Tarang components.
// ════════════════════════════════════════════════════════════════════════════

/// @deprecated Use [TarangLogo] instead.
class AppLogo extends TarangLogo {
  const AppLogo({super.key, double size = 80.0})
      : super(size: size, showText: false);
}

/// @deprecated Use [TarangButton] with variant primary instead.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: TarangButton(
          text: text,
          variant: TarangButtonVariant.primary,
          size: TarangButtonSize.lg,
          loading: isLoading,
          onPressed: onPressed,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
}

/// @deprecated Use [TarangButton] with variant secondary instead.
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: TarangButton(
          text: text,
          variant: TarangButtonVariant.secondary,
          size: TarangButtonSize.lg,
          loading: isLoading,
          onPressed: onPressed,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
}

/// @deprecated Use [TarangTextField] instead.
class CustomTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TarangTextField(
        label: labelText,
        hint: hintText,
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        rightIcon: suffixIcon,
        keyboardType: keyboardType,
      );
}

/// @deprecated Use [TarangTextField] with obscureText instead.
class PasswordField extends StatefulWidget {
  final String labelText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,
    required this.labelText,
    this.controller,
    this.validator,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TarangTextField(
        label: widget.labelText,
        controller: widget.controller,
        validator: widget.validator,
        obscureText: _obscure,
        rightIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        ),
      );
}

/// @deprecated Use [TarangAvatar] instead.
class CustomAvatar extends StatelessWidget {
  final String? url;
  final double radius;

  const CustomAvatar({super.key, this.url, this.radius = 24.0});

  @override
  Widget build(BuildContext context) {
    TarangAvatarSize sz;
    if (radius <= 16) {
      sz = TarangAvatarSize.sm;
    } else if (radius <= 22) {
      sz = TarangAvatarSize.md;
    } else if (radius <= 28) {
      sz = TarangAvatarSize.lg;
    } else {
      sz = TarangAvatarSize.xl;
    }
    return TarangAvatar(username: '?', avatarUrl: url, size: sz);
  }
}

/// @deprecated Use [TarangSkeleton] instead.
class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) => TarangSkeleton(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
}

/// @deprecated Use [TarangLoading] instead.
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const TarangLoading(),
            ),
        ],
      );
}

/// @deprecated Use [TarangDialog] / [TarangConfirmDialog] instead.
class AppDialogs {
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
  }) =>
      TarangDialog.show(
        context: context,
        title: title,
        description: message,
        child: Align(
          alignment: Alignment.centerRight,
          child: TarangButton(
            text: 'OK',
            variant: TarangButtonVariant.primary,
            size: TarangButtonSize.sm,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) =>
      TarangDialog.show(
        context: context,
        title: title,
        description: message,
        child: Align(
          alignment: Alignment.centerRight,
          child: TarangButton(
            text: 'OK',
            variant: TarangButtonVariant.primary,
            size: TarangButtonSize.sm,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
          ),
        ),
      );

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) =>
      TarangConfirmDialog.show(
        context: context,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
      );
}
