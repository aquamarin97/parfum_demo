#!/usr/bin/env python3
"""
Parfüm Kiosk — PLC Simülatörü  (Register Haritası v1.1)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Kurulum:
    pip install pymodbus PyQt6

Kullanım:
    python plc_simulator.py

NOT: Flutter uygulaması 192.168.1.105:502 adresine bağlanır.
     Yerel test için assets/config/plc_registers.json içindeki
     "host" değerini "127.0.0.1" yapın ve port olarak 5020 seçin.
"""

import asyncio
import sys
import threading
import time
from collections import deque
from datetime import datetime

from PyQt6.QtCore import (
    Qt, QTimer, pyqtSignal, QObject, QThread
)
from PyQt6.QtGui import QFont, QColor, QPalette, QTextCursor
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout,
    QHBoxLayout, QGridLayout, QLabel, QPushButton,
    QComboBox, QSpinBox, QDoubleSpinBox, QGroupBox,
    QTextEdit, QFrame, QSplitter, QProgressBar,
    QRadioButton, QButtonGroup, QCheckBox, QSizePolicy,
)

import warnings as _warnings
_warnings.filterwarnings("ignore", category=DeprecationWarning)

try:
    from pymodbus.server import StartAsyncTcpServer
    from pymodbus.datastore import ModbusSequentialDataBlock, ModbusServerContext
    try:
        from pymodbus.simulator.simdevice import SimDevice
        from pymodbus.simulator.simdata import SimData, DataType
    except ImportError:
        SimDevice = SimData = DataType = None
    try:
        from pymodbus.datastore import ModbusDeviceContext as _DevCtx
    except ImportError:
        from pymodbus.datastore import ModbusSlaveContext as _DevCtx
except ImportError as exc:
    app = QApplication(sys.argv)
    from PyQt6.QtWidgets import QMessageBox
    QMessageBox.critical(None, "Eksik Kütüphane",
                         "pymodbus import edilemedi.\n\n"
                         "pip install pymodbus\n\n"
                         f"Ayrıntı: {exc}")
    sys.exit(1)


class _ValuesAccessor:
    """Thin list-like wrapper so PLCCore.r()/w() work with any pymodbus version."""

    def __init__(self, data: list):
        self._d = data

    def getValues(self, address, count=1):
        return [self._d[address + i] for i in range(count)]

    def setValues(self, address, values):
        for i, v in enumerate(values):
            self._d[address + i] = int(v)


def create_modbus_store(initial, device_ids=(0, 1)):
    """Return (accessor, server_context) for pymodbus 3.x and 3.13+."""
    if SimDevice is not None:
        data = list(initial)
        accessor = _ValuesAccessor(data)

        def make_device(dev_id):
            bit_data = [False]
            register_data = [
                SimData(address=0, count=len(data), values=data, datatype=DataType.REGISTERS)
            ]

            async def sync_registers(func_code, start_address, address, count, registers, values):
                if func_code in (3, 4):
                    registers[:] = data[:]
                elif func_code in (6, 16, 22, 23) and values is not None:
                    offset = address - start_address
                    data[offset:offset + count] = [int(v) for v in values]
                return None

            return SimDevice(
                id=int(dev_id),
                simdata=(
                    [SimData(address=0, count=1, values=bit_data, datatype=DataType.BITS)],
                    [SimData(address=0, count=1, values=bit_data, datatype=DataType.BITS)],
                    register_data,
                    register_data,
                ),
                use_bit_addressing=True,
                action=sync_registers,
            )

        return accessor, [make_device(dev_id) for dev_id in device_ids]

    # pymodbus 3.13+: address must be >= 1; data lives in block.simdata[0].values
    try:
        block = ModbusSequentialDataBlock(1, list(initial))
        if hasattr(block, "simdata") and block.simdata:
            accessor = _ValuesAccessor(block.simdata[0].values)
            simdevices = []
            for dev_id in device_ids:
                dev = _DevCtx(hr=block)
                if hasattr(dev, "simdevice"):
                    dev.simdevice.id = int(dev_id)
                    for sim_group in dev.simdevice.simdata:
                        for sim_data in sim_group:
                            if isinstance(sim_data.values, list):
                                sim_data.count = len(sim_data.values)
                    simdevices.append(dev.simdevice)
            if simdevices:
                return accessor, simdevices
    except Exception:
        pass

    # Older pymodbus: address=0 is valid, block has getValues/setValues directly
    block = ModbusSequentialDataBlock(0, list(initial))
    accessor = _ValuesAccessor(list(initial))  # shadow copy for r/w

    class _SyncBlock:
        """Forwards getValues/setValues to both the accessor and the pymodbus block."""
        def getValues(self, addr, cnt=1): return block.getValues(addr, cnt)
        def setValues(self, addr, vals):
            block.setValues(addr, vals)
            for i, v in enumerate(vals):
                accessor._d[addr + i] = int(v)

    devices = {int(dev_id): _DevCtx(hr=_SyncBlock()) for dev_id in device_ids}
    try:
        return accessor, ModbusServerContext(slaves=devices, single=False)
    except TypeError:
        return accessor, ModbusServerContext(devices=devices, single=False)

# ─── Register adresleri ───────────────────────────────────────────────────────
R_CMD_ACTION  = 100
R_CMD_SLOT    = 101
R_CMD_SEQ_ID  = 102
R_STATUS      = 200
R_LAST_SEQ    = 201
R_LAST_RESULT = 202
R_ACTIVE_SLOT = 203
R_PAY_STATUS  = 300
R_PAY_AMOUNT  = 301
R_PAY_ACK     = 302
R_SALE_DONE   = 303
R_PRESENCE    = 400
R_STOCK_BASE  = 401
R_ERR_CODE    = 500
R_ERR_SLOT    = 501
R_ERR_CODE2   = 502
R_ERR_SLOT2   = 503
R_ERR_ACK     = 504
R_PLC_HB      = 600
R_FLUTTER_HB  = 601

A_IDLE   = 0
A_TESTER = 1
A_ODEME  = 2
A_SATIS  = 3
A_RESET  = 4
A_ABORT  = 5

ACTION_NAMES = {
    A_TESTER: "TESTER_BAS",
    A_ODEME:  "ODEME_BASLAT",
    A_SATIS:  "SATIS_BAS",
    A_RESET:  "SISTEM_SIFIRLA",
    A_ABORT:  "OTURUM_IPTAL",
}

PAY_WAITING  = 0
PAY_OK       = 1
PAY_REJECTED = 2
PAY_TIMEOUT  = 3

STATUS_LABELS = {0: "BOŞTA", 1: "MEŞGUL", 2: "HATA"}
PAY_LABELS    = {0: "BEKLİYOR", 1: "ONAYLANDI", 2: "REDDEDİLDİ", 3: "TIMEOUT"}

