import 'package:crmapp/app_state/business_provider.dart';
import 'package:crmapp/models/type_model.dart';
import 'package:crmapp/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TypeSelectDialog extends ConsumerStatefulWidget {
  final List<TypeModel> types;
  final int? selectedId;

  const TypeSelectDialog({
    super.key,
    required this.types,
    this.selectedId,
  });

  @override
  ConsumerState<TypeSelectDialog> createState() => _TypeSelectDialogState();
}

class _TypeSelectDialogState extends ConsumerState<TypeSelectDialog> {
  late List<TypeModel> _types;
  final _searchCtrl = TextEditingController();
  final _newTypeCtrl = TextEditingController();
  String? _error;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _types = List<TypeModel>.from(widget.types);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _newTypeCtrl.dispose();
    super.dispose();
  }

  List<TypeModel> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _types;
    return _types.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _create() async {
    final name = _newTypeCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a type name');
      return;
    }

    final business = ref.read(businessProvider);
    if (business == null) {
      setState(() => _error = 'Business not loaded');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      final created = await ProductService().createType(
        name: name,
        businessId: business.id,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return AlertDialog(
      backgroundColor: const Color(0xFF141414),
      title: const Text(
        'Select type',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search types',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No types yet. Add one below.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final type = items[i];
                        final selected = type.id == widget.selectedId;
                        return ListTile(
                          selected: selected,
                          selectedTileColor: Colors.white10,
                          title: Text(
                            type.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Color(0xFFFFD54F),
                                )
                              : null,
                          onTap: () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(type),
                        );
                      },
                    ),
            ),
            const Divider(color: Colors.white24),
            TextField(
              controller: _newTypeCtrl,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _create(),
              decoration: const InputDecoration(
                labelText: 'New type name',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _creating ? null : _create,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD54F),
            foregroundColor: Colors.black,
          ),
          child: _creating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add type'),
        ),
      ],
    );
  }
}
