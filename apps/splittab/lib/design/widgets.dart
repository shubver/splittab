import 'package:material_ui/material_ui.dart';

import 'icons.dart';

import '../data/currencies.dart';
import 'text_styles.dart';
import 'tokens.dart';

const Color _clear = Color(0x00000000);

/// Anything tappable. Gives every control the same states: hover shift, pressed scale of 0.98,
/// and a visible focus ring for keyboard users.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.hoverColor,
    this.borderColor,
    this.radius = Radii.xl,
    this.padding = EdgeInsets.zero,
    this.minHeight,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? hoverColor;
  final Color? borderColor;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? minHeight;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hover = false;
  bool _pressed = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = widget.onTap != null;
    final bg = enabled && _hover && widget.hoverColor != null
        ? widget.hoverColor!
        : (widget.color ?? _clear);
    final radius = BorderRadius.circular(widget.radius);

    final box = AnimatedContainer(
      duration: Motion.fade,
      curve: Motion.curve,
      constraints: widget.minHeight == null
          ? null
          : BoxConstraints(minHeight: widget.minHeight!),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: widget.borderColor == null
            ? null
            : Border.all(color: widget.borderColor!),
      ),
      foregroundDecoration: _focus
          ? BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: p.text, width: 2),
            )
          : null,
      child: widget.child,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed && !Motion.reduced(context) ? 0.98 : 1,
            duration: Motion.press,
            curve: Motion.curve,
            child: box,
          ),
        ),
      ),
    );
  }
}

enum ButtonKind { primary, secondary, quiet }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.primary,
    this.icon,
    this.expanded = false,
    this.small = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final IconData? icon;
  final bool expanded;
  final bool small;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color bg, Color hover, Color? border, Color fg) = switch (kind) {
      ButtonKind.primary => (
        p.accent,
        Color.lerp(p.accent, p.background, 0.12)!,
        null,
        p.onAccent,
      ),
      ButtonKind.secondary => (
        p.surface,
        p.hover,
        p.border,
        destructive ? p.negative : p.text,
      ),
      ButtonKind.quiet => (
        _clear,
        p.surface,
        null,
        destructive ? p.negative : p.text,
      ),
    };
    final style = (small ? AppText.buttonSm : AppText.buttonMd).copyWith(
      color: fg,
    );
    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon!, size: small ? 16 : 20, color: fg),
          const SizedBox(width: Space.s75),
        ],
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Pressable(
        onTap: onPressed,
        color: bg,
        hoverColor: hover,
        borderColor: border,
        radius: Radii.xl,
        minHeight: small ? Space.s500 : Space.s600,
        padding: const EdgeInsets.symmetric(
          vertical: Space.s75,
          horizontal: Space.s100,
        ),
        semanticLabel: label,
        child: content,
      ),
    );
  }
}

/// A round icon button (44 by 44 touch target).
class IconAction extends StatelessWidget {
  const IconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      hoverColor: p.surface,
      radius: Radii.full,
      semanticLabel: label,
      child: SizedBox(
        width: Space.s600 - Space.s50,
        height: Space.s600 - Space.s50,
        child: Center(child: Icon(icon, size: 24, color: p.text)),
      ),
    );
  }
}

/// A selectable chip.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.onAccent : p.text;
    return Pressable(
      onTap: onTap,
      color: selected ? p.accent : p.surface,
      hoverColor: selected ? Color.lerp(p.accent, p.background, 0.12) : p.hover,
      borderColor: selected ? p.accent : p.border,
      radius: Radii.full,
      minHeight: Space.s500,
      padding: const EdgeInsets.symmetric(
        vertical: Space.s75,
        horizontal: Space.s200,
      ),
      semanticLabel: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon!, size: 16, color: fg),
            const SizedBox(width: Space.s75),
          ],
          Text(label, style: AppText.body5.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// A flat bordered surface.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.s200),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (onTap != null) {
      return Pressable(
        onTap: onTap,
        color: p.surface,
        hoverColor: p.raised,
        borderColor: p.border,
        radius: Radii.xxl,
        padding: padding,
        child: child,
      );
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.xxl),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

/// Text input with the label above and an inline error below.
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.error,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.suffixText,
    this.autofocus = false,
    this.large = false,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? error;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? suffixText;
  final bool autofocus;
  final bool large;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          borderSide: BorderSide(color: color, width: width),
        );
    final hasError = error != null;
    final textStyle =
        (large ? AppText.numeric(AppText.heading4) : AppText.body3).copyWith(
          color: p.text,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.caption1.copyWith(color: p.textMuted)),
          const SizedBox(height: Space.s75),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textAlign: textAlign,
          style: textStyle,
          cursorColor: p.text,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: p.surface,
            hintText: hint,
            hintStyle: textStyle.copyWith(color: p.textMuted),
            suffixText: suffixText,
            suffixStyle: AppText.body5.copyWith(color: p.textMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Space.s200,
              vertical: Space.s100,
            ),
            border: border(hasError ? p.negative : p.border),
            enabledBorder: border(hasError ? p.negative : p.border),
            focusedBorder: border(hasError ? p.negative : p.text, 2),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: Space.s75),
          Text(error!, style: AppText.caption2.copyWith(color: p.negative)),
        ],
      ],
    );
  }
}

