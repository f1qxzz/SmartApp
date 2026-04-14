import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';

class TransactionFormValue {
  final String title;
  final String categoryId;
  final String description;
  final double amount;
  final DateTime date;

  const TransactionFormValue({
    required this.title,
    required this.categoryId,
    required this.description,
    required this.amount,
    required this.date,
  });
}

class TransactionFormSheet extends StatefulWidget {
  final Future<void> Function(TransactionFormValue value) onSubmit;
  final TransactionFormValue? initialValue;
  final String submitLabel;
  final String title;

  const TransactionFormSheet({
    super.key,
    required this.onSubmit,
    this.initialValue,
    this.submitLabel = 'Simpan',
    this.title = 'Catat Transaksi',
  });

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedCategory;
  bool _submitting = false;

  final List<(String, IconData, String, Color)> _categories =
      <(String, IconData, String, Color)>[
    ('food', Icons.restaurant_rounded, 'Makanan', AppColors.categoryColors[0]),
    (
      'transport',
      Icons.directions_car_rounded,
      'Transport',
      AppColors.categoryColors[1],
    ),
    (
      'shopping',
      Icons.shopping_bag_rounded,
      'Belanja',
      AppColors.categoryColors[2],
    ),
    (
      'health',
      Icons.favorite_rounded,
      'Kesehatan',
      AppColors.categoryColors[3]
    ),
    (
      'entertainment',
      Icons.movie_rounded,
      'Hiburan',
      AppColors.categoryColors[4],
    ),
    (
      'bills',
      Icons.receipt_long_rounded,
      'Tagihan',
      AppColors.categoryColors[6]
    ),
    ('other', Icons.more_horiz_rounded, 'Lainnya', AppColors.categoryColors[7]),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _titleCtrl.text = initial?.title ?? '';
    _amountCtrl.text = initial != null ? initial.amount.toStringAsFixed(0) : '';
    _descCtrl.text = initial?.description ?? '';
    _selectedDate = initial?.date ?? DateTime.now();
    _selectedCategory = initial?.categoryId ?? 'food';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.dividerLight,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Isi data transaksi dengan lengkap untuk laporan yang lebih akurat.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleCtrl,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Judul transaksi',
                    filled: true,
                    fillColor:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  validator: (String? value) {
                    final input = value?.trim() ?? '';
                    if (input.isEmpty) {
                      return 'Judul wajib diisi';
                    }
                    if (input.length < 2) {
                      return 'Judul minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Jumlah',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white70),
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                            'Rp',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _amountCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 24,
                                  color: Colors.white38,
                                ),
                                border: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: false,
                              ),
                              validator: (String? value) {
                                final String input = value?.trim() ?? '';
                                if (input.isEmpty) {
                                  return 'Jumlah wajib diisi';
                                }
                                final double? amount = double.tryParse(input);
                                if (amount == null || amount <= 0) {
                                  return 'Jumlah tidak valid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kategori',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final bool isSelected = _selectedCategory == cat.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.$4.withValues(alpha: 0.15)
                              : (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? cat.$4 : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              cat.$2,
                              size: 16,
                              color:
                                  isSelected ? cat.$4 : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.$3,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? cat.$4
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.dividerLight,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Tanggal transaksi',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${AppFormatters.weekDayShort(_selectedDate)}, '
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Catatan (opsional)',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.submitLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final value = TransactionFormValue(
        title: _titleCtrl.text.trim(),
        categoryId: _selectedCategory,
        description: _descCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        date: _selectedDate,
      );
      await widget.onSubmit(value);
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
