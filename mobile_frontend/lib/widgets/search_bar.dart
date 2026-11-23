import 'package:flutter/material.dart';

class CoinSearchBar extends StatefulWidget {
  const CoinSearchBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<CoinSearchBar> createState() => _CoinSearchBarState();
}

class _CoinSearchBarState extends State<CoinSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          widget.onChanged(value);
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search coins',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
