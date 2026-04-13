import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final double? width;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.gradient,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isEnabled ? (_) => _controller.forward() : null,
      onTapUp: _isEnabled
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: _isEnabled ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, Widget? child) => Transform.scale(
          scale: _isEnabled ? _scaleAnim.value : 1,
          child: child,
        ),
        child: Opacity(
          opacity: _isEnabled ? 1 : 0.65,
          child: Container(
            width: widget.width ?? double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: widget.isOutlined
                  ? null
                  : (widget.gradient ?? AppColors.gradientPrimary),
              borderRadius: BorderRadius.circular(16),
              border: widget.isOutlined
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
              boxShadow: widget.isOutlined
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (widget.icon != null) ...<Widget>[
                          widget.icon!,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: AppTextStyles.button.copyWith(
                            color: widget.isOutlined
                                ? AppColors.primary
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class InputField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLines;

  const InputField({
    super.key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Focus(
      onFocusChange: (bool focused) => setState(() => _isFocused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isFocused
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: widget.prefixIcon,
                  )
                : null,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 52, minHeight: 52),
            suffixIcon: widget.suffixIcon,
          ),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final String imageUrl;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;
  final String? avatarUrl;

  const ChatBubble({
    super.key,
    required this.text,
    this.imageUrl = '',
    required this.isMe,
    required this.timestamp,
    this.isRead = false,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!isMe) ...<Widget>[
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 16, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppColors.gradientPrimary : null,
                    color: isMe
                        ? null
                        : (isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: (isMe ? AppColors.primary : Colors.black)
                            .withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (imageUrl.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: text.trim().isNotEmpty ? 10 : 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: 210,
                              height: 170,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 210,
                                height: 170,
                                color: isMe
                                    ? Colors.white.withOpacity(0.2)
                                    : (isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.surfaceLight),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 22,
                                  color: isMe
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (text.trim().isNotEmpty)
                        Text(
                          text,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.5,
                            color: isMe
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary),
                          ),
                        ),
                      if (text.trim().isEmpty && imageUrl.trim().isEmpty)
                        Text(
                          'Pesan kosong',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isMe
                                ? Colors.white70
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textTertiary),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _formatTime(timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textTertiary,
                      ),
                    ),
                    if (isMe) ...<Widget>[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: isRead
                            ? AppColors.secondary
                            : AppColors.textTertiary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final String h = dt.hour.toString().padLeft(2, '0');
    final String m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class FinanceCard extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final String description;
  final double amount;
  final DateTime date;
  final IconData icon;
  final Color color;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const FinanceCard({
    super.key,
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.icon,
    required this.color,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey<String>(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 24),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      '${category} - ${_formatDate(date)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '-${AppFormatters.currency(amount)}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${AppFormatters.weekDayShort(d)}, ${d.day} ${months[d.month - 1]}';
  }
}

class BalanceCard extends StatelessWidget {
  final double totalSpent;
  final double budget;
  final double income;

  const BalanceCard({
    super.key,
    required this.totalSpent,
    required this.budget,
    required this.income,
  });

  @override
  Widget build(BuildContext context) {
    final double pct =
        budget <= 0 ? 0 : (totalSpent / budget).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Total Pengeluaran',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Bulan Ini',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppFormatters.currency(totalSpent),
            style: AppTextStyles.moneyLarge(context),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Budget: ${AppFormatters.currency(budget)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pct > 0.8 ? AppColors.accentLight : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              _StatItem(
                label: 'Budget',
                value: AppFormatters.compactCurrency(income),
                icon: Icons.arrow_downward_rounded,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 24),
              _StatItem(
                label: 'Sisa',
                value: AppFormatters.compactCurrency(income - totalSpent),
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.accentLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D3147) : const Color(0xFFE5E7EB),
      highlightColor:
          isDark ? const Color(0xFF3D4160) : const Color(0xFFF3F4F6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List<AnimationController>.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..repeat(reverse: true),
    );
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final AnimationController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          3,
          (int i) => AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) => Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              width: 8,
              height: 8 + _controllers[i].value * 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(
                  0.4 + _controllers[i].value * 0.6,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.6),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
