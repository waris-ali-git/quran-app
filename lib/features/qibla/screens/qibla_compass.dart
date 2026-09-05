import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ─── Color Palette (Pastel Blue / Sky / Ice) ─────────────────────────────────
const _iceWhite     = Color(0xFFFAFDFF);
const _whisperBlue  = Color(0xFFDBE9FA);
const _babyBlue     = Color(0xFFA6C7F2);
const _carolinaBlue = Color(0xFF90BDE7);
const _blueDark     = Color(0xFF6FA8D8);
const _steelBlue    = Color(0xFF6B8FB5);
const _navyDeep     = Color(0xFF1A2E44);
const _navyMid      = Color(0xFF4A6B8A);
const _shadowBlue   = Color(0x18407ABA);

// ─── Kaaba coordinates ───────────────────────────────────────────────────────
const double _kaabaLat = 21.4225;
const double _kaabaLng = 39.8262;

// ─── Qibla math (fallback if API fails) ─────────────────────────────────────
double _toRad(double deg) => deg * math.pi / 180;
double _toDeg(double rad) => rad * 180 / math.pi;

double calculateQiblaLocal(double lat, double lng) {
  final phi1 = _toRad(lat);
  final phi2 = _toRad(_kaabaLat);
  final dL   = _toRad(_kaabaLng - lng);
  final y    = math.sin(dL) * math.cos(phi2);
  final x    = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dL);
  return (_toDeg(math.atan2(y, x)) + 360) % 360;
}

