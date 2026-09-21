import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/item.dart';
import '../../services/api_client.dart';
import '../../services/item_repository.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({required this.type, super.key});
  final ItemType type;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _specificLocation = TextEditingController();
  final _color = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _picker = ImagePicker();
  late final ItemRepository _repository;
  List<Map<String, dynamic>> _categories = [];
  String? _categoryId;
  DateTime _date = DateTime.now();
  XFile? _photo;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repository = ItemRepository(ApiClient.instance);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _categoryId = categories.isEmpty ? null : categories.first['id'] as String;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (mounted && photo != null) setState(() => _photo = photo);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    setState(() => _saving = true);
    try {
      final item = await _repository.createItem(
        type: widget.type,
        title: _title.text,
        categoryId: _categoryId!,
        description: _description.text,
        date: _date,
        location: _location.text,
        specificLocation: _specificLocation.text,
        color: _color.text,
        brand: _brand.text,
        model: _model.text,
      );
      if (_photo != null) {
        await _repository.uploadImage(
          itemId: item.id,
          fileName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          bytes: await _photo!.readAsBytes(),
        );
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Report submitted'),
          content: Text(
            'Your ${widget.type == ItemType.lost ? 'lost' : 'found'} item is live. '
            'Reference number: ${item.referenceNumber}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('The report could not be submitted. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _location,
      _specificLocation,
      _color,
      _brand,
      _model,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLost = widget.type == ItemType.lost;
    return Scaffold(
      appBar: AppBar(
        title: Text(isLost ? 'Report lost item' : 'Report found item'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLost
                                ? 'Give your item the best chance of coming home.'
                                : 'A few details can help an owner identify it.',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _Field(
                            controller: _title,
                            label: 'Item title',
                            hint: 'e.g. Black Dell laptop',
                            required: true,
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _categoryId,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: _categories
                                .map(
                                  (category) => DropdownMenuItem<String>(
                                    value: category['id'] as String,
                                    child: Text(category['name'] as String),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() => _categoryId = value),
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _description,
                            label: 'Description',
                            hint: 'Describe the item and what makes it identifiable.',
                            maxLines: 4,
                            required: true,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'When and where',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                initialDate: _date,
                              );
                              if (picked != null) setState(() => _date = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Date'),
                              child: Text('${_date.day}/${_date.month}/${_date.year}'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _location,
                            label: 'Campus location',
                            hint: 'e.g. Main library',
                            required: true,
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _specificLocation,
                            label: 'Specific location',
                            hint: 'e.g. 2nd floor study area',
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Identifying details',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: _Field(controller: _color, label: 'Color')),
                              const SizedBox(width: 12),
                              Expanded(child: _Field(controller: _brand, label: 'Brand')),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _Field(controller: _model, label: 'Model or other detail'),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _pickPhoto,
                            icon: Icon(_photo == null ? Icons.add_a_photo_outlined : Icons.check),
                            label: Text(_photo == null ? 'Add a photo (optional)' : 'Photo selected'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _saving ? null : _submit,
                              child: _saving
                                  ? const CircularProgressIndicator()
                                  : const Text('Submit report'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.required = false,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    );
  }
}
