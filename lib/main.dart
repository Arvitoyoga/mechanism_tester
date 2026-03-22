import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const DroneMonitorApp());
}

class DroneMonitorApp extends StatelessWidget {
  const DroneMonitorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "CAKSA Drone Monitor",
      theme: ThemeData.dark(),
      home: const DashboardPage(),
    );
  }
}

// =====================================================
// RIPPLE BUTTON — efek tekan profesional
// =====================================================
class _TactileButton extends StatefulWidget {
  final String label;
  final String cmd;
  final bool locked;
  final Future<void> Function(String) onSend;

  const _TactileButton({
    required this.label,
    required this.cmd,
    required this.locked,
    required this.onSend,
  });

  @override
  State<_TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<_TactileButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.91).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glow = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _tap() async {
    if (widget.locked) return;
    HapticFeedback.mediumImpact();
    await _ctrl.forward();
    await widget.onSend(widget.cmd);
    await _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: _tap,
        onTapDown: (_) { if (!widget.locked) _ctrl.forward(); },
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: widget.locked
                    ? LinearGradient(colors: [
                        const Color(0xFF1C1C2E),
                        const Color(0xFF16162A),
                      ])
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF00C6FF),
                          const Color(0xFF0072FF),
                        ],
                      ),
                border: Border.all(
                  color: widget.locked
                      ? Colors.white.withAlpha(12)
                      : Colors.cyanAccent.withAlpha(
                          (80 + (_glow.value * 120)).toInt()),
                  width: 1,
                ),
                boxShadow: widget.locked
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF00C6FF)
                              .withAlpha((30 + (_glow.value * 80)).toInt()),
                          blurRadius: 10 + (_glow.value * 8),
                          spreadRadius: 0,
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: widget.locked
                      ? Colors.white.withAlpha(50)
                      : Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// BLUETOOTH PICKER
// =====================================================
class BluetoothPickerSheet extends StatefulWidget {
  const BluetoothPickerSheet({super.key});
  @override
  State<BluetoothPickerSheet> createState() => _BluetoothPickerSheetState();
}

class _BluetoothPickerSheetState extends State<BluetoothPickerSheet> {
  List<BluetoothDevice> _devices = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await FlutterBluetoothSerial.instance.getBondedDevices();
      if (mounted) setState(() { _devices = d; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.cyanAccent.withAlpha(35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 3,
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withAlpha(70),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
            child: Row(children: [
              const Icon(Icons.bluetooth_searching, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 8),
              Text("PILIH DEVICE", style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent, fontSize: 12,
                  fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white38, size: 16), onPressed: _load),
              IconButton(icon: const Icon(Icons.close, color: Colors.white38, size: 16), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(color: Color(0xFF1A2540), height: 1),
          SizedBox(
            height: 220,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 1.5))
                : _devices.isEmpty
                    ? Center(child: Text("Tidak ada device paired",
                          style: GoogleFonts.orbitron(color: Colors.white30, fontSize: 10)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _devices.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFF1A2540), height: 1, indent: 56),
                        itemBuilder: (context, i) {
                          final d = _devices[i];
                          final isESP = d.name?.contains("ESP") == true || d.name?.contains("TELEM") == true;
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isESP ? Colors.cyanAccent.withAlpha(18) : Colors.white.withAlpha(8),
                                border: Border.all(color: isESP ? Colors.cyanAccent.withAlpha(60) : Colors.white12),
                              ),
                              child: Icon(isESP ? Icons.developer_board : Icons.bluetooth,
                                  color: isESP ? Colors.cyanAccent : Colors.white38, size: 16),
                            ),
                            title: Text(d.name ?? "Unknown", style: GoogleFonts.orbitron(
                                color: isESP ? Colors.cyanAccent : Colors.white,
                                fontSize: 11, fontWeight: isESP ? FontWeight.bold : FontWeight.normal)),
                            subtitle: Text(d.address, style: GoogleFonts.orbitron(color: Colors.white30, fontSize: 8)),
                            trailing: isESP
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.cyanAccent.withAlpha(50)),
                                      color: Colors.cyanAccent.withAlpha(12),
                                    ),
                                    child: Text("RECOMMENDED", style: GoogleFonts.orbitron(
                                        color: Colors.cyanAccent, fontSize: 7)),
                                  )
                                : const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                            onTap: () => Navigator.pop(context, d),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Text("Pair ESP32 terlebih dahulu di Settings Bluetooth",
                style: GoogleFonts.orbitron(color: Colors.white.withAlpha(50), fontSize: 8)),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DASHBOARD
// =====================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  BluetoothConnection? _conn;
  StreamSubscription? _sub;
  bool isConnected = false;
  String connectedName = "";
  String _buffer = "";
  bool locked = true;