// ─── AlAdhan API — free, no key, includes magnetic declination ───────────────
//  Endpoint: https://api.aladhan.com/v1/qibla/{lat}/{lng}
//  Returns: { data: { direction: <degrees from North> } }
Future<double?> fetchQiblaFromAlAdhan(double lat, double lng) async {
  try {
    final uri = Uri.parse(
        'https://api.aladhan.com/v1/qibla/${lat.toStringAsFixed(6)}/${lng.toStringAsFixed(6)}');
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['code'] == 200 && data['data'] != null) {
        return (data['data']['direction'] as num).toDouble();
      }
    }
  } catch (_) {}
  return null;
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});
  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen>
    with TickerProviderStateMixin {
  double? _qiblaAngle;
  double  _deviceHeading = 0;
  String  _statusMsg     = 'Locating your position…';
  bool    _hasError      = false;
  bool    _isAligned     = false;
  String  _locationSource = '';
  String  _qiblaSource    = '';

  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryScale;
  late final Animation<double>   _entryOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5000))
      ..repeat();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _entryScale   = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);
    _entryOpacity = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _initLocation();
  }

  // ── Location: 4-source fallback chain ────────────────────────────────────
  Future<void> _initLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) {
      final ok = await _tryIpLocation();
      if (!ok) {
        setState(() {
          _hasError  = true;
          _statusMsg = 'Location permission denied.\nEnable in Settings.';
        });
      }
      _listenCompass();
      return;
    }

    bool got = await _tryGPS(LocationAccuracy.high, timeoutSec: 12);
    if (!got) got = await _tryGPS(LocationAccuracy.medium, timeoutSec: 8);
    if (!got) got = await _tryIpLocation();
    if (!got) got = await _tryLastKnown();

    if (!got) {
      setState(() {
        _hasError  = true;
        _statusMsg = 'Could not determine location.\nTap Retry.';
      });
    }
    _listenCompass();
  }

  Future<bool> _tryGPS(LocationAccuracy accuracy, {required int timeoutSec}) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: Duration(seconds: timeoutSec),
        ),
      );
      await _applyPosition(
        pos.latitude, pos.longitude,
        locSource: accuracy == LocationAccuracy.high ? 'GPS' : 'Network',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _tryIpLocation() async {
    try {
      final res = await http
          .get(Uri.parse('http://ip-api.com/json/?fields=lat,lon,city,status'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          final lat  = (data['lat'] as num).toDouble();
          final lon  = (data['lon'] as num).toDouble();
          final city = data['city'] ?? '';
          await _applyPosition(lat, lon, locSource: 'IP ($city)');
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _tryLastKnown() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        await _applyPosition(pos.latitude, pos.longitude, locSource: 'Cached');
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Apply position + fetch precise Qibla from AlAdhan API ────────────────
  Future<void> _applyPosition(double lat, double lng, {String locSource = ''}) async {
    if (!mounted) return;

    // 1. Immediately show local calculation so UI isn't blank
    final localAngle = calculateQiblaLocal(lat, lng);
    setState(() {
      _qiblaAngle     = localAngle;
      _hasError       = false;
      _locationSource = locSource;
      _qiblaSource    = 'Local calc';
      _statusMsg      = '${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°';
    });
    if (!_entryCtrl.isCompleted) _entryCtrl.forward();

    // 2. Refine with AlAdhan API (magnetic-declination-corrected)
    final apiAngle = await fetchQiblaFromAlAdhan(lat, lng);
    if (apiAngle != null && mounted) {
      setState(() {
        _qiblaAngle  = apiAngle;
        _qiblaSource = 'AlAdhan API';
      });
    }
  }

  void _listenCompass() {
    FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final h = event.heading ?? 0;
      setState(() {
        _deviceHeading = h;
        if (_qiblaAngle != null) {
          final diff = ((_qiblaAngle! - h) % 360 + 360) % 360;
          _isAligned = diff < 4 || diff > 356;
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  double get _needleAngle {
    if (_qiblaAngle == null) return 0;
    return _toRad(_qiblaAngle! - _deviceHeading);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _iceWhite,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_iceWhite, _whisperBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _buildCompassArea(),
                      const SizedBox(height: 28),
                      _buildBottomInfo(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _iceWhite,
        boxShadow: [
          BoxShadow(
            color: _carolinaBlue.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      color: _steelBlue,
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      'Qibla Direction',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _navyDeep,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _carolinaBlue.withValues(alpha: 0),
                    _carolinaBlue.withValues(alpha: 0.5),
                    _carolinaBlue.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ── Compass area ─────────────────────────────────────────────────────────
  Widget _buildCompassArea() {
    return Center(
      child: SizedBox(
        width: 300, height: 300,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseCtrl, _shimmerCtrl]),
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              _buildGlowRing(),
              _buildDial(),
              _buildCardinals(),
              if (_qiblaAngle != null) _buildNeedle(),
              _buildCenterJewel(),
              if (_qiblaAngle == null) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowRing() => Container(
    width: 300, height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: _carolinaBlue.withValues(alpha: 0.12 + 0.08 * _pulseCtrl.value),
          blurRadius: 40,
          spreadRadius: 10,
        ),
      ],
    ),
  );

  Widget _buildDial() => Transform.rotate(
    angle: -_toRad(_deviceHeading),
    child: CustomPaint(
      size: const Size(300, 300),
      painter: _BlueDialPainter(shimmer: _shimmerCtrl.value, isAligned: _isAligned),
    ),
  );

  Widget _buildCardinals() {
    const labels = ['N', 'E', 'S', 'W'];
    const angles = [0.0, 90.0, 180.0, 270.0];
    return Transform.rotate(
      angle: -_toRad(_deviceHeading),
      child: SizedBox(
        width: 300, height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(4, (i) {
            final rad = _toRad(angles[i]);
            const r = 112.0;
            return Transform.translate(
              offset: Offset(r * math.sin(rad), -r * math.cos(rad)),
              child: Text(
                labels[i],
                style: GoogleFonts.montserrat(
                  fontSize: i == 0 ? 16 : 12,
                  fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                  color: i == 0 ? _carolinaBlue : _steelBlue,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNeedle() => ScaleTransition(
    scale: _entryScale,
    child: FadeTransition(
      opacity: _entryOpacity,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Transform.rotate(
          angle: _needleAngle,
          child: CustomPaint(
            size: const Size(300, 300),
            painter: _BlueNeedlePainter(pulse: _pulseCtrl.value, isAligned: _isAligned),
          ),
        ),
      ),
    ),
  );

  Widget _buildCenterJewel() => AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    width: _isAligned ? 22 : 16,
    height: _isAligned ? 22 : 16,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _iceWhite,
      border: Border.all(
        color: _isAligned ? _carolinaBlue : _babyBlue,
        width: _isAligned ? 2 : 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: _carolinaBlue.withValues(alpha: _isAligned ? 0.5 : 0.2),
          blurRadius: _isAligned ? 12 : 4,
        ),
      ],
    ),
    child: Center(
      child: Container(
        width: _isAligned ? 7 : 5,
        height: _isAligned ? 7 : 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isAligned ? _carolinaBlue : _babyBlue,
        ),
      ),
    ),
  );

  Widget _buildLoadingOverlay() => Container(
    width: 300, height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _iceWhite.withValues(alpha: 0.92),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_hasError)
            AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _shimmerCtrl.value * 2 * math.pi,
                child: CustomPaint(
                    size: const Size(48, 48), painter: _BlueRingPainter()),
              ),
            )
          else
            const Icon(Icons.location_off_rounded, color: _carolinaBlue, size: 36),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _statusMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: _navyMid,
                height: 1.6,
              ),
            ),
          ),
          if (_hasError) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() { _hasError = false; _statusMsg = 'Retrying…'; });
                _initLocation();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                decoration: BoxDecoration(
                  color: _carolinaBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: _iceWhite,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  // ── Bottom info ───────────────────────────────────────────────────────────
  Widget _buildBottomInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _buildDivider(),
          const SizedBox(height: 18),
          if (_qiblaAngle != null)
            _isAligned ? _buildAlignedBadge() : _buildRotateHint(),
          const SizedBox(height: 14),
          _buildLocationChip(),
          if (_qiblaSource.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSourceChip(),
          ],
          const SizedBox(height: 18),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildDivider() => Row(
    children: [
      Expanded(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _carolinaBlue.withValues(alpha: 0),
              _carolinaBlue.withValues(alpha: 0.3),
            ]),
          ),
        ),
      ),
      Container(
        width: 5, height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _babyBlue.withValues(alpha: 0.6),
        ),
      ),
      Expanded(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _carolinaBlue.withValues(alpha: 0.3),
              _carolinaBlue.withValues(alpha: 0),
            ]),
          ),
        ),
      ),
    ],
  );

  Widget _buildAlignedBadge() => AnimatedBuilder(
    animation: _pulseCtrl,
    builder: (_, __) => Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: _iceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _carolinaBlue.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _carolinaBlue.withValues(alpha: 0.15 + 0.1 * _pulseCtrl.value),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mosque_rounded, color: _carolinaBlue, size: 18),
          const SizedBox(width: 8),
          Text(
            'Facing the Qibla',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _navyDeep,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildRotateHint() {
    if (_qiblaAngle == null) return const SizedBox.shrink();
    final diff     = ((_qiblaAngle! - _deviceHeading) % 360 + 360) % 360;
    final turnLeft = diff > 180;
    final degrees  = turnLeft ? 360 - diff : diff;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: _iceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _babyBlue.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: _shadowBlue,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            turnLeft
                ? Icons.rotate_left_rounded
                : Icons.rotate_right_rounded,
            color: _carolinaBlue,
            size: 20,
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Rotate ',
                style: GoogleFonts.montserrat(fontSize: 14, color: _navyMid),
              ),
              TextSpan(
                text: '${degrees.toStringAsFixed(1)}°',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _carolinaBlue,
                ),
              ),
              TextSpan(
                text: turnLeft ? ' left' : ' right',
                style: GoogleFonts.montserrat(fontSize: 14, color: _navyMid),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationChip() => Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
    decoration: BoxDecoration(
      color: _iceWhite,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _babyBlue.withValues(alpha: 0.5), width: 1),
      boxShadow: [BoxShadow(color: _shadowBlue, blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on_rounded, color: _carolinaBlue, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _qiblaAngle != null
                ? '${_qiblaAngle!.toStringAsFixed(2)}° from North  •  $_statusMsg'
                : _statusMsg,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(fontSize: 13, color: _navyMid),
          ),
        ),
      ],
    ),
  );

  Widget _buildSourceChip() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _qiblaSource == 'AlAdhan API' ? _carolinaBlue : _babyBlue,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        _qiblaSource == 'AlAdhan API'
            ? 'Precise • AlAdhan API'
            : 'Approximate • Local calculation',
        style: GoogleFonts.montserrat(
          fontSize: 11,
          color: _qiblaSource == 'AlAdhan API' ? _carolinaBlue : _steelBlue,
          letterSpacing: 0.3,
        ),
      ),
    ],
  );


}