# Slot 1–24 parfüm isimleri (1=erkek başlangıç, 13=kadın başlangıç)
PERFUMES = [
    "Amouage – Reasons (Essence de Parfum)",          # 1
    "Anomalia Paris – Umbra Oud EDP",                 # 2
    "Chanel – Bleu de Chanel L'Exclusif (Extrait)",   # 3
    "Dolce & Gabbana – Devotion for Men Parfum",      # 4
    "Maison Francis Kurkdjian – Amyris Homme",        # 5
    "Marc-Antoine Barrois – Aldebaran EDP",           # 6
    "Parfums de Marly – Haltane EDP",                 # 7
    "Prada – Paradigme EDP",                          # 8
    "Roja Parfums – Elysium Noir Pour Homme EDP",     # 9
    "The Merchant of Venice – Venetian Blue EDP",     # 10
    "Tom Ford – Oud Minerale EDP",                    # 11
    "Versace – Eros Flame EDP",                       # 12
    "Carolina Herrera – Good Girl Blush EDP",         # 13
    "Khloé Kardashian – XO Khloé EDP",                # 14
    "Lancôme – La Vie Est Belle EDP",                 # 15
    "Marc Jacobs – Daisy Wild EDP",                   # 16
    "Merit – Retrospect (L'Extrait)",                 # 17
    "Mugler – Alien Hypersense EDP",                  # 18
    "Parfums de Marly – Delina Exclusif",             # 19
    "Parfums de Marly – Valaya EDP",                  # 20
    "Prada – Paradoxe EDP",                           # 21
    "Valentino – Donna Born In Roma EDP",             # 22
    "YSL – Black Opium EDP",                          # 23
    "YSL – Libre Intense EDP",                        # 24
]

# ─── Renkler ──────────────────────────────────────────────────────────────────
C_BG        = "#1a1a2e"
C_SURFACE   = "#16213e"
C_CARD      = "#0f3460"
C_ACCENT    = "#e94560"
C_GREEN     = "#00b894"
C_YELLOW    = "#fdcb6e"
C_RED       = "#d63031"
C_TEXT      = "#dfe6e9"
C_MUTED     = "#636e72"
C_BORDER    = "#2d3561"
C_BLUE      = "#4a90e2"

LABEL_SIZE_OFFSET = 1


# ─── Signals (thread → GUI köprüsü) ──────────────────────────────────────────
class Signals(QObject):
    log_line        = pyqtSignal(str, str)   # (text, level)
    status_update   = pyqtSignal(dict)       # register snapshot
    tester_pending  = pyqtSignal()           # tüm testerlar ACK — manuel hazır butonu
    payment_pending = pyqtSignal(float)      # amount TL — manuel ödeme butonu
    sale_pending    = pyqtSignal(str)        # parfüm adı — manuel satış butonu
    server_started  = pyqtSignal(bool, str)


