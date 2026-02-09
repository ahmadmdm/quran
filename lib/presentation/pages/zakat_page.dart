import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';

class ZakatPage extends StatefulWidget {
  const ZakatPage({super.key});

  @override
  State<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends State<ZakatPage> {
  final _assetsController = TextEditingController();
  final _goldController = TextEditingController();
  final _liabilitiesController = TextEditingController();

  double _zakatDue = 0;
  bool _isEligible = false;
  bool _hasCalculated = false;
  // Approximate value of 85g of Gold (Nisab) in USD, this should ideally be fetched from API
  final double _nisabThreshold = 5500.0;

  double _parseNumber(String value) {
    final normalized = value.replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0;
  }

  void _calculateZakat() {
    final assets = _parseNumber(_assetsController.text);
    final gold = _parseNumber(_goldController.text);
    final liabilities = _parseNumber(_liabilitiesController.text);

    final netWorth = (assets + gold - liabilities).clamp(0, double.infinity);

    setState(() {
      _hasCalculated = true;
      if (netWorth >= _nisabThreshold) {
        _zakatDue = netWorth * 0.025;
        _isEligible = true;
      } else {
        _zakatDue = 0;
        _isEligible = false;
      }
    });

    // Dismiss keyboard
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _assetsController.dispose();
    _goldController.dispose();
    _liabilitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.translate('zakat_calculator')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputCard(
              localizations.translate('total_assets'),
              Icons.account_balance_wallet,
              _assetsController,
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              localizations.translate('gold_silver'),
              Icons.monetization_on,
              _goldController,
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              localizations.translate('liabilities'),
              Icons.money_off,
              _liabilitiesController,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _calculateZakat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Text(
                localizations.translate('calculate'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_hasCalculated)
              _buildResultCard(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(
    String title,
    IconData icon,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: '0.0',
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isEligible
              ? [Theme.of(context).colorScheme.primary, const Color(0xFF27AE60)]
              : [Colors.grey.shade700, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                (_isEligible
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black)
                    .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isEligible
                ? localizations.translate('eligible_for_zakat')
                : localizations.translate('not_eligible'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_isEligible) ...[
            Text(
              localizations.translate('zakat_due'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _zakatDue.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${localizations.translate('nisab_threshold')}: $_nisabThreshold',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