// ─── Painters ────────────────────────────────────────────────────────────────

class _BlueDialPainter extends CustomPainter {
  final double shimmer;
  final bool isAligned;
  _BlueDialPainter({required this.shimmer, required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    // Background fill — soft gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [_whisperBlue, _iceWhite.withValues(alpha: 0.85)],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bgPaint);

    // Outer ring — sweeping blue shimmer
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        transform: GradientRotation(shimmer * 2 * math.pi),
        colors: [
          _steelBlue.withValues(alpha: 0.3),
          _carolinaBlue,
          _babyBlue,
          _carolinaBlue,
          _steelBlue.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r)));

    // Inner accent rings
    canvas.drawCircle(c, r - 6,  Paint()..style=PaintingStyle.stroke..strokeWidth=0.5..color=_carolinaBlue.withValues(alpha: 0.35));
    canvas.drawCircle(c, r - 11, Paint()..style=PaintingStyle.stroke..strokeWidth=0.3..color=_babyBlue.withValues(alpha: 0.2));

    // Tick marks
    final tp = Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    for (int i = 0; i < 360; i++) {
      final a      = _toRad(i.toDouble());
      final isMaj  = i % 90 == 0;
      final isMed  = i % 45 == 0;
      final isTen  = i % 10 == 0;
      double ir, or2;
      if (isMaj)    { ir = r-26; or2 = r-6; tp..color=_carolinaBlue..strokeWidth=2.0; }
      else if (isMed){ ir = r-18; or2 = r-6; tp..color=_carolinaBlue.withValues(alpha: 0.6)..strokeWidth=1.3; }
      else if (isTen){ ir = r-12; or2 = r-6; tp..color=_babyBlue.withValues(alpha: 0.5)..strokeWidth=0.8; }
      else           { ir = r-8;  or2 = r-6; tp..color=_babyBlue.withValues(alpha: 0.2)..strokeWidth=0.5; }

      canvas.drawLine(
        Offset(c.dx + ir  * math.sin(a), c.dy - ir  * math.cos(a)),
        Offset(c.dx + or2 * math.sin(a), c.dy - or2 * math.cos(a)),
        tp,
      );
    }