# ─── PLC Simülatör çekirdeği (asyncio thread'inde çalışır) ───────────────────
class PLCCore:
    def __init__(self, signals: Signals, config: dict):
        self.signals = signals
        self.config  = config

        self._tester_acked    = 0
        self._tester_event    = None    # asyncio.Event — manuel tester onayı
        self._payment_pending = False
        self._payment_event   = None    # asyncio.Event — manuel ödeme onayı
        self._manual_result   = PAY_OK
        self._sale_event      = None    # asyncio.Event — manuel satış onayı

        # İstatistikler
        self.total_sessions   = 0
        self.total_revenue_kr = 0
        self.total_sold       = 0

        initial = [0] * 700
        stocks = config.get("stocks", [5] * 24)
        for i in range(24):
            initial[R_STOCK_BASE + i] = max(0, int(stocks[i]))
        initial[R_PRESENCE] = 1

        slave_id = int(config.get("slave_id", 1))
        self._device_ids = tuple(dict.fromkeys((0, slave_id, 255)))
        self._block, self.context = create_modbus_store(initial, self._device_ids)

        self._loop   = None
        self._server = None
        self._tasks  = []

    # ─── Register erişimi ─────────────────────────────────────────────────────
    def r(self, address):
        return self._block.getValues(address, 1)[0]

    def w(self, address, value):
        self._block.setValues(address, [int(value)])

    def snapshot(self) -> dict:
        """GUI'nin periyodik okuması için register özetidir."""
        return {
            "status":      self.r(R_STATUS),
            "active_slot": self.r(R_ACTIVE_SLOT),
            "pay_status":  self.r(R_PAY_STATUS),
            "pay_amount":  self.r(R_PAY_AMOUNT),
            "sale_done":   self.r(R_SALE_DONE),
            "presence":    self.r(R_PRESENCE),
            "plc_hb":      self.r(R_PLC_HB),
            "flutter_hb":  self.r(R_FLUTTER_HB),
            "last_seq":    self.r(R_LAST_SEQ),
            "last_result": self.r(R_LAST_RESULT),
            "stock":       [self.r(R_STOCK_BASE + i) for i in range(24)],
            # İstatistikler
            "total_sessions":   self.total_sessions,
            "total_revenue_kr": self.total_revenue_kr,
            "total_sold":       self.total_sold,
        }

    def reset_statistics(self):
        self.total_sessions = 0
        self.total_revenue_kr = 0
        self.total_sold = 0

    # ─── Yardımcılar ──────────────────────────────────────────────────────────
    def _log(self, msg, level="INFO"):
        self.signals.log_line.emit(msg, level)

    def _ack(self, seq_id, result=0):
        self.w(R_LAST_SEQ,    seq_id)
        self.w(R_LAST_RESULT, result)
        lbl = "OK" if result == 0 else "HATA"
        self._log(f"✓ ACK  seq={seq_id}  result={lbl}", "ACK")

    def _reset_state(self):
        self.w(R_STATUS, 0)
        self.w(R_ACTIVE_SLOT, 0)
        self.w(R_PAY_STATUS, 0)
        self.w(R_PAY_AMOUNT, 0)
        self.w(R_PAY_ACK, 0)
        self.w(R_SALE_DONE, 0)
        self.w(R_ERR_CODE, 0)
        self.w(R_ERR_SLOT, 0)
        self._tester_acked    = 0
        self._payment_pending = False

    # ─── Handlers ─────────────────────────────────────────────────────────────
    async def _handle_tester(self, seq_id, slot):
        self.w(R_STATUS, 1)
        self.w(R_ACTIVE_SLOT, slot)
        self._ack(seq_id)
        self._tester_acked += 1
        tester_no = self._tester_acked
        name = PERFUMES[slot - 1] if 1 <= slot <= 24 else f"Slot {slot}"
        self._log(f"🧪 {tester_no}. Tester: {name} hazırlanıyor…")

        if self.config["tester_mode"] == "auto":
            await asyncio.sleep(self.config["tester_delay"])
            self._log(f"✅ {tester_no}. Tester: {name} hazır", "OK")

        if self._tester_acked >= 3:
            if self.config["tester_mode"] == "manual":
                self._tester_event = asyncio.Event()
                self.signals.tester_pending.emit()
                await self._tester_event.wait()
            self.w(R_STATUS, 0)
            self._log("── Tüm testerlar hazır  →  STATUS=IDLE", "OK")
            self._tester_acked = 0

    async def _handle_payment(self, seq_id, slot):
        self.w(R_STATUS, 1)
        self.w(R_ACTIVE_SLOT, slot)
        self.w(R_PAY_STATUS, PAY_WAITING)   # Önceki ödeme sonucunu sıfırla (ACK öncesi)
        self.w(R_PAY_ACK, 0)                # PAY_CONFIRMED_ACK sıfırla
        self._ack(seq_id)
        amount_tl = self.r(R_PAY_AMOUNT)   # register değeri TL cinsinden
        name = PERFUMES[slot - 1] if 1 <= slot <= 24 else f"Slot {slot}"
        self._log(f"💳 {name}  —  ödeme bekleniyor  ({amount_tl} TL)")

        if self.config["payment_mode"] == "manual":
            # GUI'ye sinyal gönder, event bekle
            self._payment_event   = asyncio.Event()
            self._payment_pending = True
            self.signals.payment_pending.emit(float(amount_tl))
            await self._payment_event.wait()
            status = self._manual_result
            self._payment_pending = False
        else:
            await asyncio.sleep(self.config["payment_delay"])
            outcome_map = {"ok": PAY_OK, "reject": PAY_REJECTED, "timeout": PAY_TIMEOUT}
            status = outcome_map[self.config["payment_outcome"]]

        self.w(R_PAY_STATUS, status)
        labels = {PAY_OK: "ONAYLANDI ✅", PAY_REJECTED: "REDDEDİLDİ ❌", PAY_TIMEOUT: "TIMEOUT ⏱"}
        level  = "OK" if status == PAY_OK else "WARN"
        self._log(f"💳 Ödeme sonucu: {labels[status]}", level)

        if status == PAY_OK:
            self.total_revenue_kr += amount_tl * 100   # geliri kuruş olarak sakla
            self.total_sessions   += 1

    async def _handle_sale(self, seq_id, slot):
        name = PERFUMES[slot - 1] if 1 <= slot <= 24 else f"Slot {slot}"
        self.w(R_STATUS, 1)
        self.w(R_ACTIVE_SLOT, slot)
        self._ack(seq_id)
        self._log(f"🍾 {name} dağıtılıyor…")

        if self.config["sale_mode"] == "manual":
            self._sale_event = asyncio.Event()
            self.signals.sale_pending.emit(name)
            await self._sale_event.wait()
        else:
            await asyncio.sleep(self.config["sale_delay"])
        self.w(R_SALE_DONE, 1)
        self.w(R_STATUS, 0)
        self.w(R_PAY_STATUS, 0)
        self.w(R_PAY_ACK, 0)
        idx = R_STOCK_BASE + slot - 1
        cur = self.r(idx)
        if cur > 0:
            self.w(idx, cur - 1)
        self.total_sold += 1
        self._log(f"✅ {name} dağıtıldı  →  SALE_COMPLETED=1", "OK")

    async def _handle_reset(self, seq_id):
        self._ack(seq_id)
        await asyncio.sleep(0.3)
        self._reset_state()
        self._log("🔄 Sistem sıfırlandı", "WARN")

    async def _handle_abort(self, seq_id):
        self._ack(seq_id)
        await asyncio.sleep(0.2)
        self._reset_state()
        self._log("⛔ Oturum iptal edildi", "WARN")

    # ─── Dispatcher ───────────────────────────────────────────────────────────
    async def _dispatch(self, seq_id, action, slot):
        action_name = ACTION_NAMES.get(action, f"BILINMEYEN({action})")
        perfume = f"  [{PERFUMES[slot - 1]}]" if 1 <= slot <= 24 else ""
        self._log(f"▶ seq={seq_id}  {action_name}  slot={slot}{perfume}")
        if   action == A_TESTER: await self._handle_tester(seq_id, slot)
        elif action == A_ODEME:  await self._handle_payment(seq_id, slot)
        elif action == A_SATIS:  await self._handle_sale(seq_id, slot)
        elif action == A_RESET:  await self._handle_reset(seq_id)
        elif action == A_ABORT:  await self._handle_abort(seq_id)
        else: self._log(f"⚠ Bilinmeyen action={action}", "WARN")

    # ─── Watcher & heartbeat ──────────────────────────────────────────────────
    async def _command_watcher(self):
        last_seq = -1
        while True:
            seq_id = self.r(R_CMD_SEQ_ID)
            if seq_id != last_seq:
                last_seq = seq_id
                action = self.r(R_CMD_ACTION)
                slot   = self.r(R_CMD_SLOT)
                if action != A_IDLE:
                    asyncio.create_task(self._dispatch(seq_id, action, slot))
            await asyncio.sleep(0.1)

    async def _heartbeat_loop(self):
        hb = 0
        while True:
            hb = (hb + 1) % 65536
            self.w(R_PLC_HB, hb)
            await asyncio.sleep(1)

    # ─── Manuel onay metotları (GUI thread'inden çağrılır) ───────────────────
    def resolve_tester(self):
        if self._tester_event and self._loop:
            self._loop.call_soon_threadsafe(self._tester_event.set)

    def resolve_payment(self, result: int):
        self._manual_result = result
        if self._payment_event and self._loop:
            self._loop.call_soon_threadsafe(self._payment_event.set)

    def resolve_sale(self):
        if self._sale_event and self._loop:
            self._loop.call_soon_threadsafe(self._sale_event.set)

    async def _shutdown(self):
        for event in (self._tester_event, self._payment_event, self._sale_event):
            if event and not event.is_set():
                event.set()
        for task in self._tasks:
            task.cancel()
        self._tasks.clear()
        if self._server:
            await self._server.shutdown()
            self._server = None

    def stop(self):
        if self._loop and self._loop.is_running():
            asyncio.run_coroutine_threadsafe(self._shutdown(), self._loop)

    # ─── Sunucu başlatma ──────────────────────────────────────────────────────
    async def run(self):
        self._loop = asyncio.get_running_loop()
        host = self.config["host"]
        port = self.config["port"]
        
        self._log(f"🚀 Sunucu başlatılıyor… {host}:{port}")
        
        # Command watcher ve heartbeat'i başlat
        self._tasks = [
            asyncio.create_task(self._command_watcher()),
            asyncio.create_task(self._heartbeat_loop()),
        ]
        
        try:
            from pymodbus.server import ModbusTcpServer
            
            # Framer kullanma - direkt server oluştur
            def trace_connect(connected):
                state = "connected" if connected else "disconnected"
                self._log(f"TCP client {state}", "OK" if connected else "WARN")

            server = ModbusTcpServer(
                context=self.context,
                address=(host, port),
                trace_connect=trace_connect,
            )
            self._server = server
            
            await server.serve_forever(background=True)
            devices = ", ".join(str(x) for x in self._device_ids)
            msg = f"{host}:{port}  unit-id: {devices}"
            self.signals.server_started.emit(True, msg)
            self._log(f"✅ Sunucu aktif: {msg}")
            
            # Sonsuza kadar bekle
            await server.serving
            
        except Exception as e:
            self._log(f"❌ Sunucu hatası: {type(e).__name__}: {e}", "ERR")
            self.signals.server_started.emit(False, str(e))
        finally:
            for task in self._tasks:
                task.cancel()
            self._tasks.clear()
            self._server = None

