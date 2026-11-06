import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

/// Single-column vertical wheel picker with a centered selection band.
class AppWheelPicker extends StatefulWidget {
  const AppWheelPicker({
    super.key,
    required this.values,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    this.height = 168,
    this.itemExtent = 28,
    this.semanticLabel = 'Wheel picker',
  });

  final List<String> values;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final double height;
  final double itemExtent;
  final String semanticLabel;

  @override
  State<AppWheelPicker> createState() => _AppWheelPickerState();
}

class _AppWheelPickerState extends State<AppWheelPicker> {
  late FixedExtentScrollController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _clamp(widget.selectedIndex);
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void didUpdateWidget(covariant AppWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selectedIndex = _clamp(widget.selectedIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToItem(_selectedIndex);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _clamp(int index) {
    if (widget.values.isEmpty) {
      return 0;
    }
    return index.clamp(0, widget.values.length - 1);
  }

  void _handleChanged(int index) {
    setState(() => _selectedIndex = index);
    widget.onSelectedIndexChanged(index);
  }

  Widget _buildItem(BuildContext context, int index) {
    final selected = index == _selectedIndex;
    return Center(
      child: Text(
        widget.values[index],
        style: selected
            ? AppTypography.bodyStrong.copyWith(
                fontSize: 15,
                color: AppColors.text,
              )
            : AppTypography.body.copyWith(
                fontSize: 12.5,
                color: AppColors.muted,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) {
      return SizedBox(height: widget.height);
    }
    return Semantics(
      label: widget.semanticLabel,
      value: widget.values[_selectedIndex],
      child: SizedBox(
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: widget.itemExtent,
              perspective: 0.001,
              diameterRatio: 1.2,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: _handleChanged,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.values.length,
                builder: _buildItem,
              ),
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  height: widget.itemExtent + 8,
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border(
                      top: BorderSide(color: AppColors.limeBorder45),
                      bottom: BorderSide(color: AppColors.limeBorder45),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
