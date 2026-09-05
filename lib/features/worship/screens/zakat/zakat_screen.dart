import 'package:flutter/material.dart';
import '../../../../core/widgets/translated_text.dart';
import '../../widgets/worship_sliver_header.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  // Input Controllers
  final _goldValueCtrl = TextEditingController();
  final _silverValueCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _assetsCtrl = TextEditingController();
  final _liabilitiesCtrl = TextEditingController();

  double _zakatAmount = 0.0;

  // Light warm amber theme (matching Namaz light gradient pattern)
  static const Color _deepColor = Color(0xFFD4822A); // warm amber
  static const Color _lightColor = Color(0xFFFFD080); // soft gold

  @override
  void initState() {
    super.initState();
    _goldValueCtrl.addListener(_calculateZakat);
    _silverValueCtrl.addListener(_calculateZakat);
    _cashCtrl.addListener(_calculateZakat);
    _assetsCtrl.addListener(_calculateZakat);
    _liabilitiesCtrl.addListener(_calculateZakat);
  }

  @override
  void dispose() {
    _goldValueCtrl.dispose();
    _silverValueCtrl.dispose();
    _cashCtrl.dispose();
    _assetsCtrl.dispose();
    _liabilitiesCtrl.dispose();
    super.dispose();
  }

  void _calculateZakat() {
    double gold = double.tryParse(_goldValueCtrl.text) ?? 0.0;
    double silver = double.tryParse(_silverValueCtrl.text) ?? 0.0;
    double cash = double.tryParse(_cashCtrl.text) ?? 0.0;
    double assets = double.tryParse(_assetsCtrl.text) ?? 0.0;
    double liabilities = double.tryParse(_liabilitiesCtrl.text) ?? 0.0;

    double totalWealth = gold + silver + cash + assets;
    double netWealth = totalWealth - liabilities;
    if (netWealth < 0) netWealth = 0;

    setState(() {
      _zakatAmount = netWealth * 0.025; // 2.5%
    });
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _deepColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF3A2000)),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(
                  color: _deepColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _lightColor, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: _deepColor.withValues(alpha: 0.2), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _deepColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFE), // Ice White
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          WorshipSliverHeader(
            title: 'Zakat',
            subtitle: 'Obligatory Charity',
            arabicTitle: 'زَكَاة',
            icon: Icons.volunteer_activism,
            deepColor: _deepColor,
            lightColor: _lightColor,
            badgeText: 'Pillar #4',
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildInputSection()),
                          const SizedBox(width: 32),
                          Expanded(child: _buildResultSection()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildInputSection(),
                          const SizedBox(height: 24),
                          _buildResultSection(),
                          const SizedBox(height: 40),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBF0), Color(0xFFFFF3CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _deepColor.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            "Wealth Assessment",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _deepColor,
            ),
          ),
          const SizedBox(height: 8),
          const TranslatedText(
            "Enter the current market value of your assets.",
            style: TextStyle(color: Color(0xFF8A6020), fontSize: 14),
          ),
          const SizedBox(height: 28),
          _buildTextField("GOLD VALUE", _goldValueCtrl),
          _buildTextField("SILVER VALUE", _silverValueCtrl),
          _buildTextField("CASH & SAVINGS", _cashCtrl),
          _buildTextField("BUSINESS ASSETS", _assetsCtrl),
          _buildTextField("DEBTS & LIABILITIES", _liabilitiesCtrl),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEEC0), Color(0xFFFFD880)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _deepColor.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      padding: const EdgeInsets.all(36),
      child: Column(
        children: [
          // Calculator Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _deepColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child:
                const Icon(Icons.calculate, color: _deepColor, size: 40),
          ),
          const SizedBox(height: 24),

          // Total Zakat Due Label
          const TranslatedText(
            "TOTAL ZAKAT DUE",
            style: TextStyle(
              color: _deepColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "\$",
                style: TextStyle(
                  color: _deepColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _zakatAmount.toStringAsFixed(2),
                style: const TextStyle(
                  color: Color(0xFF3A2000),
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Quote Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _deepColor.withValues(alpha: 0.3), width: 1.5),
              color: Colors.white.withValues(alpha: 0.4),
            ),
            child: const Text(
              "\"The example of those who spend their wealth in the way of Allah is like a seed of grain which grows seven spikes; in each spike is a hundred grains.\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5A3A00),
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Nisab Threshold Note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline,
                  color: _deepColor, size: 18),
              const SizedBox(width: 8),
              const TranslatedText(
                "NISAB THRESHOLD APPLIES",
                style: TextStyle(
                  color: _deepColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
