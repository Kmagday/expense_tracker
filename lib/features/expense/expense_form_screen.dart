import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/expense_models.dart';
import '../../blocs/expense_bloc.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../blocs/budget_bloc.dart';
import '../../blocs/ai_bloc.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/currency_cubit.dart';
import '../../domain/services/receipt_ocr_service.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class ExpenseFormScreen extends StatefulWidget {
  final ExpenseModel? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtl;
  late TextEditingController _noteCtl;
  late TextEditingController _tagsCtl;
  int? _categoryId;
  int? _accountId;
  DateTime _date = DateTime.now();
  String? _paymentMethod;
  bool _isRecurring = false;
  String? _recurringFrequency;
  String? _receiptPath;
  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amountCtl = TextEditingController(text: e != null ? e.amount.toString() : '');
    _noteCtl = TextEditingController(text: e?.note ?? '');
    _tagsCtl = TextEditingController(text: e?.tags.isNotEmpty == true ? e!.tags.join(', ') : '');
    _categoryId = e?.categoryId;
    _accountId = e?.accountId;
    _date = e?.date ?? DateTime.now();
    _paymentMethod = e?.paymentMethod;
    _isRecurring = e?.isRecurring ?? false;
    _recurringFrequency = e?.recurringFrequency;
    _receiptPath = e?.receiptPath;
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    _tagsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExpenseBloc>().state;
    final categories = state.categories;
    final accounts = state.accounts;
    final symbol = context.watch<CurrencyCubit>().state.symbol;

    final effectiveCategoryId = _categoryId != null && categories.any((c) => c.id == _categoryId)
        ? _categoryId
        : null;
    final effectiveAccountId = _accountId != null && accounts.any((a) => a.id == _accountId)
        ? _accountId
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? PageTitles.editExpense : PageTitles.addExpense),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$symbol ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: effectiveCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories.map((c) => DropdownMenuItem(
                value: c.id,
                child: Row(children: [
                  Icon(iconFromString(c.icon), size: 20, color: Color(c.color)),
                  const SizedBox(width: 8),
                  Text(c.name),
                ]),
              )).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? UiLabels.selectCategory : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: effectiveAccountId,
              decoration: const InputDecoration(labelText: UiLabels.accountOptional),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...accounts.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Row(children: [
                    Icon(iconFromString(a.icon), size: 20, color: Color(a.color)),
                    const SizedBox(width: 8),
                    Text('${a.name} ($symbol${a.balance.toStringAsFixed(0)})'),
                  ]),
                )),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Date: ${DateFormat.yMMMd().format(_date)}'),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: UiLabels.paymentMethodOptional),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Card', child: Text('Card')),
                DropdownMenuItem(value: PaymentMethods.eWallet, child: Text(PaymentMethods.eWallet)),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtl,
              decoration: const InputDecoration(labelText: UiLabels.noteOptional),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.document_scanner),
                  tooltip: 'Scan Receipt',
                  onPressed: _isSaving ? null : () => _scanReceipt(ImageSource.camera),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Take Photo',
                  onPressed: _isSaving ? null : () => _pickPhoto(ImageSource.camera),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  tooltip: 'Choose from Gallery',
                  onPressed: _isSaving ? null : () => _pickPhoto(ImageSource.gallery),
                ),
                if (_receiptPath != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickPhoto(ImageSource.gallery),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_receiptPath!),
                              height: 80,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Text('Invalid image'),
                            ),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _receiptPath = null),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_receiptPath == null)
                  TextButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Receipt'),
                  ),
              ],
            ),
            TextFormField(
              controller: _tagsCtl,
              decoration: const InputDecoration(
                labelText: UiLabels.tagsOptional,
                hintText: UiLabels.tagHint,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Recurring Expense'),
              subtitle: _isRecurring ? Text(_recurringFrequency ?? 'Monthly') : null,
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            if (_isRecurring)
              DropdownButtonFormField<String>(
                value: _recurringFrequency ?? 'monthly',
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (v) => setState(() => _recurringFrequency = v),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'Update' : 'Save'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _delete,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file != null) setState(() => _receiptPath = file.path);
  }

  Future<void> _scanReceipt(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final ocr = ReceiptOcrService();
      debugPrint('[ExpenseForm] scanning receipt: ${file.path}');
      final result = await ocr.processImage(file.path);
      ocr.dispose();
      debugPrint('[ExpenseForm] OCR result - amount: ${result.amount}, date: ${result.date}, merchant: ${result.merchant}');

      if (mounted) {
        setState(() {
          _receiptPath = file.path;
          if (result.amount != null) _amountCtl.text = result.amount!.toStringAsFixed(2);
          if (result.date != null) _date = result.date!;
          if (result.merchant != null && _noteCtl.text.isEmpty) {
            _noteCtl.text = result.merchant!;
          }
        });

        final parts = <String>[];
        if (result.amount != null) parts.add('\$${result.amount!.toStringAsFixed(2)}');
        if (result.date != null) parts.add(DateFormat.yMMMd().format(result.date!));
        if (result.merchant != null) parts.add(result.merchant!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanned: ${parts.join(' · ')}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final amount = double.parse(_amountCtl.text);
    debugPrint('[ExpenseForm] ${_isEditing ? "updating" : "saving"} expense - amount: $amount, categoryId: $_categoryId, accountId: $_accountId, date: $_date');
    try {
      if (_isEditing) {
        context.read<ExpenseBloc>().add(UpdateExpenseEvent(
          id: widget.expense!.id,
          amount: amount,
          categoryId: _categoryId,
          date: _date,
          note: _noteCtl.text.isEmpty ? null : _noteCtl.text,
          accountId: _accountId,
          paymentMethod: _paymentMethod,
          receiptPath: _receiptPath,
          tags: _parseTags(),
        ));
      } else {
        context.read<ExpenseBloc>().add(AddExpenseEvent(
          amount: amount,
          categoryId: _categoryId!,
          date: _date,
          note: _noteCtl.text.isEmpty ? null : _noteCtl.text,
          accountId: _accountId,
          paymentMethod: _paymentMethod,
          isRecurring: _isRecurring,
          recurringFrequency: _isRecurring ? _recurringFrequency : null,
          receiptPath: _receiptPath,
          tags: _parseTags(),
        ));
      }
      final expenseBloc = context.read<ExpenseBloc>();
      await expenseBloc.stream.firstWhere((s) => s.isLoading);
      await expenseBloc.stream.firstWhere((s) => !s.isLoading);
      if (!mounted) return;
      context.read<DashboardBloc>().add(LoadDashboard());
      context.read<BudgetBloc>().add(LoadBudgets());
      context.read<AIBloc>().add(LoadAIInsights());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? AppMessages.expenseUpdated : AppMessages.expenseAdded)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _delete() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(UiLabels.deleteExpenseTitle),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        debugPrint('[ExpenseForm] deleting expense id=${widget.expense!.id}');
        context.read<ExpenseBloc>().add(DeleteExpenseEvent(widget.expense!.id));
        final expenseBloc = context.read<ExpenseBloc>();
        await expenseBloc.stream.firstWhere((s) => s.isLoading);
        await expenseBloc.stream.firstWhere((s) => !s.isLoading);
        if (!mounted) return;
        context.read<DashboardBloc>().add(LoadDashboard());
        context.read<BudgetBloc>().add(LoadBudgets());
        context.read<AIBloc>().add(LoadAIInsights());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppMessages.expenseDeleted)),
        );
        Navigator.pop(context, true);
      }
    });
  }

  List<String> _parseTags() {
    final raw = _tagsCtl.text;
    if (raw.trim().isEmpty) return const [];
    return raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }
}
