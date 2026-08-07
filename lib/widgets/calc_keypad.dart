import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/sound.dart';

/// A calculator keypad for entering amounts.
///
/// Works like a basic pocket calculator: pressing an operator applies whatever
/// is pending and starts a new entry. The bottom-right key does double duty -
/// while an operator is pending it shows "=" and resolves the expression into
/// a plain number; once nothing is pending it shows a check mark and actually
/// saves that number.
class CalcKeypad extends StatefulWidget {
  final double? initialValue;

  /// Label shown on the date key, e.g. "Today" or "Shrawan 12".
  final String dateLabel;
  final VoidCallback onDatePressed;

  /// Called with the final resolved amount when the check mark is pressed.
  final ValueChanged<double> onConfirm;

  const CalcKeypad({
    super.key,
    this.initialValue,
    required this.dateLabel,
    required this.onDatePressed,
    required this.onConfirm,
  });

  @override
  State<CalcKeypad> createState() => CalcKeypadState();
}

class CalcKeypadState extends State<CalcKeypad> {
  String _entry = '';
  double? _accumulator;
  String? _pendingOp;

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    if (v != null && v > 0) {
      _entry = v == v.roundToDouble()
          ? v.toStringAsFixed(0)
          : v.toString();
    }
  }

  double _apply(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? a : a / b;
      default:
        return b;
    }
  }

  void _digit(String d) {
    tapFeedback();
    setState(() {
      if (d == '.') {
        if (_entry.contains('.')) return;
        _entry = _entry.isEmpty ? '0.' : '$_entry.';
        return;
      }
      // Avoid building up leading zeros like "0005".
      if (_entry == '0') {
        _entry = d;
      } else {
        _entry = '$_entry$d';
      }
    });
  }

  void _operator(String op) {
    tapFeedback();
    setState(() {
      if (_entry.isNotEmpty) {
        final right = double.tryParse(_entry) ?? 0;
        _accumulator = _pendingOp == null
            ? right
            : _apply(_accumulator ?? 0, right, _pendingOp!);
        _entry = '';
      }
      _accumulator ??= 0;
      _pendingOp = op;
    });
  }

  void _backspace() {
    tapFeedback();
    setState(() {
      if (_entry.isNotEmpty) {
        _entry = _entry.substring(0, _entry.length - 1);
      } else if (_pendingOp != null) {
        _pendingOp = null;
      } else if (_accumulator != null) {
        _accumulator = null;
      }
    });
  }

  /// Resolves the pending expression into a plain number, ready either to be
  /// saved or built on further. This does not save anything by itself.
  void _equals() {
    tapFeedback();
    final op = _pendingOp;
    if (op == null) return;

    final left = _accumulator ?? 0;
    final right = _entry.isEmpty ? 0.0 : (double.tryParse(_entry) ?? 0);
    final result = _apply(left, right, op);

    setState(() {
      _accumulator = null;
      _pendingOp = null;
      _entry = result == result.roundToDouble()
          ? result.toStringAsFixed(0)
          : result.toString();
    });
  }

  /// Saves the current plain value. Only reachable when nothing is pending.
  void _confirm() {
    saveFeedback();
    final value = double.tryParse(_entry);
    if (value == null || value <= 0) return;
    widget.onConfirm(value);
  }

  String get _display {
    final buffer = StringBuffer();
    if (_pendingOp != null) {
      final acc = _accumulator ?? 0;
      buffer.write(acc == acc.roundToDouble()
          ? acc.toStringAsFixed(0)
          : acc.toString());
      buffer.write(' $_pendingOp ');
    }
    buffer.write(_entry);
    final text = buffer.toString().trim();
    return text.isEmpty ? '0' : text;
  }

  @override
  Widget build(BuildContext context) {
    final awaitingEquals = _pendingOp != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _key('7', onTap: () => _digit('7')),
            _key('8', onTap: () => _digit('8')),
            _key('9', onTap: () => _digit('9')),
            _key(
              widget.dateLabel,
              onTap: () {
                tapFeedback();
                widget.onDatePressed();
              },
              accentText: true,
              icon: Icons.event,
              flex: 2,
            ),
          ],
        ),
        Row(
          children: [
            _key('4', onTap: () => _digit('4')),
            _key('5', onTap: () => _digit('5')),
            _key('6', onTap: () => _digit('6')),
            _key('+', onTap: () => _operator('+')),
            _key('-', onTap: () => _operator('-')),
          ],
        ),
        Row(
          children: [
            _key('1', onTap: () => _digit('1')),
            _key('2', onTap: () => _digit('2')),
            _key('3', onTap: () => _digit('3')),
            _key('×', onTap: () => _operator('×')),
            _key('÷', onTap: () => _operator('÷')),
          ],
        ),
        Row(
          children: [
            _key('.', onTap: () => _digit('.')),
            _key('0', onTap: () => _digit('0')),
            _key('', icon: Icons.backspace_outlined, onTap: _backspace),
            _key(
              awaitingEquals ? '=' : '',
              icon: awaitingEquals ? null : Icons.check,
              onTap: awaitingEquals ? _equals : _confirm,
              background: AppColors.accent,
              foreground: Colors.black,
              flex: 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(
    String label, {
    required VoidCallback onTap,
    IconData? icon,
    Color? background,
    Color? foreground,
    bool accentText = false,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: background ?? AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: SizedBox(
              height: 54,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null)
                      Icon(
                        icon,
                        size: 20,
                        color: foreground ??
                            (accentText ? AppColors.accent : AppColors.text),
                      ),
                    if (icon != null && label.isNotEmpty)
                      const SizedBox(width: 5),
                    if (label.isNotEmpty)
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: accentText
                                ? 13
                                : (label == '=' ? 24 : 20),
                            fontWeight: FontWeight.w600,
                            color: foreground ??
                                (accentText
                                    ? AppColors.accent
                                    : AppColors.text),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