/// Two or three way switch.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const gap = Space.s50;
    return Container(
      padding: const EdgeInsets.all(gap),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(i),
                color: i == index ? p.hover : _clear,
                hoverColor: i == index ? p.hover : p.raised,
                radius: Radii.nested(Radii.xl, gap),
                minHeight: Space.s500,
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.s100,
                  vertical: Space.s75,
                ),
                semanticLabel: labels[i],
                child: Center(
                  child: Text(
                    labels[i],
                    style: AppText.body5.copyWith(
                      color: i == index ? p.text : p.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A composed "getting started" view for a screen with nothing in it yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.s300),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Space.s700,
                height: Space.s700,
                decoration: BoxDecoration(
                  color: p.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.border),
                ),
                child: Center(child: Icon(icon, size: 28, color: p.text)),
              ),
              const SizedBox(height: Space.s300),
              Text(
                title,
                style: AppText.heading6.copyWith(color: p.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.s75),
              Text(
                body,
                style: AppText.body6.copyWith(color: p.textMuted),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: Space.s300),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An error shown inline, never as a pop up.
class InlineMessage extends StatelessWidget {
  const InlineMessage(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Space.s100),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: p.negative),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Ph.warningCircle, size: 20, color: p.negative),
          const SizedBox(width: Space.s75),
          Expanded(
            child: Text(text, style: AppText.body6.copyWith(color: p.text)),
          ),
        ],
      ),
    );
  }
}

/// Placeholder block shaped like the real content. Only its opacity moves.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = Radii.lg,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
    if (Motion.reduced(context)) return Opacity(opacity: 0.7, child: box);
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.45,
        end: 1,
      ).animate(CurvedAnimation(parent: _c, curve: Motion.curve)),
      child: box,
    );
  }
}

/// Rises a short distance and fades in once. Plain fade when motion is reduced.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0});

  final Widget child;

  /// Position in a list; later items start a little later (capped).
  final int index;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.reveal,
  );

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 400));
    Future<void>.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Motion.curve);
    final fade = FadeTransition(opacity: curved, child: widget.child);
    if (Motion.reduced(context)) return fade;
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (1 - curved.value) * Space.s300),
        child: child,
      ),
      child: fade,
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.size = Space.s500});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.raised,
        shape: BoxShape.circle,
        border: Border.all(color: p.border),
      ),
      child: Center(
        child: Text(initial, style: AppText.body4.copyWith(color: p.text)),
      ),
    );
  }
}

/// An amount coloured by sign: green when owed, red when owing, muted when zero.
class AmountText extends StatelessWidget {
  const AmountText(
    this.minor,
    this.currency, {
    super.key,
    this.style,
    this.showPlus = true,
    this.align,
  });

  final int minor;
  final String currency;
  final TextStyle? style;
  final bool showPlus;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = minor > 0
        ? p.positive
        : (minor < 0 ? p.negative : p.textMuted);
    return Text(
      formatMoney(minor, currency, showPlus: showPlus),
      textAlign: align,
      style: AppText.numeric(style ?? AppText.body4).copyWith(color: color),
    );
  }
}

/// A small heading above a group.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Text(text, style: AppText.title4.copyWith(color: p.textMuted)),
        ),
        ?trailing,
      ],
    );
  }
}

/// Wraps sheet content: grabber, optional title, keyboard padding.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.s100),
          Center(
            child: Container(
              width: Space.s500,
              height: Space.s50,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(Radii.full),
              ),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.s300,
                Space.s200,
                Space.s300,
                Space.s75,
              ),
              child: Text(
                title!,
                style: AppText.heading6.copyWith(color: p.text),
              ),
            ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: builder,
  );
}

/// Shows a calm confirmation message. It floats above the bottom button bar so it never covers
/// the main actions.
void showNotice(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) => showNoticeOn(
  ScaffoldMessenger.of(context),
  message,
  actionLabel: actionLabel,
  onAction: onAction,
);

/// Same as [showNotice], for when the messenger was grabbed before leaving the screen.
void showNoticeOn(
  ScaffoldMessengerState messenger,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      margin: const EdgeInsets.fromLTRB(
        Space.s200,
        Space.s0,
        Space.s200,
        Space.s900 - Space.s75,
      ),
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      duration: const Duration(seconds: 4),
    ),
  );
}