    // Inner dial face
    canvas.drawCircle(c, 58, Paint()
      ..shader = RadialGradient(
        colors: [_iceWhite, _whisperBlue],
      ).createShader(Rect.fromCircle(center: c, radius: 58)));
    canvas.drawCircle(c, 58, Paint()..style=PaintingStyle.stroke..strokeWidth=0.8..color=_carolinaBlue.withValues(alpha: 0.4));
    canvas.drawCircle(c, 50, Paint()..style=PaintingStyle.stroke..strokeWidth=0.3..color=_babyBlue.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(_BlueDialPainter o) => o.shimmer != shimmer || o.isAligned != isAligned;
}

class _BlueNeedlePainter extends CustomPainter {
  final double pulse;
  final bool isAligned;
  _BlueNeedlePainter({required this.pulse, required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    // Glow when aligned
    if (isAligned) {
      canvas.drawCircle(
        Offset(c.dx, c.dy - 86),
        16,
        Paint()
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 8 * pulse)
          ..color = _carolinaBlue.withValues(alpha: 0.35 + 0.2 * pulse),
      );
    }

    // Main needle
    final path = Path()
      ..moveTo(c.dx, c.dy - 104)
      ..lineTo(c.dx - 6.5, c.dy - 22)
      ..lineTo(c.dx, c.dy - 12)
      ..lineTo(c.dx + 6.5, c.dy - 22)
      ..close();

    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isAligned
            ? [_babyBlue, _carolinaBlue]
            : [_carolinaBlue, _steelBlue],
      ).createShader(Rect.fromPoints(Offset(c.dx, c.dy - 104), c)));

    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = _blueDark.withValues(alpha: 0.4));

    // Kaaba cube at needle tip
    final cubeRect = Rect.fromCenter(
      center: Offset(c.dx, c.dy - 113),
      width: 18, height: 15,
    );
    // Cube body
    canvas.drawRRect(
      RRect.fromRectAndRadius(cubeRect, const Radius.circular(2)),
      Paint()..color = _navyDeep,
    );
    // Cube border
    canvas.drawRRect(
      RRect.fromRectAndRadius(cubeRect, const Radius.circular(2)),
      Paint()..style=PaintingStyle.stroke..strokeWidth=1.4..color=_carolinaBlue,
    );
    // Kiswah band
    final bandY = cubeRect.top + 4.5;
    for (final dy in [0.0, 3.5]) {
      canvas.drawLine(
        Offset(cubeRect.left + 1, bandY + dy),
        Offset(cubeRect.right - 1, bandY + dy),
        Paint()..color=_babyBlue..strokeWidth=0.9,
      );
    }
    // Door
    final door = Rect.fromCenter(
      center: Offset(c.dx, cubeRect.bottom - 4),
      width: 5.5, height: 6.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(door, const Radius.circular(0.5)),
      Paint()..color=_carolinaBlue.withValues(alpha: 0.85),
    );

    // Counter needle (back)
    final back = Path()
      ..moveTo(c.dx, c.dy + 56)
      ..lineTo(c.dx - 4.5, c.dy + 18)
      ..lineTo(c.dx, c.dy + 10)
      ..lineTo(c.dx + 4.5, c.dy + 18)
      ..close();
    canvas.drawPath(back, Paint()..color=_steelBlue.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(_BlueNeedlePainter o) => o.pulse != pulse || o.isAligned != isAligned;
}

