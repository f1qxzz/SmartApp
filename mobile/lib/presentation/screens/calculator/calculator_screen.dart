import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartlife_app/core/theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _history = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldClearDisplay = false;

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _display = '0';
        _history = '';
        _firstOperand = null;
        _operator = null;
        _shouldClearDisplay = false;
      } else if (value == '⌫') {
        if (_shouldClearDisplay) return;
        if (_display == 'Error') {
          _display = '0';
          return;
        }
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
        } else {
          _display = '0';
        }
      } else if (value == '+' || value == '-' || value == '×' || value == '÷') {
        if (_display == 'Error') return;
        if (_operator != null && !_shouldClearDisplay) {
          _calculateResult();
        }
        _firstOperand = double.tryParse(_display.replaceAll(',', ''));
        if (_firstOperand == null) return;
        _operator = value;
        _history = '$_display $value';
        _shouldClearDisplay = true;
      } else if (value == '=') {
        if (_operator != null && _display != 'Error') {
          _calculateResult();
          _operator = null;
          _history = '';
        }
      } else if (value == '%') {
        if (_display == 'Error') return;
        double current = double.tryParse(_display) ?? 0;
        _display = _formatResult(current / 100);
      } else if (value == '±') {
        if (_display == 'Error') return;
        if (_display != '0') {
          if (_display.startsWith('-')) {
            _display = _display.substring(1);
          } else {
            _display = '-$_display';
          }
        }
      } else if (value == '.') {
        if (_display == 'Error') _display = '0';
        if (_shouldClearDisplay) {
          _display = '0.';
          _shouldClearDisplay = false;
        } else if (!_display.contains('.')) {
          _display += '.';
        }
      } else {
        // Numbers
        if (_display == 'Error') _display = '0';
        if (_display == '0' || _shouldClearDisplay) {
          _display = value;
          _shouldClearDisplay = false;
        } else {
          // Limit length to prevent overflow easily
          if (_display.length < 15) {
             _display += value;
          }
        }
      }
    });
  }

  void _calculateResult() {
    if (_firstOperand == null || _operator == null) return;
    double secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          _display = 'Error';
          _firstOperand = null;
          _operator = null;
          _shouldClearDisplay = true;
          return;
        }
        result = _firstOperand! / secondOperand;
        break;
    }

    _display = _formatResult(result);
    _firstOperand = result;
    _shouldClearDisplay = true;
  }

  String _formatResult(double result) {
    if (result == result.truncateToDouble()) {
      return result.truncate().toString();
    }
    String str = result.toStringAsFixed(8);
    // remove trailing zeros
    while (str.contains('.') && (str.endsWith('0') || str.endsWith('.'))) {
      if (str.endsWith('.')) {
        str = str.substring(0, str.length - 1);
        break;
      }
      str = str.substring(0, str.length - 1);
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Display Area
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      _history,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _display,
                        style: GoogleFonts.poppins(
                          fontSize: 68,
                          fontWeight: FontWeight.w400,
                          color: _display == 'Error' 
                              ? AppColors.error 
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Divider
            Divider(
              height: 1,
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
            // Keypad Area
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Column(
                  children: <Widget>[
                    _buildRow(['C', '±', '%', '÷'], isDark),
                    _buildRow(['7', '8', '9', '×'], isDark),
                    _buildRow(['4', '5', '6', '-'], isDark),
                    _buildRow(['1', '2', '3', '+'], isDark),
                    _buildRow(['0', '.', '⌫', '='], isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> buttons, bool isDark) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map((String text) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: _CalculatorButton(
                text: text,
                isDark: isDark,
                onPressed: () => _onButtonPressed(text),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CalculatorButton extends StatelessWidget {
  final String text;
  final bool isDark;
  final VoidCallback onPressed;

  const _CalculatorButton({
    required this.text,
    required this.isDark,
    required this.onPressed,
  });

  bool get _isOperator => text == '÷' || text == '×' || text == '-' || text == '+';
  bool get _isAction => text == 'C' || text == '±' || text == '%' || text == '⌫';
  bool get _isEquals => text == '=';

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color buttonColor;

    if (_isEquals) {
      buttonColor = AppColors.primary;
      textColor = Colors.white;
    } else if (_isOperator) {
      buttonColor = isDark ? const Color(0xFF4C5372) : const Color(0xFFE2D4E0);
      textColor = isDark ? Colors.white : AppColors.primaryDark;
    } else if (_isAction) {
      buttonColor = isDark ? AppColors.surfaceDark : Colors.white;
      textColor = const Color(0xFFEF4444); 
    } else {
      buttonColor = isDark ? AppColors.backgroundDark : Colors.white;
      textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    }

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(24),
      elevation: _isEquals ? 4 : 0,
      shadowColor: AppColors.primary.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: _isOperator || _isEquals || _isAction ? 26 : 28,
              fontWeight: _isEquals ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