# ─── Asyncio thread ───────────────────────────────────────────────────────────
class ServerThread(QThread):
    def __init__(self, core: PLCCore):
        super().__init__()
        self.core = core

    def stop(self):
        self.core.stop()

    def run(self):
        asyncio.run(self.core.run())


# ─── Kart widget'ı ────────────────────────────────────────────────────────────
def make_card(title: str = "", color: str = C_CARD) -> QGroupBox:
    box = QGroupBox(title)
    box.setStyleSheet(f"""
        QGroupBox {{
            background: {color};
            border: 1px solid {C_BORDER};
            border-radius: 8px;
            margin-top: 18px;
            padding: 16px 8px 8px 8px;
            font-weight: bold;
            color: {C_TEXT};
        }}
        QGroupBox::title {{
            subcontrol-origin: margin;
            left: 10px;
            color: {C_MUTED};
            font-size: 14px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
        }}
    """)
    return box


def make_button(text: str, color: str = C_BLUE, width: int = 0) -> QPushButton:
    btn = QPushButton(text)
    if width:
        btn.setFixedWidth(width)
    btn.setStyleSheet(f"""
        QPushButton {{
            background: {color};
            color: white;
            border: none;
            border-radius: 6px;
            padding: 8px 16px;
            font-weight: bold;
            font-size: 14px;
        }}
        QPushButton:hover {{ background: {color}dd; }}
        QPushButton:pressed {{ background: {color}99; }}
        QPushButton:disabled {{ background: {C_MUTED}; color: #888; }}
    """)
    return btn


def make_label(text: str, size: int = 13, bold: bool = False, color: str = C_TEXT) -> QLabel:
    lbl = QLabel(text)
    font = QFont()
    font.setPointSize(size + LABEL_SIZE_OFFSET)
    font.setBold(bold)
    lbl.setFont(font)
    lbl.setStyleSheet(f"color: {color}; background: transparent;")
    return lbl


def status_pill(text: str, color: str) -> QLabel:
    lbl = QLabel(text)
    lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
    lbl.setStyleSheet(f"""
        QLabel {{
            background: {color}33;
            color: {color};
            border: 1px solid {color}66;
            border-radius: 4px;
            padding: 3px 10px;
            font-weight: bold;
            font-size: 13px;
        }}
    """)
    return lbl


