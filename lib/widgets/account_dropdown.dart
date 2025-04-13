import 'package:flutter/material.dart';

class AccountDropdown extends StatefulWidget {
  final List<String> accounts;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? labelText;
  final bool isRequired;

  const AccountDropdown({
    Key? key,
    required this.accounts,
    this.initialValue,
    required this.onChanged,
    this.labelText,
    this.isRequired = true,
  }) : super(key: key);

  @override
  State<AccountDropdown> createState() => _AccountDropdownState();
}

class _AccountDropdownState extends State<AccountDropdown> {
  late TextEditingController _controller;
  List<String> _filteredAccounts = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _filteredAccounts = widget.accounts;
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _showOverlay() {
    _hideOverlay();
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                minWidth: size.width,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _filteredAccounts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_filteredAccounts[index]),
                    onTap: () {
                      _controller.text = _filteredAccounts[index];
                      widget.onChanged(_filteredAccounts[index]);
                      _hideOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filterAccounts(String query) {
    setState(() {
      _filteredAccounts = widget.accounts
          .where((account) => account.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
    
    if (_filteredAccounts.isNotEmpty && query.isNotEmpty) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.labelText ?? 'Account',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showOverlay,
          ),
        ),
        onChanged: (value) {
          _filterAccounts(value);
          widget.onChanged(value);
        },
        onTap: _showOverlay,
        validator: widget.isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select or enter an account';
                }
                return null;
              }
            : null,
      ),
    );
  }
}