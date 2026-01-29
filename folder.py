import os

def create_flutter_structure():
    # Klasör yapısını tanımla
    structure = [
        "assets/i18n",
        "assets/content",
        "assets/rules",
        "lib/core/constants",
        "lib/core/logging",
        "lib/core/time",
        "lib/core/utils",
        "lib/kiosk",
        "lib/i18n",
        "lib/data/models",
        "lib/data/local",
        "lib/data/repositories",
        "lib/domain/engine",
        "lib/domain/session",
        "lib/domain/state",
        "lib/plc",
        "lib/ui/theme",
        "lib/ui/components",
        "lib/ui/screens",
        "lib/ui/navigation",
        "lib/viewmodel"
    ]

    # Dosyaları tanımla
    files = [
        "assets/i18n/strings_tr.json", "assets/i18n/strings_en.json", "assets/i18n/strings_ar.json",
        "assets/content/survey_questions.json", "assets/content/kvkk_legal_01.json",
        "assets/rules/scoring_rules_placeholder.json",
        "lib/main.dart", "lib/app.dart",
        "lib/core/constants/app_constants.dart",
        "lib/core/logging/app_logger.dart", "lib/core/logging/file_log_writer.dart",
        "lib/core/time/clock.dart",
        "lib/core/utils/seeded_random.dart", "lib/core/utils/result.dart",
        "lib/kiosk/kiosk_mode_controller.dart", "lib/kiosk/android_kiosk_controller.dart",
        "lib/i18n/locale_manager.dart", "lib/i18n/rtl_support.dart", "lib/i18n/string_repository.dart",
        "lib/data/models/language.dart", "lib/data/models/question.dart",
        "lib/data/models/survey.dart", "lib/data/models/kvkk_text.dart", "lib/data/models/recommendation.dart",
        "lib/data/local/asset_json_loader.dart", "lib/data/local/preferences_store.dart",
        "lib/data/repositories/survey_repository.dart", "lib/data/repositories/kvkk_repository.dart", "lib/data/repositories/i18n_repository.dart",
        "lib/domain/engine/recommendation_engine.dart", "lib/domain/engine/seeded_random_scoring_engine.dart", "lib/domain/engine/rule_based_scoring_engine_TODO.dart",
        "lib/domain/session/session_manager.dart", "lib/domain/session/timeout_watcher.dart",
        "lib/domain/state/app_state.dart", "lib/domain/state/app_state_machine.dart",
        "lib/plc/plc_client.dart", "lib/plc/modbus_client_TODO.dart",
        "lib/ui/theme/app_theme.dart", "lib/ui/theme/app_colors.dart", "lib/ui/theme/app_text_styles.dart",
        "lib/ui/components/bottom_nav_bar.dart", "lib/ui/components/language_switcher.dart", "lib/ui/components/primary_button.dart", "lib/ui/components/radio_option_list.dart",
        "lib/ui/screens/idle_screen.dart", "lib/ui/screens/kvkk_screen.dart", "lib/ui/screens/question_screen.dart", "lib/ui/screens/loading_screen.dart", "lib/ui/screens/result_screen.dart", "lib/ui/screens/error_screen.dart",
        "lib/ui/navigation/app_routes.dart", "lib/ui/navigation/app_router.dart",
        "lib/viewmodel/app_view_model.dart", "lib/viewmodel/app_view_model_provider.dart"
    ]

    print("📁 Klasörler oluşturuluyor...")
    for folder in structure:
        os.makedirs(folder, exist_ok=True)
    
    print("📄 Dosyalar oluşturuluyor...")
    for file_path in files:
        # Dosya zaten varsa üzerine yazmaz
        if not os.path.exists(file_path):
            with open(file_path, 'w', encoding='utf-8') as f:
                # Dart dosyalarına basit bir açıklama ekleyelim
                if file_path.endswith('.dart'):
                    f.write(f"// {os.path.basename(file_path)} file\n")
                elif file_path.endswith('.json'):
                    f.write("{}")
    
    print("\n✅ İşlem tamamlandı! Flutter mimarisi hazır.")

if __name__ == "__main__":
    create_flutter_structure()