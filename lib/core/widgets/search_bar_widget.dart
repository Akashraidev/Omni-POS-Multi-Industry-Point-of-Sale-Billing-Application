import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class SearchBarWidget extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onScanTap;
  final bool hasActiveFilters;
  final FocusNode? focusNode;

  const SearchBarWidget({
    super.key,
    this.hint = 'Search products, SKU, barcode...',
    required this.onSearchChanged,
    this.onFilterTap,
    this.onScanTap,
    this.hasActiveFilters = false,
    this.focusNode,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  void _onTextChange(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      widget.onSearchChanged(text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppTokens.borderLG,
        border: Border.all(color: theme.dividerColor),
        boxShadow: AppTokens.shadowSM,
      ),
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        onChanged: _onTextChange,
        decoration: InputDecoration(
          hintText: widget.hint,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                    setState(() {});
                  },
                ),
              if (widget.onScanTap != null)
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  tooltip: 'Scan Barcode',
                  onPressed: widget.onScanTap,
                ),
              if (widget.onFilterTap != null)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: 'Filter options',
                      onPressed: widget.onFilterTap,
                    ),
                    if (widget.hasActiveFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