class _BlueRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: size.width / 2 - 2),
      0,
      3 * math.pi / 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [Colors.transparent, _carolinaBlue],
        ).createShader(Rect.fromCircle(center: c, radius: size.width / 2)),
    );
  }
  @override bool shouldRepaint(_) => true;
}

class _KaabaIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Body
    final body = Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.82);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(2)),
      Paint()..color = _navyDeep,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(2)),
      Paint()..style=PaintingStyle.stroke..strokeWidth=1.6..color=_carolinaBlue,
    );

    // Kiswah band
    final bandTop = h * 0.28;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.1, bandTop, w * 0.8, h * 0.14),
      Paint()..color = _carolinaBlue.withValues(alpha: 0.18),
    );
    canvas.drawLine(Offset(w * 0.1, bandTop), Offset(w * 0.9, bandTop),
        Paint()..color=_carolinaBlue..strokeWidth=1.0);
    canvas.drawLine(Offset(w * 0.1, bandTop + h * 0.14),
        Offset(w * 0.9, bandTop + h * 0.14),
        Paint()..color=_carolinaBlue..strokeWidth=1.0);

    // Door
    final door = Rect.fromLTWH(w * 0.36, h * 0.5, w * 0.28, h * 0.42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(door, const Radius.circular(2)),
      Paint()..color = _carolinaBlue,
    );
    canvas.drawLine(Offset(w * 0.5, door.top + 4), Offset(w * 0.5, door.bottom - 4),
        Paint()..color=_navyDeep..strokeWidth=0.8);

    // Black Stone (Hajar al-Aswad) oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.1, h * 0.18), width: 12, height: 9),
      Paint()..color = const Color(0xFF0D1A2A),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.1, h * 0.18), width: 12, height: 9),
      Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=_carolinaBlue,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.1, h * 0.18), width: 5, height: 4),
      Paint()..color = _babyBlue.withValues(alpha: 0.4),
    );
  }

  @override bool shouldRepaint(_) => false;
}