  // Telemetri
  int drone = 1, cam = 1, mode = 0, payload = 0, pos = 0, dropA = 0, dropB = 0;

  // Animasi pulse dot
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Timestamp update terakhir
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> connectBluetooth() async {
    final status = await Permission.bluetoothConnect.status;
    if (!status.isGranted) { await _requestPermissions(); return; }

    final device = await showModalBottomSheet<BluetoothDevice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BluetoothPickerSheet(),
    );
    if (device == null) return;

    _showSnack("Menghubungkan ke ${device.name}...");
    try {
      final conn = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _conn = conn;
        isConnected = true;
        connectedName = device.name ?? device.address;
        _buffer = "";
      });

      _sub = conn.input!.listen((data) {
        _buffer += utf8.decode(data, allowMalformed: true);
        while (_buffer.contains('\n')) {
          int i = _buffer.indexOf('\n');
          String line = _buffer.substring(0, i).trim();
          _buffer = _buffer.substring(i + 1);
          if (line.isNotEmpty) _parse(line);
        }
      },
      onDone: () => _disconnect(),
      onError: (_) => _disconnect(),
      cancelOnError: false);

      HapticFeedback.heavyImpact();
      _showSnack("✓ Terhubung ke ${device.name}");
    } catch (e) { _showSnack("Gagal: $e"); }
  }

  void _disconnect() {
    _sub?.cancel(); _sub = null;
    _conn?.dispose(); _conn = null;
    if (mounted) {
      setState(() { isConnected = false; connectedName = ""; _lastUpdate = null; });
      _showSnack("Koneksi terputus");
    }
  }

  Future<void> disconnectBluetooth() async {
    HapticFeedback.mediumImpact();
    try { await _conn?.finish(); } catch (_) {}
    _disconnect();
  }

  void _parse(String data) {
    try {
      final v = data.trim().split(",");
      if (v.length < 7) return;
      setState(() {
        drone   = int.tryParse(v[0]) ?? drone;
        cam     = int.tryParse(v[1]) ?? cam;
        mode    = int.tryParse(v[2]) ?? mode;
        payload = int.tryParse(v[3]) ?? payload;
        pos     = int.tryParse(v[4]) ?? pos;
        dropA   = int.tryParse(v[5]) ?? dropA;
        dropB   = int.tryParse(v[6]) ?? dropB;
        _lastUpdate = DateTime.now();
      });
    } catch (_) {}
  }

  Future<void> sendCommand(String cmd) async {
    if (_conn == null || !_conn!.isConnected) { _showSnack("Tidak terhubung"); return; }
    try {
      _conn!.output.add(utf8.encode("$cmd\n"));
      await _conn!.output.allSent;
    } catch (e) { _showSnack("Gagal kirim: $e"); }
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _sub?.cancel(); _conn?.dispose(); super.dispose(); }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.orbitron(fontSize: 10, color: Colors.white)),
      backgroundColor: const Color(0xFF0D1525),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.cyanAccent.withAlpha(40))),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Helpers ──
  String _modeText()    => mode == 1 ? "VOICE" : "MANUAL";
  String _posText()     => ["FRONT","RIGHT","LEFT"].elementAtOrNull(pos) ?? "-";
  String _dropText(int v) => ["LEFT","MID","RIGHT"].elementAtOrNull(v) ?? "-";

  String _lastUpdateStr() {
    if (_lastUpdate == null) return "--:--:--";
    final t = _lastUpdate!;
    return "${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:${t.second.toString().padLeft(2,'0')}";
  }

  // =====================================================
  // WIDGETS
  // =====================================================

  // ── Label kecil di atas value ──
  Widget _dataCard(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyanAccent.withAlpha(25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Colors.white.withAlpha(6), Colors.white.withAlpha(2)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.orbitron(
              color: Colors.white38, fontSize: 8, letterSpacing: 1)),
          Text(value, style: GoogleFonts.orbitron(
              color: valueColor ?? Colors.cyanAccent,
              fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Signal bar (simulasi sinyal) ──
  Widget _signalBars() {
    return Row(
      children: List.generate(4, (i) => Container(
        width: 4, height: 6.0 + i * 3,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          color: isConnected
              ? Colors.greenAccent.withAlpha(180 + i * 18)
              : Colors.white.withAlpha(25),
        ),
      )),
    );
  }

  // ── Monitor Panel ──
  Widget _monitorPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Title bar ──
          Row(children: [
            Text("MONITOR", style: GoogleFonts.orbitron(
                color: Colors.cyanAccent, fontSize: 12,
                fontWeight: FontWeight.bold, letterSpacing: 3)),
            const Spacer(),
            // Live badge
            if (isConnected)
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Opacity(
                  opacity: _pulse.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.greenAccent.withAlpha(20),
                      border: Border.all(color: Colors.greenAccent.withAlpha(60)),
                    ),
                    child: Row(children: [
                      Container(width: 5, height: 5,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.greenAccent)),
                      const SizedBox(width: 4),
                      Text("LIVE", style: GoogleFonts.orbitron(
                          color: Colors.greenAccent, fontSize: 7, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 8),

          // ── Connection card ──
          GestureDetector(
            onTap: isConnected ? null : connectBluetooth,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isConnected ? Colors.greenAccent.withAlpha(70) : Colors.cyanAccent.withAlpha(40),
                  width: 1,
                ),
                gradient: LinearGradient(
                  colors: isConnected
                      ? [Colors.greenAccent.withAlpha(15), Colors.greenAccent.withAlpha(5)]
                      : [Colors.cyanAccent.withAlpha(10), Colors.cyanAccent.withAlpha(3)],
                ),
              ),
              child: Row(children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? Colors.greenAccent : Colors.redAccent,
                      boxShadow: isConnected ? [BoxShadow(
                        color: Colors.greenAccent.withAlpha(
                            (60 * _pulse.value).toInt()),
                        blurRadius: 8, spreadRadius: 1,
                      )] : [],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isConnected ? connectedName : "TIDAK TERHUBUNG",
                        style: GoogleFonts.orbitron(
                            color: isConnected ? Colors.greenAccent : Colors.white38,
                            fontSize: 10, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                    if (isConnected)
                      Text("Update: ${_lastUpdateStr()}",
                          style: GoogleFonts.orbitron(color: Colors.white30, fontSize: 7)),
                  ],
                )),
                const SizedBox(width: 6),
                if (isConnected) _signalBars(),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isConnected ? disconnectBluetooth : connectBluetooth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isConnected ? Colors.redAccent.withAlpha(25) : Colors.cyanAccent.withAlpha(25),
                      border: Border.all(color: isConnected ? Colors.redAccent.withAlpha(70) : Colors.cyanAccent.withAlpha(70)),
                    ),
                    child: Text(isConnected ? "PUTUS" : "KONEK",
                        style: GoogleFonts.orbitron(
                            color: isConnected ? Colors.redAccent : Colors.cyanAccent,
                            fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ),

          // ── Drone & Cam ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(colors: [
                Colors.cyanAccent.withAlpha(18),
                Colors.blue.withAlpha(10),
              ]),
              border: Border.all(color: Colors.cyanAccent.withAlpha(35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.flight, color: Colors.cyanAccent, size: 14),
                  const SizedBox(width: 6),
                  Text("DRONE $drone", style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
                Row(children: [
                  const Icon(Icons.videocam, color: Colors.cyanAccent, size: 12),
                  const SizedBox(width: 4),
                  Text("CAM $cam", style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent, fontSize: 10)),
                ]),
              ],
            ),
          ),

          // ── Telemetri cards ──
          _dataCard("MODE",          _modeText()),
          _dataCard("PAYLOAD SEQ",   "$payload"),
          _dataCard("DRONE POS",     _posText()),
          _dataCard("FRONT DROPPER", _dropText(dropA)),
          _dataCard("REAR DROPPER",  _dropText(dropB)),

          // ── Footer info ──
          const SizedBox(height: 4),
          Center(
            child: Text("CAKSA v1.0",
                style: GoogleFonts.orbitron(color: Colors.white.withAlpha(38), fontSize: 7, letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  // ── Control Panel ──
  Widget _controlPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + lock ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("CONTROL", style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent, fontSize: 12,
                  fontWeight: FontWeight.bold, letterSpacing: 3)),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => locked = !locked);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: locked ? Colors.redAccent.withAlpha(20) : Colors.greenAccent.withAlpha(20),
                    border: Border.all(
                        color: locked ? Colors.redAccent.withAlpha(70) : Colors.greenAccent.withAlpha(70)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(locked ? Icons.lock_outline : Icons.lock_open_outlined,
                        color: locked ? Colors.redAccent : Colors.greenAccent, size: 11),
                    const SizedBox(width: 4),
                    Text(locked ? "LOCKED" : "UNLOCKED",
                        style: GoogleFonts.orbitron(
                            color: locked ? Colors.redAccent : Colors.greenAccent,
                            fontSize: 8, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ],
          ),

          if (locked)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text("Tap LOCKED untuk mengaktifkan kontrol",
                  style: GoogleFonts.orbitron(color: Colors.white.withAlpha(50), fontSize: 7)),
            ),

          const SizedBox(height: 10),

          // ── Section: DROPPER ──
          _sectionLabel("DROPPER"),
          const SizedBox(height: 5),
          Row(children: [
            _TactileButton(label: "DROP\nFRONT", cmd: "1", locked: locked, onSend: sendCommand),
            const SizedBox(width: 6),
            _TactileButton(label: "DROP\nREAR", cmd: "2", locked: locked, onSend: sendCommand),
          ]),
          const SizedBox(height: 5),
          Row(children: [
            _TactileButton(label: "RESET DROPPER", cmd: "3", locked: locked, onSend: sendCommand),
          ]),

          const SizedBox(height: 10),

          // ── Section: PAYLOAD ──
          _sectionLabel("PAYLOAD"),
          const SizedBox(height: 5),
          Row(children: [
            _TactileButton(label: "RELOAD\nPAYLOAD", cmd: "4", locked: locked, onSend: sendCommand),
            const SizedBox(width: 6),
            _TactileButton(label: "ROTATE\nDRONE", cmd: "5", locked: locked, onSend: sendCommand),
          ]),
          const SizedBox(height: 5),
          Row(children: [
            _TactileButton(label: "RESET RELOADER", cmd: "6", locked: locked, onSend: sendCommand),
          ]),

          const SizedBox(height: 10),

          // ── Section: SYSTEM ──
          _sectionLabel("SYSTEM"),
          const SizedBox(height: 5),
          Row(children: [
            _TactileButton(label: "SWITCH\nCAM", cmd: "7", locked: locked, onSend: sendCommand),
            const SizedBox(width: 6),
            _TactileButton(label: "SWITCH\nDRONE", cmd: "8", locked: locked, onSend: sendCommand),
          ]),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(children: [
      Container(width: 2, height: 10, color: Colors.cyanAccent.withAlpha(150),
          margin: const EdgeInsets.only(right: 6)),
      Text(label, style: GoogleFonts.orbitron(
          color: Colors.white38, fontSize: 8, letterSpacing: 2)),
      const SizedBox(width: 8),
      Expanded(child: Container(height: 1, color: Colors.white.withAlpha(12))),
    ]);
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _monitorPanel()),
            Container(
              width: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.cyanAccent.withAlpha(50),
                    Colors.cyanAccent.withAlpha(50),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Expanded(child: _controlPanel()),
          ],
        ),
      ),
    );
  }
}