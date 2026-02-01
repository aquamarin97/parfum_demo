// kvkk_screen.dart file
import 'package:flutter/material.dart';
import 'package:parfume_app/ui/components/outlinedbutton.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';

import '../../../viewmodel/app_view_model.dart';
import '../../components/primary_button.dart';
import '../../theme/app_text_styles.dart';

class KvkkScreen extends StatefulWidget {
  const KvkkScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<KvkkScreen> createState() => _KvkkScreenState();
}

class _KvkkScreenState extends State<KvkkScreen> {
  bool _approved = false;

  @override
  Widget build(BuildContext context) {
    final kvkk = widget.viewModel.kvkkText;
    final strings = widget.viewModel.strings;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 100,
        vertical: MediaQuery.of(context).size.height * 0.05,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kvkk.title, style: AppTextStyles.title),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(kvkk.body, style: AppTextStyles.body),
            ),
          ),
          SizedBox(height: 50),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Metinle hizalar
            children: [
              Transform.scale(
                scale:
                    3.5, // 1.0 standarttır, 2.5 kiosk için ideal bir büyüklük sunar
                child: Checkbox(
                  value: _approved,
                  activeColor:
                      AppColors.primary, // Marka rengine göre ayarlanabilir
                  onChanged: (value) {
                    setState(() => _approved = value ?? false);
                  },
                ),
              ),
              const SizedBox(
                width: 24,
              ), // Checkbox büyüdüğü için metinle araya biraz boşluk
              Expanded(
                child: Text(
                  kvkk.approvalLabel,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 40,
                  ), // Metni de büyütebiliriz
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PrimaryOutlinedButton(
                  label: strings.cancel,
                  onPressed: widget.viewModel.cancelToIdle,
                  fontSize: 50,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  label: kvkk.buttonLabel,
                  enabled: _approved,
                  onPressed: _approved ? widget.viewModel.startQuestions : null,
                  fontSize: 50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
