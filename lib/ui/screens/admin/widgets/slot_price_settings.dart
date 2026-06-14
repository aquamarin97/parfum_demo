import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parfume_app/core/strings/app_strings.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/viewmodel/app_view_model.dart';

/// Admin paneli — slot bazlı fiyat yönetimi.
///
/// Her slot için global fiyat yerine geçen bir override tanımlanabilir.
/// Override tanımlanmamış slotlar için [AppViewModel.price] kullanılır.
class SlotPriceSettings extends StatefulWidget {
  const SlotPriceSettings({
    super.key,
    required this.viewModel,
    required this.adminStrings,
  });

  final AppViewModel viewModel;
  final AppStrings adminStrings;

  static const int _slotCount = 24;

  @override
  State<SlotPriceSettings> createState() => _SlotPriceSettingsState();
}

class _SlotPriceSettingsState extends State<SlotPriceSettings> {
  AppStrings get _s => widget.adminStrings;

  @override
  Widget build(BuildContext context) {
    final globalPrice = widget.viewModel.price;
    final currency    = widget.viewModel.currency;
    final slotPrices  = widget.viewModel.slotPrices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _s.t('admin_slot_title'),
          style: TextStyle(
            fontSize: AppSizes.adminAppBarTitleSize,
            fontWeight: FontWeight.w800,
            color: AdminColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _s.t('admin_slot_subtitle')
              .replaceAll('{price}', '$globalPrice')
              .replaceAll('{currency}', currency),
          style: TextStyle(
            fontSize: AppSizes.adminDialogBodySize - 2,
            color: AdminColors.secondaryText,
          ),
        ),
        const SizedBox(height: 20),
        for (int slot = 1; slot <= SlotPriceSettings._slotCount; slot++) ...[
          _SlotRow(
            slot: slot,
            globalPrice: globalPrice,
            currency: currency,
            priceOverride: slotPrices[slot],
            adminStrings: _s,
            onEdit: () => _showEditDialog(context, slot, slotPrices[slot]),
            onClear: slotPrices.containsKey(slot)
                ? () => widget.viewModel.clearSlotPrice(slot)
                : null,
          ),
          if (slot < SlotPriceSettings._slotCount)
            Divider(color: Colors.white12, height: 1),
        ],
      ],
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    int slot,
    int? current,
  ) async {
    final controller = TextEditingController(
      text: current?.toString() ?? '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => _SlotEditDialog(
        slot: slot,
        controller: controller,
        currency: widget.viewModel.currency,
        globalPrice: widget.viewModel.price,
        adminStrings: _s,
      ),
    );

    controller.dispose();
    if (result != null && mounted) {
      if (result == 0) {
        await widget.viewModel.clearSlotPrice(slot);
      } else {
        await widget.viewModel.setSlotPrice(slot, result);
      }
      setState(() {});
    }
  }
}

// ---------------------------------------------------------------------------
// Slot satırı
// ---------------------------------------------------------------------------

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slot,
    required this.globalPrice,
    required this.currency,
    required this.priceOverride,
    required this.adminStrings,
    required this.onEdit,
    required this.onClear,
  });

  final int slot;
  final int globalPrice;
  final String currency;
  final int? priceOverride;
  final AppStrings adminStrings;
  final VoidCallback onEdit;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasOverride = priceOverride != null;
    final priceLabel  = hasOverride
        ? '${priceOverride!} $currency'
        : '$globalPrice $currency ${adminStrings.t('admin_slot_default_suffix')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '${adminStrings.t('admin_slot_label')} $slot',
              style: TextStyle(
                fontSize: AppSizes.adminDialogBodySize,
                fontWeight: FontWeight.w600,
                color: AdminColors.primaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              priceLabel,
              style: TextStyle(
                fontSize: AppSizes.adminDialogBodySize,
                color: hasOverride ? AdminColors.accent : AdminColors.secondaryText,
                fontWeight:
                    hasOverride ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 22),
            color: Colors.white70,
            tooltip: adminStrings.t('admin_slot_edit_tooltip'),
            onPressed: onEdit,
          ),
          if (onClear != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 22),
              color: Colors.red.shade300,
              tooltip: adminStrings.t('admin_slot_reset_tooltip'),
              onPressed: onClear,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Düzenleme diyalogu
// ---------------------------------------------------------------------------

class _SlotEditDialog extends StatelessWidget {
  const _SlotEditDialog({
    required this.slot,
    required this.controller,
    required this.currency,
    required this.globalPrice,
    required this.adminStrings,
  });

  final int slot;
  final TextEditingController controller;
  final String currency;
  final int globalPrice;
  final AppStrings adminStrings;

  @override
  Widget build(BuildContext context) {
    final s = adminStrings;
    return AlertDialog(
      backgroundColor: AdminColors.background,
      title: Text(
        '${s.t('admin_slot_label')} $slot ${s.t('admin_slot_price_suffix')}',
        style: TextStyle(
          color: AdminColors.primaryText,
          fontSize: AppSizes.adminDialogBodySize + 2,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.t('admin_slot_dialog_content')
                .replaceAll('{price}', '$globalPrice')
                .replaceAll('{currency}', currency),
            style: TextStyle(
              color: AdminColors.secondaryText,
              fontSize: AppSizes.adminDialogBodySize - 2,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              color: AdminColors.primaryText,
              fontSize: AppSizes.adminDialogActionSize,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white12,
              suffixText: currency,
              suffixStyle: TextStyle(color: AdminColors.secondaryText),
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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.t('admin_cancel'),
              style: TextStyle(color: AdminColors.secondaryText)),
        ),
        if (controller.text.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.of(context).pop(0),
            child: Text(s.t('admin_slot_reset'),
                style: TextStyle(color: Colors.red.shade300)),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.accent,
          ),
          onPressed: () {
            final val = int.tryParse(controller.text.trim());
            if (val != null && val > 0) {
              Navigator.of(context).pop(val);
            } else if (controller.text.trim().isEmpty) {
              Navigator.of(context).pop(0);
            }
          },
          child: Text(s.t('admin_save'),
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
