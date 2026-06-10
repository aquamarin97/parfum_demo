import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/viewmodel/app_view_model.dart';

/// Admin settings panel for configuring the product price and currency unit.
///
/// Changes are persisted immediately via [AppViewModel.setPrice] and
/// [AppViewModel.setCurrency] when the save button is pressed.
class PriceSettings extends StatefulWidget {
  const PriceSettings({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<PriceSettings> createState() => _PriceSettingsState();
}

class _PriceSettingsState extends State<PriceSettings> {
  late final TextEditingController _priceController;
  late final TextEditingController _currencyController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _priceController =
        TextEditingController(text: widget.viewModel.price.toString());
    _currencyController =
        TextEditingController(text: widget.viewModel.currency);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = int.tryParse(_priceController.text.trim());
    final currency = _currencyController.text.trim();

    if (price == null || price <= 0) {
      _showSnackBar('Geçerli bir fiyat girin', isError: true);
      return;
    }
    if (currency.isEmpty) {
      _showSnackBar('Para birimi boş olamaz', isError: true);
      return;
    }

    setState(() => _saving = true);
    await widget.viewModel.setPrice(price);
    await widget.viewModel.setCurrency(currency);
    setState(() => _saving = false);

    _showSnackBar('Kaydedildi');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: AppSizes.adminDialogBodySize)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fiyat Ayarları',
          style: TextStyle(
            fontSize: AppSizes.adminAppBarTitleSize,
            fontWeight: FontWeight.w800,
            color: AdminColors.primaryText,
          ),
        ),
        const SizedBox(height: 32),
        _AdminField(
          label: 'Fiyat',
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),
        _AdminField(
          label: 'Para Birimi',
          controller: _currencyController,
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 80,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: Colors.white),
                  )
                : const Text(
                    'Kaydet',
                    style: TextStyle(
                      fontSize: AppSizes.adminDialogActionSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _AdminField extends StatelessWidget {
  const _AdminField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.adminDialogBodySize,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: AppSizes.adminDialogActionSize,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}
