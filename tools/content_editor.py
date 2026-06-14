from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from pathlib import Path

from PyQt6.QtCore import Qt
from PyQt6.QtGui import QColor, QFont, QPalette
from PyQt6.QtWidgets import (
    QAbstractItemView,
    QAbstractScrollArea,
    QApplication,
    QCheckBox,
    QFileDialog,
    QGridLayout,
    QGroupBox,
    QHBoxLayout,
    QInputDialog,
    QLabel,
    QLayout,
    QListWidget,
    QListWidgetItem,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QScrollArea,
    QSizePolicy,
    QSpinBox,
    QSplitter,
    QStyle,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SURVEY = ROOT / "assets" / "content" / "survey_questions.json"
DEFAULT_RULES = ROOT / "assets" / "rules" / "scoring_rules.json"
DEFAULT_PERFUMES = ROOT / "parfume_list.txt"
LANGUAGE_CODE = "tr"


STYLE_SHEET = """
QMainWindow {
    background-color: #f1f3f6;
}

QWidget {
    font-family: "Segoe UI", "Helvetica Neue", Arial, sans-serif;
    font-size: 10pt;
    color: #1f2937;
}

QLabel#appTitle {
    font-size: 15pt;
    font-weight: 700;
    color: #111827;
    padding: 2px 0;
}

QLabel#counterLabel {
    font-weight: 600;
    font-size: 11pt;
    color: #2563eb;
}

QLabel#selectorTitle {
    font-weight: 600;
    color: #374151;
}

QGroupBox {
    background-color: #ffffff;
    border: 1px solid #d8dce3;
    border-radius: 8px;
    margin-top: 6px;
    padding: 12px 10px 10px 10px;
    font-weight: 600;
    color: #374151;
}

QGroupBox::title {
    subcontrol-origin: border;
    subcontrol-position: top left;
    left: 12px;
    top: 2px;
    padding: 0 4px;
    background-color: #ffffff;
}

QWidget#perfumeSelector {
    background-color: #fafbfc;
    border: 1px solid #e5e7eb;
    border-radius: 6px;
}

QPushButton {
    background-color: #ffffff;
    border: 1px solid #d0d5dd;
    border-radius: 6px;
    padding: 6px 14px;
}

QPushButton:hover {
    background-color: #eef2ff;
    border-color: #94a3b8;
}

QPushButton:pressed {
    background-color: #e0e7ff;
}

QPushButton:disabled {
    color: #9ca3af;
    background-color: #f3f4f6;
    border-color: #e5e7eb;
}

QPushButton#smallButton {
    padding: 3px 10px;
    font-size: 9pt;
}

QPushButton#primaryButton {
    background-color: #2563eb;
    color: #ffffff;
    border: none;
    font-weight: 600;
}

QPushButton#primaryButton:hover {
    background-color: #1d4ed8;
}

QPushButton#primaryButton:pressed {
    background-color: #1e40af;
}

QPushButton#successButton {
    background-color: #16a34a;
    color: #ffffff;
    border: none;
    font-weight: 600;
}

QPushButton#successButton:hover {
    background-color: #15803d;
}

QPushButton#warningButton {
    background-color: #f59e0b;
    color: #ffffff;
    border: none;
    font-weight: 600;
}

QPushButton#warningButton:hover {
    background-color: #d97706;
}

QPushButton#dangerButton {
    color: #dc2626;
    border-color: #f3c2c2;
}

QPushButton#dangerButton:hover {
    background-color: #fee2e2;
    border-color: #fca5a5;
}

QLineEdit, QTextEdit, QSpinBox {
    background-color: #ffffff;
    border: 1px solid #d0d5dd;
    border-radius: 6px;
    padding: 6px;
    selection-background-color: #bfdbfe;
}

QListWidget {
    background-color: transparent;
    border: none;
    padding: 6px;
    selection-background-color: #bfdbfe;
}

QListWidget#optionList {
    background-color: #ffffff;
    border: 1px solid #d0d5dd;
    border-radius: 6px;
    padding: 6px 6px 10px 6px;
}

QLineEdit:focus, QTextEdit:focus, QSpinBox:focus {
    border: 1px solid #2563eb;
}

QListWidget::item {
    padding: 5px 6px;
    border-radius: 4px;
    min-height: 22px;
}

QListWidget::item:selected {
    background-color: #2563eb;
    color: #ffffff;
}

QListWidget QLineEdit {
    padding: 2px 6px;
    border: 2px solid #2563eb;
    border-radius: 4px;
    background-color: #ffffff;
    color: #1f2937;
    selection-background-color: #bfdbfe;
}

QLabel#optionIndicator {
    background-color: #eef2ff;
    border: 1px solid #c7d2fe;
    border-radius: 6px;
    padding: 8px 10px;
    font-weight: 600;
    color: #3730a3;
}

QCheckBox {
    spacing: 6px;
    padding: 2px;
}

QScrollArea {
    border: none;
    background-color: transparent;
}

QSplitter::handle {
    background-color: #e5e7eb;
}

QSplitter::handle:horizontal {
    width: 4px;
}

QSplitter::handle:vertical {
    height: 4px;
}
"""


def build_light_palette() -> QPalette:
    palette = QPalette()
    palette.setColor(QPalette.ColorRole.Window, QColor("#f1f3f6"))
    palette.setColor(QPalette.ColorRole.WindowText, QColor("#1f2937"))
    palette.setColor(QPalette.ColorRole.Base, QColor("#ffffff"))
    palette.setColor(QPalette.ColorRole.AlternateBase, QColor("#fafbfc"))
    palette.setColor(QPalette.ColorRole.ToolTipBase, QColor("#ffffff"))
    palette.setColor(QPalette.ColorRole.ToolTipText, QColor("#1f2937"))
    palette.setColor(QPalette.ColorRole.Text, QColor("#1f2937"))
    palette.setColor(QPalette.ColorRole.Button, QColor("#ffffff"))
    palette.setColor(QPalette.ColorRole.ButtonText, QColor("#1f2937"))
    palette.setColor(QPalette.ColorRole.Highlight, QColor("#2563eb"))
    palette.setColor(QPalette.ColorRole.HighlightedText, QColor("#ffffff"))
    return palette


@dataclass
class OptionData:
    text: str = ""
    score_perfumes: set[int] = field(default_factory=set)
    exclude_perfumes: set[int] = field(default_factory=set)
    points: int = 1


@dataclass
class QuestionData:
    id: int
    text: str = ""
    options: list[OptionData] = field(default_factory=list)


def load_perfumes(path: Path) -> list[tuple[int, str]]:
    if not path.exists():
        return [(i, f"Perfume {i}") for i in range(1, 25)]

    raw = path.read_text(encoding="utf-8", errors="replace")
    names: list[str] = []
    for line in raw.splitlines():
        item = line.strip()
        if not item:
            continue
        if item.lower() in {"man", "men", "woman", "women"}:
            continue
        names.append(item)

    if not names:
        names = [f"Perfume {i}" for i in range(1, 25)]
    return [(index + 1, name) for index, name in enumerate(names)]


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


class PerfumeSelector(QWidget):
    def __init__(self, title: str, perfumes: list[tuple[int, str]]) -> None:
        super().__init__()
        self.setObjectName("perfumeSelector")
        self._checks: dict[int, QCheckBox] = {}

        layout = QVBoxLayout(self)
        layout.setContentsMargins(8, 8, 8, 8)
        layout.setSpacing(6)

        header = QHBoxLayout()
        title_label = QLabel(title)
        title_label.setObjectName("selectorTitle")
        header.addWidget(title_label)
        header.addStretch()

        select_all = QPushButton("Tumunu sec")
        clear = QPushButton("Temizle")
        select_all.setObjectName("smallButton")
        clear.setObjectName("smallButton")
        select_all.clicked.connect(lambda: self._set_all(True))
        clear.clicked.connect(lambda: self._set_all(False))
        header.addWidget(select_all)
        header.addWidget(clear)
        layout.addLayout(header)

        grid_widget = QWidget()
        grid = QGridLayout(grid_widget)
        grid.setContentsMargins(2, 2, 2, 2)
        grid.setHorizontalSpacing(14)
        grid.setVerticalSpacing(4)
        grid.setSizeConstraint(QLayout.SizeConstraint.SetMinimumSize)

        columns = 1
        for index, (perfume_id, name) in enumerate(perfumes):
            check = QCheckBox(f"{perfume_id} - {name}")
            check.setToolTip(name)
            self._checks[perfume_id] = check
            grid.addWidget(check, index // columns, index % columns)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setWidget(grid_widget)
        scroll.setMinimumHeight(110)
        layout.addWidget(scroll)

    def selected(self) -> set[int]:
        return {pid for pid, check in self._checks.items() if check.isChecked()}

    def set_selected(self, selected: set[int]) -> None:
        for pid, check in self._checks.items():
            check.setChecked(pid in selected)

    def _set_all(self, checked: bool) -> None:
        for check in self._checks.values():
            check.setChecked(checked)


class ContentEditor(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Parfum Soru ve Puanlama Editoru")
        self.resize(1440, 900)
        self.setMinimumSize(1180, 880)

        self.perfumes = load_perfumes(DEFAULT_PERFUMES)
        self.questions: list[QuestionData] = []
        self.current_question_index = 0
        self.current_option_index = -1
        self._loading = False

        self._build_ui()
        self._load_defaults()

    def _build_ui(self) -> None:
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setContentsMargins(12, 12, 12, 12)
        root.setSpacing(8)

        # ---- Top bar ----
        toolbar = QHBoxLayout()
        toolbar.setSpacing(8)

        title_label = QLabel("Parfum Anketi - Icerik ve Puanlama Editoru")
        title_label.setObjectName("appTitle")
        toolbar.addWidget(title_label)
        toolbar.addStretch()

        self.import_button = QPushButton(" Import")
        self.export_button = QPushButton(" Export")
        self.validate_button = QPushButton(" Validate")
        self.export_button.setObjectName("successButton")
        self.validate_button.setObjectName("warningButton")
        self.import_button.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_DialogOpenButton))
        self.export_button.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_DialogSaveButton))
        self.validate_button.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_DialogApplyButton))
        self.import_button.setToolTip("Survey ve scoring JSON dosyalarini ice aktar")
        self.export_button.setToolTip("Duzenlenen veriyi JSON olarak disa aktar")
        self.validate_button.setToolTip("Tum sorulari ve secenekleri kontrol et")
        self.import_button.clicked.connect(self.import_files)
        self.export_button.clicked.connect(self.export_files)
        self.validate_button.clicked.connect(self.show_validation)
        toolbar.addWidget(self.import_button)
        toolbar.addWidget(self.export_button)
        toolbar.addWidget(self.validate_button)
        root.addLayout(toolbar)

        splitter = QSplitter(Qt.Orientation.Horizontal)
        root.addWidget(splitter, stretch=1)

        # ================= MAIN EDITOR =================
        main_area = QWidget()
        splitter.addWidget(main_area)

        left_layout = QVBoxLayout(main_area)
        left_layout.setContentsMargins(0, 0, 0, 0)
        left_layout.setSpacing(8)

        # Navigation row
        nav = QHBoxLayout()
        nav.setSpacing(6)

        self.prev_button = QPushButton()
        self.prev_button.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_ArrowBack))
        self.prev_button.setToolTip("Onceki soru")
        self.prev_button.setFixedWidth(40)

        self.next_button = QPushButton()
        self.next_button.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_ArrowForward))
        self.next_button.setToolTip("Sonraki soru")
        self.next_button.setFixedWidth(40)

        self.question_counter = QLabel("Soru 0 / 0")
        self.question_counter.setObjectName("counterLabel")
        self.question_counter.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.new_question_button = QPushButton(" Yeni soru")
        self.new_question_button.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_FileDialogNewFolder))

        self.delete_question_button = QPushButton(" Soruyu sil")
        self.delete_question_button.setObjectName("dangerButton")
        self.delete_question_button.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_TrashIcon))

        self.prev_button.clicked.connect(self.previous_question)
        self.next_button.clicked.connect(self.next_question)
        self.new_question_button.clicked.connect(self.add_question)
        self.delete_question_button.clicked.connect(self.delete_question)

        nav.addWidget(self.prev_button)
        nav.addWidget(self.question_counter, 1)
        nav.addWidget(self.next_button)
        nav.addSpacing(12)
        nav.addWidget(self.new_question_button)
        nav.addWidget(self.delete_question_button)
        left_layout.addLayout(nav)

        # Vertical layout: top = question + options, bottom = option details
        content_layout = QVBoxLayout()
        content_layout.setContentsMargins(0, 0, 0, 0)
        content_layout.setSpacing(8)
        left_layout.addLayout(content_layout, 1)

        vertical_splitter = QSplitter(Qt.Orientation.Vertical)
        vertical_splitter.setChildrenCollapsible(False)
        content_layout.addWidget(vertical_splitter, 1)

        # --- Top section: question text + options list ---
        top_widget = QWidget()
        top_widget.setSizePolicy(
            QSizePolicy.Policy.Expanding,
            QSizePolicy.Policy.Expanding,
        )
        top_layout = QVBoxLayout(top_widget)
        top_layout.setContentsMargins(0, 0, 0, 0)
        top_layout.setSpacing(8)

        question_group = QGroupBox("Soru Metni")
        question_layout = QVBoxLayout(question_group)
        question_layout.setContentsMargins(10, 14, 10, 10)
        question_layout.setSpacing(6)
        self.question_text = QTextEdit()
        self.question_text.setPlaceholderText("Soru metnini buraya yazin...")
        self.question_text.setMaximumHeight(110)
        self.question_text.textChanged.connect(self._on_question_text_changed)
        question_layout.addWidget(self.question_text)
        top_layout.addWidget(question_group)

        options_group = QGroupBox("Secenekler")
        options_group.setSizePolicy(
            QSizePolicy.Policy.Expanding,
            QSizePolicy.Policy.Expanding,
        )
        options_layout = QVBoxLayout(options_group)
        options_layout.setContentsMargins(10, 14, 10, 10) # bottom pading çalışmadı.
        options_layout.setSpacing(8)

        option_header = QHBoxLayout()
        option_header.addStretch()
        self.add_option_button = QPushButton(" Secenek ekle")
        self.add_option_button.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_FileDialogNewFolder))
        self.delete_option_button = QPushButton(" Secenegi sil")
        self.delete_option_button.setObjectName("dangerButton")
        self.delete_option_button.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_TrashIcon))
        self.add_option_button.clicked.connect(self.add_option)
        self.delete_option_button.clicked.connect(self.delete_option)
        option_header.addWidget(self.add_option_button)
        option_header.addWidget(self.delete_option_button)
        options_layout.addLayout(option_header)

        self.option_list = QListWidget()
        self.option_list.setObjectName("optionList")
        self.option_list.setMinimumHeight(120)
        self.option_list.setSizePolicy(
            QSizePolicy.Policy.Expanding,
            QSizePolicy.Policy.Expanding,
        )
        self.option_list.setSizeAdjustPolicy(
            QAbstractScrollArea.SizeAdjustPolicy.AdjustIgnored,
        )
        self.option_list.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAsNeeded)
        self.option_list.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.option_list.setSpacing(4)
        self.option_list.setEditTriggers(
            QAbstractItemView.EditTrigger.DoubleClicked
            | QAbstractItemView.EditTrigger.EditKeyPressed
        )
        self.option_list.currentRowChanged.connect(self._on_option_selected)
        self.option_list.itemChanged.connect(self._on_option_item_edited)
        options_layout.addWidget(self.option_list, 1)

        top_layout.addWidget(options_group, 1)
        vertical_splitter.addWidget(top_widget)


        # --- Bottom section: option detail / scoring ---
        detail = QGroupBox("Secenek Puanlama")
        detail.setSizePolicy(
            QSizePolicy.Policy.Expanding,
            QSizePolicy.Policy.Expanding,
        )
        detail_layout = QVBoxLayout(detail)
        detail_layout.setContentsMargins(10, 14, 10, 10)
        detail_layout.setSpacing(8)

        self.option_indicator = QLabel()
        self.option_indicator.setObjectName("optionIndicator")
        self.option_indicator.setWordWrap(True)
        detail_layout.addWidget(self.option_indicator)

        points_row = QHBoxLayout()
        points_row.addWidget(QLabel("Puan:"))
        self.points_input = QSpinBox()
        self.points_input.setRange(1, 99)
        self.points_input.valueChanged.connect(self._on_points_changed)
        points_row.addWidget(self.points_input)
        points_row.addStretch()
        detail_layout.addLayout(points_row)

        selectors_row = QHBoxLayout()
        selectors_row.setSpacing(10)
        self.score_selector = PerfumeSelector("Puan verilecek parfumler", self.perfumes)
        self.exclude_selector = PerfumeSelector("Elenecek parfumler", self.perfumes)
        selectors_row.addWidget(self.score_selector, 1)
        selectors_row.addWidget(self.exclude_selector, 1)
        detail_layout.addLayout(selectors_row)

        save_selection = QPushButton(" Bu secenek icin secimleri kaydet")
        save_selection.setObjectName("primaryButton")
        save_selection.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_DialogSaveButton))
        save_selection.clicked.connect(self._save_current_option_selectors)
        detail_layout.addWidget(save_selection)

        vertical_splitter.addWidget(detail)
        vertical_splitter.setStretchFactor(0, 3)
        vertical_splitter.setStretchFactor(1, 2)
        vertical_splitter.setSizes([430, 330])

        # ================= RIGHT PANEL =================
        right = QWidget()
        right_layout = QVBoxLayout(right)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_layout.setSpacing(8)
        splitter.addWidget(right)
        splitter.setStretchFactor(0, 4)
        splitter.setStretchFactor(1, 1)
        splitter.setSizes([1080, 300])

        validation_group = QGroupBox("Dogrulama Sonuclari")
        validation_layout = QVBoxLayout(validation_group)
        validation_layout.setContentsMargins(10, 14, 10, 10)
        self.validation_output = QTextEdit()
        self.validation_output.setObjectName("validationOutput")
        self.validation_output.setReadOnly(True)
        validation_layout.addWidget(self.validation_output)
        right_layout.addWidget(validation_group)

    def _load_defaults(self) -> None:
        if DEFAULT_SURVEY.exists() and DEFAULT_RULES.exists():
            self._load_from_paths(DEFAULT_SURVEY, DEFAULT_RULES)
        else:
            self.questions = [QuestionData(id=1, options=[OptionData(), OptionData()])]
            self.refresh_ui()

    def import_files(self) -> None:
        survey_name, _ = QFileDialog.getOpenFileName(
            self,
            "Survey JSON sec",
            str(DEFAULT_SURVEY.parent),
            "JSON files (*.json)",
        )
        if not survey_name:
            return

        rules_name, _ = QFileDialog.getOpenFileName(
            self,
            "Scoring rules JSON sec",
            str(DEFAULT_RULES.parent),
            "JSON files (*.json)",
        )
        if not rules_name:
            return

        try:
            self._load_from_paths(Path(survey_name), Path(rules_name))
        except Exception as exc:
            QMessageBox.critical(self, "Import hatasi", str(exc))

    def export_files(self) -> None:
        self._save_current_option_selectors()
        errors = self.validate()
        if errors:
            QMessageBox.warning(
                self,
                "Validation hatasi",
                "Export oncesi hatalar duzeltilmeli:\n\n" + "\n".join(errors[:12]),
            )
            self._show_messages(errors, "error")
            return

        output_dir = QFileDialog.getExistingDirectory(
            self,
            "Export klasoru sec",
            str(ROOT),
        )
        if not output_dir:
            return

        out = Path(output_dir)
        try:
            write_json(out / "survey_questions.json", self._build_survey_json())
            write_json(out / "scoring_rules.json", self._build_rules_json())
        except Exception as exc:
            QMessageBox.critical(self, "Export hatasi", str(exc))
            return

        self._show_messages([f"Export basarili: {out}"], "success")
        QMessageBox.information(
            self,
            "Export tamam",
            f"Dosyalar olusturuldu:\n{out / 'survey_questions.json'}\n{out / 'scoring_rules.json'}",
        )

    def _load_from_paths(self, survey_path: Path, rules_path: Path) -> None:
        survey_json = read_json(survey_path)
        rules_json = read_json(rules_path)
        questions = self._parse_survey(survey_json)
        self._apply_rules(questions, rules_json)
        self.questions = questions
        self.current_question_index = 0
        self.current_option_index = 0 if questions and questions[0].options else -1
        self.refresh_ui()
        self._show_messages([f"Import tamam: {len(questions)} soru yüklendi."], "success")

    def _parse_survey(self, data: dict) -> list[QuestionData]:
        items = data.get("perfume_survey")
        if not isinstance(items, list):
            raise ValueError("Survey JSON icinde 'perfume_survey' listesi bulunamadi.")

        questions: list[QuestionData] = []
        for item in items:
            translations = item.get("translations", {})
            tr = translations.get(LANGUAGE_CODE) or next(iter(translations.values()), {})
            options = [OptionData(text=str(text)) for text in tr.get("options", [])]
            questions.append(
                QuestionData(
                    id=int(item["id"]),
                    text=str(tr.get("question", "")),
                    options=options,
                )
            )
        return questions

    def _apply_rules(self, questions: list[QuestionData], data: dict) -> None:
        by_id = {question.id: question for question in questions}
        for rule in data.get("rules", []):
            question = by_id.get(int(rule.get("q", -1)))
            if question is None:
                continue
            option_index = int(rule.get("a", -1))
            if option_index < 0 or option_index >= len(question.options):
                continue

            option = question.options[option_index]
            perfumes = {int(value) for value in rule.get("perfumes", [])}
            rule_type = rule.get("type")
            if rule_type == "score":
                option.score_perfumes.update(perfumes)
                option.points = int(rule.get("pts", option.points))
            elif rule_type == "exclude":
                option.exclude_perfumes.update(perfumes)

    def _build_survey_json(self) -> dict:
        return {
            "perfume_survey": [
                {
                    "id": question.id,
                    "translations": {
                        LANGUAGE_CODE: {
                            "question": question.text,
                            "options": [option.text for option in question.options],
                        }
                    },
                }
                for question in self.questions
            ]
        }

    def _build_rules_json(self) -> dict:
        rules: list[dict] = []
        for question in self.questions:
            for option_index, option in enumerate(question.options):
                if option.score_perfumes:
                    rules.append(
                        {
                            "q": question.id,
                            "a": option_index,
                            "type": "score",
                            "pts": option.points,
                            "perfumes": sorted(option.score_perfumes),
                        }
                    )
                if option.exclude_perfumes:
                    rules.append(
                        {
                            "q": question.id,
                            "a": option_index,
                            "type": "exclude",
                            "perfumes": sorted(option.exclude_perfumes),
                        }
                    )
        return {"rules": rules}

    def validate(self) -> list[str]:
        self._save_current_option_selectors()
        errors: list[str] = []
        seen_ids: set[int] = set()
        perfume_ids = {pid for pid, _ in self.perfumes}

        if not self.questions:
            errors.append("En az bir soru olmali.")

        for number, question in enumerate(self.questions, start=1):
            label = f"Soru {number} (id={question.id})"
            if question.id in seen_ids:
                errors.append(f"{label}: soru id tekrar ediyor.")
            seen_ids.add(question.id)

            if not question.text.strip():
                errors.append(f"{label}: soru metni bos.")
            if len(question.options) < 2:
                errors.append(f"{label}: en az 2 secenek olmali.")

            for option_index, option in enumerate(question.options):
                option_label = f"{label}, secenek {option_index + 1}"
                if not option.text.strip():
                    errors.append(f"{option_label}: secenek metni bos.")
                invalid_score = option.score_perfumes - perfume_ids
                invalid_exclude = option.exclude_perfumes - perfume_ids
                if invalid_score:
                    errors.append(f"{option_label}: gecersiz puan parfum id: {sorted(invalid_score)}")
                if invalid_exclude:
                    errors.append(f"{option_label}: gecersiz eleme parfum id: {sorted(invalid_exclude)}")

        return errors

    def show_validation(self) -> None:
        errors = self.validate()
        if errors:
            self._show_messages(errors, "error")
            QMessageBox.warning(self, "Validation", f"{len(errors)} hata bulundu.")
        else:
            self._show_messages(["Validation basarili. Export icin hazir."], "success")
            QMessageBox.information(self, "Validation", "Her sey iyi gorunuyor.")

    def _show_messages(self, messages: list[str], level: str = "info") -> None:
        self.validation_output.setPlainText("\n".join(messages))
        palette = {
            "error": ("#fef2f2", "#fca5a5"),
            "success": ("#f0fdf4", "#86efac"),
            "info": ("#ffffff", "#d0d5dd"),
        }
        background, border = palette.get(level, palette["info"])
        self.validation_output.setStyleSheet(
            "QTextEdit#validationOutput {"
            f" background-color: {background};"
            f" border: 1px solid {border};"
            " border-radius: 6px;"
            " padding: 6px;"
            " font-family: Consolas, 'Courier New', monospace;"
            " font-size: 9pt;"
            "}"
        )

    def refresh_ui(self) -> None:
        self._loading = True
        try:
            has_questions = bool(self.questions)
            self.prev_button.setEnabled(has_questions and self.current_question_index > 0)
            self.next_button.setEnabled(
                has_questions and self.current_question_index < len(self.questions) - 1
            )
            self.delete_question_button.setEnabled(has_questions)
            self.add_option_button.setEnabled(has_questions)
            self.delete_option_button.setEnabled(has_questions and self.current_option_index >= 0)

            if not has_questions:
                self.question_counter.setText("Soru 0 / 0")
                self.question_text.clear()
                self.option_list.clear()
                self._set_option_detail_enabled(False)
                return

            question = self.questions[self.current_question_index]
            self.question_counter.setText(
                f"Soru {self.current_question_index + 1} / {len(self.questions)}  (id: {question.id})"
            )
            self.question_text.setPlainText(question.text)

            self.option_list.blockSignals(True)
            self.option_list.clear()
            for option in question.options:
                text = option.text.strip() or "(bos secenek)"
                item = QListWidgetItem(text)
                item.setFlags(item.flags() | Qt.ItemFlag.ItemIsEditable)
                self.option_list.addItem(item)
            self.option_list.blockSignals(False)

            if question.options:
                if self.current_option_index < 0:
                    self.current_option_index = 0
                self.current_option_index = min(self.current_option_index, len(question.options) - 1)
                self.option_list.setCurrentRow(self.current_option_index)
                self._load_option_detail(question.options[self.current_option_index])
                self._set_option_detail_enabled(True)
            else:
                self.current_option_index = -1
                self._set_option_detail_enabled(False)
        finally:
            self._loading = False

    def _set_option_detail_enabled(self, enabled: bool) -> None:
        self.option_indicator.setEnabled(enabled)
        self.points_input.setEnabled(enabled)
        self.score_selector.setEnabled(enabled)
        self.exclude_selector.setEnabled(enabled)
        if not enabled:
            self.option_indicator.setText("Secenek secili degil")

    def _update_option_indicator(self, option: OptionData) -> None:
        text = option.text.strip() or "(bos secenek)"
        self.option_indicator.setText(f"Duzenlenen secenek {self.current_option_index + 1}: {text}")

    def _load_option_detail(self, option: OptionData) -> None:
        self._update_option_indicator(option)
        self.points_input.setValue(option.points)
        self.score_selector.set_selected(option.score_perfumes)
        self.exclude_selector.set_selected(option.exclude_perfumes)

    def _current_question(self) -> QuestionData | None:
        if not self.questions:
            return None
        return self.questions[self.current_question_index]

    def _current_option(self) -> OptionData | None:
        question = self._current_question()
        if question is None:
            return None
        if self.current_option_index < 0 or self.current_option_index >= len(question.options):
            return None
        return question.options[self.current_option_index]

    def _save_current_option_selectors(self) -> None:
        option = self._current_option()
        if option is None:
            return
        option.score_perfumes = self.score_selector.selected()
        option.exclude_perfumes = self.exclude_selector.selected()
        option.points = int(self.points_input.value())

    def _on_question_text_changed(self) -> None:
        if self._loading:
            return
        question = self._current_question()
        if question is not None:
            question.text = self.question_text.toPlainText()

    def _on_points_changed(self, value: int) -> None:
        if self._loading:
            return
        option = self._current_option()
        if option is not None:
            option.points = value

    def _on_option_item_edited(self, item: QListWidgetItem) -> None:
        if self._loading:
            return
        question = self._current_question()
        if question is None:
            return
        row = self.option_list.row(item)
        if not (0 <= row < len(question.options)):
            return
        new_text = item.text()
        question.options[row].text = new_text
        if row == self.current_option_index:
            self._loading = True
            try:
                self._update_option_indicator(question.options[row])
            finally:
                self._loading = False

    def _on_option_selected(self, row: int) -> None:
        if self._loading:
            return
        self._save_current_option_selectors()
        self.current_option_index = row
        option = self._current_option()
        self._loading = True
        try:
            if option is None:
                self._set_option_detail_enabled(False)
                self.score_selector.set_selected(set())
                self.exclude_selector.set_selected(set())
            else:
                self._set_option_detail_enabled(True)
                self._load_option_detail(option)
        finally:
            self._loading = False

    def previous_question(self) -> None:
        if self.current_question_index <= 0:
            return
        self._save_current_option_selectors()
        self.current_question_index -= 1
        self.current_option_index = 0
        self.refresh_ui()

    def next_question(self) -> None:
        if self.current_question_index >= len(self.questions) - 1:
            return
        self._save_current_option_selectors()
        self.current_question_index += 1
        self.current_option_index = 0
        self.refresh_ui()

    def add_question(self) -> None:
        self._save_current_option_selectors()
        existing = {question.id for question in self.questions}
        next_id = 1
        while next_id in existing:
            next_id += 1
        self.questions.append(
            QuestionData(
                id=next_id,
                text="",
                options=[OptionData(), OptionData()],
            )
        )
        self.current_question_index = len(self.questions) - 1
        self.current_option_index = 0
        self.refresh_ui()

    def delete_question(self) -> None:
        if not self.questions:
            return
        result = QMessageBox.question(
            self,
            "Soruyu sil",
            "Bu soru silinsin mi?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        )
        if result != QMessageBox.StandardButton.Yes:
            return
        del self.questions[self.current_question_index]
        self.current_question_index = max(0, min(self.current_question_index, len(self.questions) - 1))
        self.current_option_index = 0
        self.refresh_ui()

    def add_option(self) -> None:
        question = self._current_question()
        if question is None:
            return
        self._save_current_option_selectors()
        question.options.append(OptionData())
        self.current_option_index = len(question.options) - 1
        self.refresh_ui()
        item = self.option_list.item(self.current_option_index)
        if item is not None:
            item.setText("")
            self.option_list.editItem(item)

    def delete_option(self) -> None:
        question = self._current_question()
        if question is None or self.current_option_index < 0:
            return
        del question.options[self.current_option_index]
        self.current_option_index = max(0, min(self.current_option_index, len(question.options) - 1))
        self.refresh_ui()

    def keyPressEvent(self, event) -> None:  # type: ignore[no-untyped-def]
        if event.key() == Qt.Key.Key_Left:
            self.previous_question()
        elif event.key() == Qt.Key.Key_Right:
            self.next_question()
        else:
            super().keyPressEvent(event)


def main() -> int:
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    app.setPalette(build_light_palette())
    app.setFont(QFont("Segoe UI", 10))
    app.setStyleSheet(STYLE_SHEET)
    window = ContentEditor()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