# ─── Ana Pencere ──────────────────────────────────────────────────────────────
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Parfüm Kiosk — PLC Simülatörü")
        self.setLayoutDirection(Qt.LayoutDirection.LeftToRight)
        self.setMinimumSize(1100, 720)
        self._core   = None
        self._thread = None
        self._running = False
        self._log_lines = deque(maxlen=500)
        self._payment_pending = False
        self._stock_spins: list[QSpinBox] = []   # 24 spinbox, indeks = slot-1
        self._stock_rows:  list[QWidget]  = []   # satır widget'ları (highlight için)
        self._updating_stock = False             # spinbox sinyali döngüsünü önler

        self._build_ui()
        self._apply_global_style()

        # Periyodik snapshot timer
        self._snap_timer = QTimer()
        self._snap_timer.timeout.connect(self._refresh_snapshot)
        self._snap_timer.start(250)

    # ─── UI inşa ──────────────────────────────────────────────────────────────
    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setSpacing(8)
        root.setContentsMargins(12, 12, 12, 12)

        # ── Başlık çubuğu ──
        header = QHBoxLayout()
        title_lbl = make_label("PLC SİMÜLATÖR", 16, True, C_ACCENT)
        self._status_pill = status_pill("DURDURULDU", C_RED)
        self._status_pill.setFixedWidth(130)
        self._conn_lbl = make_label("", 11, color=C_MUTED)
        header.addWidget(title_lbl)
        header.addWidget(self._status_pill)
        header.addWidget(self._conn_lbl)
        header.addStretch()
        root.addLayout(header)

        # ── Ayraç ──
        sep = QFrame()
        sep.setFrameShape(QFrame.Shape.HLine)
        sep.setStyleSheet(f"color: {C_BORDER};")
        root.addWidget(sep)

        # ── Ana içerik (3 kolon) ──
        splitter = QSplitter(Qt.Orientation.Horizontal)
        splitter.setHandleWidth(6)
        splitter.setStyleSheet(f"QSplitter::handle {{ background: {C_BORDER}; }}")

        splitter.addWidget(self._build_left())
        splitter.addWidget(self._build_center())
        splitter.addWidget(self._build_right())
        splitter.setSizes([280, 420, 320])
        root.addWidget(splitter, 1)

        # ── Alt çubuk ──
        footer = QHBoxLayout()
        self._start_btn = make_button("▶  SUNUCU BAŞLAT", C_GREEN, 180)
        self._stop_btn  = make_button("■  DURDUR", C_RED, 130)
        self._stop_btn.setEnabled(False)
        self._clear_btn = make_button("🗑  Logu Temizle", C_MUTED, 130)

        self._start_btn.clicked.connect(self._start_server)
        self._stop_btn.clicked.connect(self._stop_server)
        self._clear_btn.clicked.connect(self._clear_log)

        footer.addWidget(self._start_btn)
        footer.addWidget(self._stop_btn)
        footer.addStretch()
        footer.addWidget(self._clear_btn)
        root.addLayout(footer)

    def _build_left(self) -> QWidget:
        """Bağlantı + Ödeme ayarları."""
        w = QWidget()
        lay = QVBoxLayout(w)
        lay.setSpacing(10)
        lay.setContentsMargins(0, 0, 0, 0)

        # ── Bağlantı ──
        conn_card = make_card("BAĞLANTI AYARLARI")
        cg = QVBoxLayout(conn_card)

        h_host = QHBoxLayout()
        h_host.addWidget(make_label("Host:", 12))
        self._host_combo = QComboBox()
        self._host_combo.addItems(["0.0.0.0", "127.0.0.1", "192.168.1.105"])
        self._host_combo.setEditable(True)
        h_host.addWidget(self._host_combo, 1)
        cg.addLayout(h_host)

        h_port = QHBoxLayout()
        h_port.addWidget(make_label("Port:", 12))
        self._port_spin = QSpinBox()
        self._port_spin.setRange(1, 65535)
        self._port_spin.setValue(5020)
        h_port.addWidget(self._port_spin)
        cg.addLayout(h_port)

        lay.addWidget(conn_card)

        # ── Ödeme modu ──
        pay_card = make_card("ÖDEME MODU")
        pg = QVBoxLayout(pay_card)

        self._pay_manual_rb  = QRadioButton("Manuel (Buton ile)")
        self._pay_auto_rb    = QRadioButton("Otomatik (Süreli)")
        self._pay_manual_rb.setChecked(True)
        self._pay_manual_rb.setStyleSheet(f"color: {C_TEXT};")
        self._pay_auto_rb.setStyleSheet(f"color: {C_TEXT};")

        pay_grp = QButtonGroup(self)
        pay_grp.addButton(self._pay_manual_rb)
        pay_grp.addButton(self._pay_auto_rb)
        self._pay_manual_rb.toggled.connect(self._on_pay_mode_changed)

        pg.addWidget(self._pay_manual_rb)
        pg.addWidget(self._pay_auto_rb)

        # Otomatik ayarlar
        self._auto_frame = QWidget()
        af = QVBoxLayout(self._auto_frame)
        af.setContentsMargins(8, 0, 0, 0)
        af.setSpacing(4)

        h_out = QHBoxLayout()
        h_out.addWidget(make_label("Sonuç:", 10))
        self._pay_outcome_combo = QComboBox()
        self._pay_outcome_combo.addItems(["ok — Onaylı", "reject — Reddedildi", "timeout — Timeout"])
        h_out.addWidget(self._pay_outcome_combo, 1)
        af.addLayout(h_out)

        h_pdel = QHBoxLayout()
        h_pdel.addWidget(make_label("Gecikme (s):", 12))
        self._pay_delay_spin = QDoubleSpinBox()
        self._pay_delay_spin.setRange(0.5, 30)
        self._pay_delay_spin.setValue(4)
        self._pay_delay_spin.setSingleStep(0.5)
        h_pdel.addWidget(self._pay_delay_spin)
        af.addLayout(h_pdel)

        pg.addWidget(self._auto_frame)
        self._auto_frame.setEnabled(False)

        lay.addWidget(pay_card)

        # ── Tester modu ──
        tester_card = make_card("TESTER MODU")
        tg = QVBoxLayout(tester_card)

        self._tester_manual_rb = QRadioButton("Manuel (Buton ile)")
        self._tester_auto_rb   = QRadioButton("Otomatik (Süreli)")
        self._tester_auto_rb.setChecked(True)
        for rb in (self._tester_manual_rb, self._tester_auto_rb):
            rb.setStyleSheet(f"color: {C_TEXT};")
        tester_grp = QButtonGroup(self)
        tester_grp.addButton(self._tester_manual_rb)
        tester_grp.addButton(self._tester_auto_rb)
        self._tester_auto_rb.toggled.connect(self._on_tester_mode_changed)
        tg.addWidget(self._tester_manual_rb)
        tg.addWidget(self._tester_auto_rb)

        self._tester_auto_frame = QWidget()
        taf = QHBoxLayout(self._tester_auto_frame)
        taf.setContentsMargins(8, 0, 0, 0)
        taf.addWidget(make_label("Gecikme (s):", 10))
        self._tester_delay_spin = QDoubleSpinBox()
        self._tester_delay_spin.setRange(0.1, 120)
        self._tester_delay_spin.setValue(3)
        self._tester_delay_spin.setSingleStep(1)
        taf.addWidget(self._tester_delay_spin)
        tg.addWidget(self._tester_auto_frame)

        lay.addWidget(tester_card)

        # ── Satış modu ──
        sale_card = make_card("SATIŞ MODU")
        sg2 = QVBoxLayout(sale_card)

        self._sale_manual_rb = QRadioButton("Manuel (Buton ile)")
        self._sale_auto_rb   = QRadioButton("Otomatik (Süreli)")
        self._sale_auto_rb.setChecked(True)
        for rb in (self._sale_manual_rb, self._sale_auto_rb):
            rb.setStyleSheet(f"color: {C_TEXT};")
        sale_grp = QButtonGroup(self)
        sale_grp.addButton(self._sale_manual_rb)
        sale_grp.addButton(self._sale_auto_rb)
        self._sale_auto_rb.toggled.connect(self._on_sale_mode_changed)
        sg2.addWidget(self._sale_manual_rb)
        sg2.addWidget(self._sale_auto_rb)

        self._sale_auto_frame = QWidget()
        saf = QHBoxLayout(self._sale_auto_frame)
        saf.setContentsMargins(8, 0, 0, 0)
        saf.addWidget(make_label("Gecikme (s):", 12))
        self._sale_delay_spin = QDoubleSpinBox()
        self._sale_delay_spin.setRange(0.1, 120)
        self._sale_delay_spin.setValue(6)
        self._sale_delay_spin.setSingleStep(1)
        saf.addWidget(self._sale_delay_spin)
        sg2.addWidget(self._sale_auto_frame)

        lay.addWidget(sale_card)
        lay.addStretch()
        return w

    def _build_center(self) -> QWidget:
        """Durum paneli + Manuel ödeme + Log."""
        w = QWidget()
        lay = QVBoxLayout(w)
        lay.setSpacing(10)
        lay.setContentsMargins(0, 0, 0, 0)

        # ── Durum kartları ──
        st_card = make_card("CANLI DURUM")
        sg = QGridLayout(st_card)
        sg.setSpacing(8)

        # PLC Status
        sg.addWidget(make_label("PLC Durum", 11, color=C_MUTED), 0, 0)
        self._plc_status_lbl = status_pill("BOŞTA", C_GREEN)
        sg.addWidget(self._plc_status_lbl, 0, 1)

        # Ödeme Status
        sg.addWidget(make_label("Ödeme", 11, color=C_MUTED), 0, 2)
        self._pay_status_lbl = status_pill("BEKLİYOR", C_MUTED)
        sg.addWidget(self._pay_status_lbl, 0, 3)

        # Aktif slot
        sg.addWidget(make_label("Aktif Slot", 11, color=C_MUTED), 1, 0)
        self._active_slot_lbl = make_label("—", 14, True)
        sg.addWidget(self._active_slot_lbl, 1, 1)

        # Heartbeat
        sg.addWidget(make_label("PLC HB", 11, color=C_MUTED), 1, 2)
        self._hb_lbl = make_label("0", 13, color=C_MUTED)
        sg.addWidget(self._hb_lbl, 1, 3)

        lay.addWidget(st_card)

        # ── Manuel Tester Paneli ──
        self._tester_panel_card = make_card("TESTER HAZIRLIĞI BEKLENİYOR", C_CARD)
        tp = QVBoxLayout(self._tester_panel_card)
        tp.addWidget(make_label("3 tester ACK'landı — fiziksel hazır mı?", 12, color=C_YELLOW))
        self._tester_ready_btn = make_button("✅  TESTERLAR HAZIR", C_GREEN)
        self._tester_ready_btn.setEnabled(False)
        self._tester_ready_btn.clicked.connect(self._resolve_tester)
        tp.addWidget(self._tester_ready_btn)
        self._tester_panel_card.setVisible(False)
        lay.addWidget(self._tester_panel_card)

        # ── Manuel Ödeme Paneli ──
        self._pay_panel_card = make_card("ÖDEME ONAYI BEKLENİYOR", C_CARD)
        pp = QVBoxLayout(self._pay_panel_card)

        self._pay_amount_lbl = make_label("0.00 TL", 22, True, C_YELLOW)
        self._pay_amount_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        pp.addWidget(self._pay_amount_lbl)

        pay_btns = QHBoxLayout()
        self._approve_btn = make_button("✅  ONAYLA", C_GREEN)
        self._reject_btn  = make_button("❌  REDDET", C_RED)
        self._timeout_btn = make_button("⏱  TIMEOUT", C_YELLOW)
        for btn in (self._approve_btn, self._reject_btn, self._timeout_btn):
            btn.setEnabled(False)
            pay_btns.addWidget(btn)
        self._approve_btn.clicked.connect(lambda: self._resolve_payment(PAY_OK))
        self._reject_btn.clicked.connect(lambda: self._resolve_payment(PAY_REJECTED))
        self._timeout_btn.clicked.connect(lambda: self._resolve_payment(PAY_TIMEOUT))

        pp.addLayout(pay_btns)
        self._pay_panel_card.setVisible(False)
        lay.addWidget(self._pay_panel_card)

        # ── Manuel Satış Paneli ──
        self._sale_panel_card = make_card("SATIŞ (DAĞITIM) BEKLENİYOR", C_CARD)
        sp2 = QVBoxLayout(self._sale_panel_card)
        self._sale_name_lbl = make_label("", 13, True, C_YELLOW)
        self._sale_name_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        sp2.addWidget(self._sale_name_lbl)
        self._sale_done_btn = make_button("✅  SATIŞ TAMAMLANDI", C_GREEN)
        self._sale_done_btn.setEnabled(False)
        self._sale_done_btn.clicked.connect(self._resolve_sale)
        sp2.addWidget(self._sale_done_btn)
        self._sale_panel_card.setVisible(False)
        lay.addWidget(self._sale_panel_card)

        # ── Log ──
        log_card = make_card("OLAY GÜNLÜĞÜ")
        lg = QVBoxLayout(log_card)
        self._log_view = QTextEdit()
        self._log_view.setLayoutDirection(Qt.LayoutDirection.LeftToRight)
        self._log_view.setReadOnly(True)
        self._log_view.verticalScrollBar().setInvertedAppearance(False)
        self._log_view.verticalScrollBar().setInvertedControls(False)
        self._log_view.setFont(QFont("Consolas, Courier New, monospace", 11))
        self._log_view.setStyleSheet(f"""
            QTextEdit {{
                background: #0a0a14;
                color: {C_TEXT};
                border: none;
                border-radius: 4px;
            }}
        """)
        lg.addWidget(self._log_view)
        lay.addWidget(log_card, 1)

        return w

    def _build_right(self) -> QWidget:
        """İstatistikler + Stok paneli (erkek/kadın ayrımı)."""
        w = QWidget()
        lay = QVBoxLayout(w)
        lay.setSpacing(10)
        lay.setContentsMargins(0, 0, 0, 0)

        # ── İstatistikler ──
        stat_card = make_card("İSTATİSTİKLER")
        sg = QGridLayout(stat_card)
        sg.setSpacing(8)

        def stat_block(label, value_lbl, row):
            sg.addWidget(make_label(label, 11, color=C_MUTED), row, 0)
            value_lbl.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
            sg.addWidget(value_lbl, row, 1)

        self._sessions_lbl = make_label("0", 18, True, C_BLUE)
        self._revenue_lbl  = make_label("0.00 ₺", 18, True, C_GREEN)
        self._sold_lbl     = make_label("0", 18, True, C_YELLOW)

        stat_block("Toplam İşlem", self._sessions_lbl, 0)
        stat_block("Toplam Gelir", self._revenue_lbl,  1)
        stat_block("Satılan Adet", self._sold_lbl,     2)

        self._reset_stats_btn = make_button("Sıfırla", C_MUTED)
        self._reset_stats_btn.clicked.connect(self._reset_statistics)
        sg.addWidget(self._reset_stats_btn, 3, 0, 1, 2)

        lay.addWidget(stat_card)

        # ── Stok paneli (kaydırılabilir) ──
        from PyQt6.QtWidgets import QScrollArea
        scroll = QScrollArea()
        scroll.setLayoutDirection(Qt.LayoutDirection.LeftToRight)
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.Shape.NoFrame)
        scroll.setStyleSheet(f"QScrollArea {{ background: transparent; }}")
        scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        scroll.verticalScrollBar().setInvertedAppearance(False)
        scroll.verticalScrollBar().setInvertedControls(False)

        scroll_content = QWidget()
        scroll_content.setStyleSheet("background: transparent;")
        scroll_lay = QVBoxLayout(scroll_content)
        scroll_lay.setSpacing(8)
        scroll_lay.setContentsMargins(0, 0, 4, 0)

        self._stock_spins = []
        self._stock_rows  = []

        for section_title, slot_range, pill_color in [
            ("♂  ERKEK  —  Slot 1–12",   range(0, 12),  C_BLUE),
            ("♀  KADIN  —  Slot 13–24",  range(12, 24), "#e84393"),
        ]:
            card = make_card(section_title)
            grid = QGridLayout(card)
            grid.setSpacing(3)
            grid.setContentsMargins(6, 16, 6, 8)

            # Sütun başlıkları
            for col, (txt, _) in enumerate([("#", 0), ("Parfüm", 1), ("Stok", 0)]):
                hdr = make_label(txt, 10, color=C_MUTED)
                hdr.setAlignment(Qt.AlignmentFlag.AlignCenter)
                grid.addWidget(hdr, 0, col)
            grid.setColumnStretch(1, 1)

            for local_i, global_i in enumerate(slot_range):
                slot_no = global_i + 1
                row_w   = QWidget()
                row_w.setObjectName(f"slot_row_{slot_no}")
                row_lay = QHBoxLayout(row_w)
                row_lay.setContentsMargins(2, 1, 2, 1)
                row_lay.setSpacing(6)

                # Slot numarası pill
                no_lbl = QLabel(str(slot_no))
                no_lbl.setFixedSize(24, 22)
                no_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
                no_lbl.setStyleSheet(f"""
                    QLabel {{
                        background: {pill_color}33;
                        color: {pill_color};
                        border: 1px solid {pill_color}55;
                        border-radius: 3px;
                        font-size: 11px;
                        font-weight: bold;
                    }}
                """)

                # Parfüm adı
                name = PERFUMES[global_i]
                name_lbl = QLabel(name)
                name_lbl.setToolTip(name)
                name_lbl.setStyleSheet(f"color: {C_TEXT}; font-size: 12px; background: transparent;")
                name_lbl.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Preferred)

                # Stok spinbox
                spin = QSpinBox()
                spin.setRange(0, 20)
                spin.setValue(5)
                spin.setFixedWidth(52)
                spin.setStyleSheet(f"""
                    QSpinBox {{
                        background: {C_SURFACE};
                        color: {C_TEXT};
                        border: 1px solid {C_BORDER};
                        border-radius: 3px;
                        padding: 2px 4px;
                        font-size: 12px;
                    }}
                """)
                spin.valueChanged.connect(
                    lambda val, idx=global_i: self._on_stock_changed(idx, val)
                )

                row_lay.addWidget(no_lbl)
                row_lay.addWidget(name_lbl, 1)
                row_lay.addWidget(spin)

                grid.addWidget(row_w, local_i + 1, 0, 1, 3)

                self._stock_spins.append(spin)
                self._stock_rows.append(row_w)

            scroll_lay.addWidget(card)

        scroll.setWidget(scroll_content)
        lay.addWidget(scroll, 1)

        # ── Varlık sensörü ──
        pres_card = make_card("SENSÖRLER")
        pl = QHBoxLayout(pres_card)
        pl.addWidget(make_label("Müşteri Varlık:", 12))
        self._presence_lbl = status_pill("AÇIK", C_GREEN)
        pl.addWidget(self._presence_lbl)
        pl.addStretch()
        self._presence_btn = make_button("Değiştir", C_MUTED)
        self._presence_btn.setEnabled(False)
        self._presence_btn.clicked.connect(self._toggle_presence)
        pl.addWidget(self._presence_btn)
        lay.addWidget(pres_card)

        return w

    # ─── Stok spinbox değişimi (canlı override) ──────────────────────────────
    def _on_stock_changed(self, slot_idx: int, value: int):
        if self._core and self._running and not self._updating_stock:
            self._core.w(R_STOCK_BASE + slot_idx, value)

    def _apply_global_style(self):
        self.setStyleSheet(f"""
            QMainWindow, QWidget {{
                background: {C_BG};
                color: {C_TEXT};
                font-family: 'Segoe UI', 'Inter', sans-serif;
            }}
            QComboBox, QSpinBox, QDoubleSpinBox {{
                background: {C_SURFACE};
                color: {C_TEXT};
                border: 1px solid {C_BORDER};
                border-radius: 4px;
                padding: 4px 8px;
                min-height: 26px;
                font-size: 13px;
            }}
            QRadioButton {{
                font-size: 13px;
            }}
            QComboBox::drop-down {{ border: none; }}
            QComboBox QAbstractItemView {{
                background: {C_SURFACE};
                color: {C_TEXT};
                selection-background-color: {C_CARD};
            }}
            QSplitter::handle {{ background: {C_BORDER}; }}
            QScrollBar:vertical {{
                background: {C_SURFACE};
                width: 10px;
                margin: 0;
                border-radius: 4px;
            }}
            QScrollBar::handle:vertical {{
                background: {C_BORDER};
                border-radius: 4px;
                min-height: 20px;
            }}
            QScrollBar::handle:vertical:hover {{
                background: {C_BLUE};
            }}
            QScrollBar::add-line:vertical,
            QScrollBar::sub-line:vertical {{
                height: 0;
                border: none;
                background: none;
            }}
            QScrollBar::add-page:vertical,
            QScrollBar::sub-page:vertical {{
                background: transparent;
            }}
            QScrollBar:horizontal {{
                background: {C_SURFACE};
                height: 10px;
                margin: 0;
                border-radius: 4px;
            }}
            QScrollBar::handle:horizontal {{
                background: {C_BORDER};
                border-radius: 4px;
                min-width: 20px;
            }}
            QScrollBar::add-line:horizontal,
            QScrollBar::sub-line:horizontal {{
                width: 0;
                border: none;
                background: none;
            }}
            QScrollBar::add-page:horizontal,
            QScrollBar::sub-page:horizontal {{
                background: transparent;
            }}
        """)

    # ─── Mod değişim callbackleri ─────────────────────────────────────────────
    def _on_tester_mode_changed(self, _):
        self._tester_auto_frame.setEnabled(self._tester_auto_rb.isChecked())

    def _on_pay_mode_changed(self, _):
        self._auto_frame.setEnabled(self._pay_auto_rb.isChecked())

    def _on_sale_mode_changed(self, _):
        self._sale_auto_frame.setEnabled(self._sale_auto_rb.isChecked())

    # ─── Sunucu başlat / durdur ───────────────────────────────────────────────
    def _build_config(self) -> dict:
        outcome_raw = self._pay_outcome_combo.currentText().split(" — ")[0]
        return {
            "host":            self._host_combo.currentText().strip(),
            "port":            self._port_spin.value(),
            "slave_id":        1,
            "tester_mode":     "manual" if self._tester_manual_rb.isChecked() else "auto",
            "tester_delay":    self._tester_delay_spin.value(),
            "payment_mode":    "manual" if self._pay_manual_rb.isChecked() else "auto",
            "payment_outcome": outcome_raw,
            "payment_delay":   self._pay_delay_spin.value(),
            "sale_mode":       "manual" if self._sale_manual_rb.isChecked() else "auto",
            "sale_delay":      self._sale_delay_spin.value(),
            "stocks":          [s.value() for s in self._stock_spins],
        }

    def _start_server(self):
        if self._running:
            return
        config = self._build_config()
        signals = Signals()
        signals.log_line.connect(self._on_log_line)
        signals.status_update.connect(self._on_status_update)
        signals.tester_pending.connect(self._on_tester_pending)
        signals.payment_pending.connect(self._on_payment_pending)
        signals.sale_pending.connect(self._on_sale_pending)
        signals.server_started.connect(self._on_server_started)

        self._core   = PLCCore(signals, config)
        self._thread = ServerThread(self._core)
        self._thread.start()

        self._start_btn.setEnabled(False)
        self._stop_btn.setEnabled(True)
        self._presence_btn.setEnabled(True)
        self._set_config_widgets_enabled(False)

    def _stop_server(self):
        if self._thread:
            self._thread.stop()
            if not self._thread.wait(2000):
                self._on_log_line("Sunucu nazikçe kapanmadı; thread sonlandırılıyor.", "WARN")
                self._thread.terminate()
                self._thread.wait(1000)
            self._thread = None
        self._core    = None
        self._running = False
        self._status_pill.setText("DURDURULDU")
        self._status_pill.setStyleSheet(status_pill("", C_RED).styleSheet())
        self._start_btn.setEnabled(True)
        self._stop_btn.setEnabled(False)
        self._presence_btn.setEnabled(False)
        self._set_config_widgets_enabled(True)
        self._tester_panel_card.setVisible(False)
        self._pay_panel_card.setVisible(False)
        self._sale_panel_card.setVisible(False)
        self._conn_lbl.setText("")
        self._on_log_line("■ Sunucu durduruldu.", "WARN")

    def _set_config_widgets_enabled(self, enabled: bool):
        for w in (self._host_combo, self._port_spin,
                  self._tester_manual_rb, self._tester_auto_rb, self._tester_delay_spin,
                  self._pay_manual_rb, self._pay_auto_rb,
                  self._pay_outcome_combo, self._pay_delay_spin,
                  self._sale_manual_rb, self._sale_auto_rb, self._sale_delay_spin):
            w.setEnabled(enabled)

    # ─── Signal slot'ları ─────────────────────────────────────────────────────
    def _on_server_started(self, ok: bool, msg: str):
        if ok:
            self._running = True
            self._status_pill.setText("ÇALIŞIYOR")
            self._status_pill.setStyleSheet(status_pill("", C_GREEN).styleSheet())
            self._conn_lbl.setText(f"  {msg}")
            self._on_log_line(f"▶ Sunucu aktif: {msg}", "OK")
        else:
            self._on_log_line(f"⚠ Sunucu başlatılamadı: {msg}", "ERR")
            self._stop_server()

    def _on_log_line(self, text: str, level: str = "INFO"):
        ts = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        colors = {
            "INFO": C_TEXT,
            "OK":   C_GREEN,
            "WARN": C_YELLOW,
            "ERR":  C_RED,
            "ACK":  C_BLUE,
        }
        color = colors.get(level, C_TEXT)
        html  = (
            f'<span style="color:{C_MUTED};">[{ts}]</span> '
            f'<span style="color:{color};">{text}</span>'
        )
        self._log_view.append(html)
        self._log_view.moveCursor(QTextCursor.MoveOperation.End)

    def _on_status_update(self, snap: dict):
        # PLC durum pill
        st = snap["status"]
        sc = {0: (C_GREEN, "BOŞTA"), 1: (C_YELLOW, "MEŞGUL"), 2: (C_RED, "HATA")}
        col, lbl = sc.get(st, (C_MUTED, "?"))
        self._plc_status_lbl.setText(lbl)
        self._plc_status_lbl.setStyleSheet(status_pill("", col).styleSheet())

        # Ödeme durum pill
        ps = snap["pay_status"]
        pc = {0: (C_MUTED, "BEKLİYOR"), 1: (C_GREEN, "ONAYLANDI"),
              2: (C_RED, "REDDEDİLDİ"), 3: (C_YELLOW, "TIMEOUT")}
        col2, lbl2 = pc.get(ps, (C_MUTED, "?"))
        self._pay_status_lbl.setText(lbl2)
        self._pay_status_lbl.setStyleSheet(status_pill("", col2).styleSheet())

        # Slot
        asl = snap["active_slot"]
        self._active_slot_lbl.setText(str(asl) if asl else "—")

        # Heartbeat
        self._hb_lbl.setText(str(snap["plc_hb"]))

        # Stok spinboxları ve satır vurgulama
        self._updating_stock = True
        for i, (spin, row_w) in enumerate(zip(self._stock_spins, self._stock_rows)):
            val    = snap["stock"][i]
            active = (asl == i + 1)
            if spin.value() != val:
                spin.blockSignals(True)
                spin.setValue(val)
                spin.blockSignals(False)
            # Satır rengi: aktif=vurgu, stok=0=soluk, normal=saydam
            if active:
                bg = f"{C_ACCENT}33"
                border = f"1px solid {C_ACCENT}88"
            elif val == 0:
                bg = f"{C_RED}18"
                border = f"1px solid {C_RED}33"
            else:
                bg = "transparent"
                border = "none"
            row_w.setStyleSheet(
                f"QWidget#slot_row_{i+1} {{ background: {bg}; border-radius: 3px; border: {border}; }}"
            )
        self._updating_stock = False

        # Varlık
        pres = snap["presence"]
        self._presence_lbl.setText("AÇIK" if pres else "KAPALI")
        self._presence_lbl.setStyleSheet(
            status_pill("", C_GREEN if pres else C_RED).styleSheet()
        )

        # İstatistikler
        self._sessions_lbl.setText(str(snap["total_sessions"]))
        rev = snap["total_revenue_kr"] / 100
        self._revenue_lbl.setText(f"{rev:,.2f} ₺")
        self._sold_lbl.setText(str(snap["total_sold"]))

    def _on_payment_pending(self, amount_tl: float):
        self._pay_amount_lbl.setText(f"{amount_tl:.2f} TL")
        for btn in (self._approve_btn, self._reject_btn, self._timeout_btn):
            btn.setEnabled(True)
        self._pay_panel_card.setVisible(True)
        self._payment_pending = True
        self._on_log_line(f"⏳ Ödeme onayı bekleniyor: {amount_tl:.2f} TL", "WARN")

    def _on_tester_pending(self):
        self._tester_ready_btn.setEnabled(True)
        self._tester_panel_card.setVisible(True)
        self._on_log_line("⏳ Tester hazırlığı bekleniyor — butona basın", "WARN")

    def _resolve_tester(self):
        if self._core:
            self._core.resolve_tester()
        self._tester_ready_btn.setEnabled(False)
        self._tester_panel_card.setVisible(False)

    def _on_sale_pending(self, name: str):
        self._sale_name_lbl.setText(name)
        self._sale_done_btn.setEnabled(True)
        self._sale_panel_card.setVisible(True)
        self._on_log_line(f"⏳ Satış bekleniyor: {name}", "WARN")

    def _resolve_sale(self):
        if self._core:
            self._core.resolve_sale()
        self._sale_done_btn.setEnabled(False)
        self._sale_panel_card.setVisible(False)

    def _resolve_payment(self, result: int):
        if self._core and self._payment_pending:
            self._core.resolve_payment(result)
            self._payment_pending = False
            for btn in (self._approve_btn, self._reject_btn, self._timeout_btn):
                btn.setEnabled(False)
            self._pay_panel_card.setVisible(False)

    # ─── Periyodik snapshot ───────────────────────────────────────────────────
    def _refresh_snapshot(self):
        if self._core and self._running:
            snap = self._core.snapshot()
            self._on_status_update(snap)

    # ─── Varlık sensörü toggle ────────────────────────────────────────────────
    def _toggle_presence(self):
        if self._core:
            cur = self._core.r(R_PRESENCE)
            self._core.w(R_PRESENCE, 0 if cur else 1)

    # ─── Log temizle ──────────────────────────────────────────────────────────
    def _clear_log(self):
        self._log_view.clear()

    def _reset_statistics(self):
        if self._core:
            self._core.reset_statistics()
        self._sessions_lbl.setText("0")
        self._revenue_lbl.setText("0.00 TL")
        self._sold_lbl.setText("0")
        self._on_log_line("İstatistikler sıfırlandı.", "WARN")

    # ─── Kapat ────────────────────────────────────────────────────────────────
    def closeEvent(self, event):
        self._stop_server()
        event.accept()


# ─── Main ─────────────────────────────────────────────────────────────────────
def main():
    app = QApplication(sys.argv)
    app.setApplicationName("PLC Simülatör")

    # PyQt6/Qt6 newer releases enable high-DPI pixmaps by default.
    high_dpi_pixmaps = getattr(Qt.ApplicationAttribute, "AA_UseHighDpiPixmaps", None)
    if high_dpi_pixmaps is not None:
        app.setAttribute(high_dpi_pixmaps, True)

    win = MainWindow()
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
