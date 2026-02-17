import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/integrations_repository.dart';

/// Integrations: Email and Paysharp configuration for Super Admin.
class IntegrationsPage extends StatefulWidget {
  const IntegrationsPage({super.key});

  @override
  State<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends State<IntegrationsPage> {
  final IntegrationsRepository _repo = IntegrationsRepository();
  int _selectedSection = 0; // 0 = Email, 1 = Paysharp, 2 = PayPal
  bool _paysharpLoading = false;
  bool _paysharpSaving = false;
  bool _paysharpConfigured = false;
  String? _paysharpError;

  // Email integration fields
  final _emailHost = TextEditingController(text: '');
  final _emailPort = TextEditingController(text: '587');
  final _emailUsername = TextEditingController();
  final _emailPassword = TextEditingController();
  final _emailFrom = TextEditingController();
  final _emailFromName = TextEditingController(text: 'BizzPass');
  bool _emailUseTls = true;
  bool _emailPasswordObscured = true;

  // Paysharp integration fields
  final _paysharpApiKey = TextEditingController();
  final _paysharpSecretKey = TextEditingController();
  final _paysharpMerchantId = TextEditingController();
  final _paysharpApiBaseUrl = TextEditingController();
  bool _paysharpSandbox = true;
  bool _paysharpApiKeyObscured = true;
  bool _paysharpSecretKeyObscured = true;

  // PayPal integration fields
  final _paypalClientId = TextEditingController();
  final _paypalClientSecret = TextEditingController();
  bool _paypalConfigured = false;
  bool _paypalLoading = false;
  bool _paypalSaving = false;
  String? _paypalError;

  @override
  void initState() {
    super.initState();
    _loadPaysharpConfig();
    _loadPayPalConfig();
  }

  Future<void> _loadPayPalConfig() async {
    setState(() => _paypalLoading = true);
    try {
      final cfg = await _repo.getPayPalConfig(reveal: true);
      if (mounted) {
        setState(() {
          _paypalConfigured = (cfg['configured'] as bool?) ?? false;
          _paypalLoading = false;
          if (_paypalConfigured) {
            _paypalClientId.text = (cfg['client_id'] as String?) ?? cfg['client_id_masked'] ?? '';
            _paypalClientSecret.text = (cfg['client_secret'] as String?) ?? '••••••••';
          } else {
            _paypalClientId.text = '';
            _paypalClientSecret.text = '';
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _paypalLoading = false);
    }
  }

  Future<void> _loadPaysharpConfig() async {
    setState(() {
      _paysharpLoading = true;
      _paysharpError = null;
    });
    try {
      // reveal=true so one response returns all details: api_key, secret_key, merchant_id, etc.
      final config = await _repo.getPaysharpConfig(reveal: true);
      if (!mounted) return;
      setState(() {
        _paysharpLoading = false;
        _paysharpConfigured = config.configured;
        _paysharpSandbox = config.sandbox;
        _paysharpApiBaseUrl.text = config.apiBaseUrl ?? '';
        _paysharpMerchantId.text = config.merchantId ?? '';
        if (config.configured) {
          _paysharpApiKey.text = config.apiKey ?? config.apiKeyMasked ?? '';
          _paysharpSecretKey.text = config.secretKey ?? '••••••••';
          _paysharpApiKeyObscured = true;
          _paysharpSecretKeyObscured = true; // API Token: hidden by default, show via view icon
        } else {
          _paysharpApiKey.text = '';
          _paysharpSecretKey.text = '';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paysharpLoading = false;
        _paysharpError = e.toString().replaceAll('IntegrationsException: ', '');
      });
    }
  }

  @override
  void dispose() {
    _emailHost.dispose();
    _emailPort.dispose();
    _emailUsername.dispose();
    _emailPassword.dispose();
    _emailFrom.dispose();
    _emailFromName.dispose();
    _paysharpApiKey.dispose();
    _paysharpSecretKey.dispose();
    _paysharpMerchantId.dispose();
    _paysharpApiBaseUrl.dispose();
    _paypalClientId.dispose();
    _paypalClientSecret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Integrations',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure email delivery and payment gateway settings.',
            style: TextStyle(
              fontSize: 13,
              color: context.textMutedColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTabs(),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selectedSection == 0
                ? _buildEmailSection()
                : _selectedSection == 1
                    ? _buildPaysharpSection()
                    : _buildPayPalSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs() {
    final tabs = [
      (label: 'Email', icon: Icons.email_rounded),
      (label: 'Paysharp', icon: Icons.payments_rounded),
      (label: 'PayPal', icon: Icons.payment_rounded),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _selectedSection == i;
          final tab = tabs[i];
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedSection = i),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? context.accentColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: selected
                        ? Border.all(
                            color: context.accentColor.withOpacity(0.4),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 18,
                        color: selected
                            ? context.accentColor
                            : context.textMutedColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? context.accentColor
                              : context.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmailSection() {
    return Container(
      key: const ValueKey<int>(0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.email_rounded, color: context.accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Integration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SMTP settings for transactional emails (notifications, payslips, etc.)',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _emailHost,
            label: 'SMTP Host *',
            hint: 'e.g. smtp.gmail.com',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildTextField(
                  controller: _emailPort,
                  label: 'Port *',
                  hint: '587',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildSwitchRow(
                  label: 'Use TLS',
                  value: _emailUseTls,
                  onChanged: (v) => setState(() => _emailUseTls = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailUsername,
            label: 'Username *',
            hint: 'your-email@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildSecretField(
            controller: _emailPassword,
            label: 'Password *',
            hint: '••••••••',
            obscured: _emailPasswordObscured,
            onVisibilityToggle: () => setState(() => _emailPasswordObscured = !_emailPasswordObscured),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailFrom,
            label: 'From Email *',
            hint: 'noreply@bizzpass.in',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailFromName,
            label: 'From Name',
            hint: 'BizzPass',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email settings saved (demo)')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Save Email Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaysharpSection() {
    return Container(
      key: const ValueKey<int>(1),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.payments_rounded, color: context.accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paysharp Payment Gateway',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RBI-authorized payment aggregator for UPI, Virtual Accounts, and payment pages',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_paysharpError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: context.dangerColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_paysharpError!, style: TextStyle(fontSize: 13, color: context.textColor))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_paysharpLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
          if (_paysharpConfigured)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton.icon(
                onPressed: _paysharpLoading
                    ? null
                    : () async {
                        await _loadPaysharpConfig();
                      },
                icon: Icon(Icons.refresh_rounded, size: 18, color: context.accentColor),
                label: Text(
                  'Refresh keys',
                  style: TextStyle(fontSize: 13, color: context.accentColor, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          _buildSecretField(
            controller: _paysharpApiKey,
            label: 'API Key *',
            hint: 'Your Paysharp API key',
            obscured: _paysharpApiKeyObscured,
            onVisibilityToggle: () => setState(() => _paysharpApiKeyObscured = !_paysharpApiKeyObscured),
          ),
          const SizedBox(height: 16),
          _buildSecretField(
            controller: _paysharpSecretKey,
            label: 'API Token *',
            hint: 'Your Paysharp API token (Bearer token)',
            obscured: _paysharpSecretKeyObscured,
            onVisibilityToggle: () => setState(() => _paysharpSecretKeyObscured = !_paysharpSecretKeyObscured),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _paysharpMerchantId,
            label: 'Merchant ID',
            hint: 'Your merchant identifier',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _paysharpApiBaseUrl,
            label: 'API Base URL (optional override)',
            hint: 'e.g. https://api.paysharp.in/v1 (leave blank for default UPI base)',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          _buildSwitchRow(
            label: 'Use Sandbox (Testing)',
            value: _paysharpSandbox,
            onChanged: (v) => setState(() => _paysharpSandbox = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _paysharpSaving
                ? null
                : () async {
                    final apiKey = _paysharpApiKey.text.trim();
                    final apiToken = _paysharpSecretKey.text.trim();
                    final apiTokenIsPlaceholder = apiToken.isEmpty || apiToken == '••••••••';
                    if (apiTokenIsPlaceholder && !_paysharpConfigured) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API Token is required')),
                      );
                      return;
                    }
                    setState(() => _paysharpSaving = true);
                    try {
                      await _repo.savePaysharpConfig(
                        apiKey: apiKey.isNotEmpty ? apiKey : (apiTokenIsPlaceholder ? '' : apiToken),
                        secretKey: apiTokenIsPlaceholder ? null : apiToken,
                        merchantId: _paysharpMerchantId.text.trim().isEmpty ? null : _paysharpMerchantId.text.trim(),
                        sandbox: _paysharpSandbox,
                        apiBaseUrl: _paysharpApiBaseUrl.text.trim().isEmpty ? null : _paysharpApiBaseUrl.text.trim(),
                      );
                      if (!mounted) return;
                      setState(() {
                        _paysharpSaving = false;
                        _paysharpError = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Paysharp settings saved securely (encrypted in database)')),
                      );
                      await _loadPaysharpConfig();
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _paysharpSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('IntegrationsException: ', '')),
                          backgroundColor: context.dangerColor,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _paysharpSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Paysharp Settings'),
          ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayPalSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_rounded, size: 28, color: context.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PayPal',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    Text(
                      'Enable PayPal Checkout for subscription and one-time payments',
                      style: TextStyle(fontSize: 12, color: context.textMutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_paypalError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: context.dangerColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_paypalError!, style: TextStyle(fontSize: 13, color: context.textColor))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_paypalLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          if (!_paypalLoading) ...[
            _buildTextField(
              controller: _paypalClientId,
              label: 'Client ID *',
              hint: 'Your PayPal REST API Client ID',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _paypalClientSecret,
              label: 'Client Secret *',
              hint: 'Your PayPal REST API Client Secret',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _paypalSaving
                  ? null
                  : () async {
                      final clientId = _paypalClientId.text.trim();
                      final clientSecret = _paypalClientSecret.text.trim();
                      if (clientId.isEmpty || clientSecret.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Client ID and Client Secret are required')),
                        );
                        return;
                      }
                      setState(() {
                        _paypalSaving = true;
                        _paypalError = null;
                      });
                      try {
                        await _repo.savePayPalConfig(clientId: clientId, clientSecret: clientSecret);
                        if (!mounted) return;
                        setState(() {
                          _paypalSaving = false;
                          _paypalConfigured = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PayPal settings saved')),
                        );
                        await _loadPayPalConfig();
                      } catch (e) {
                        if (!mounted) return;
                        setState(() {
                          _paypalSaving = false;
                          _paypalError = e.toString().replaceAll('IntegrationsException: ', '');
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _paypalSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save PayPal Settings'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14, color: context.textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textMutedColor, fontSize: 13),
            filled: true,
            fillColor: context.bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.accentColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecretField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required bool obscured,
    required VoidCallback onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscured,
          style: TextStyle(fontSize: 14, color: context.textColor),
          decoration: InputDecoration(
            hintText: hint ?? '••••••••',
            hintStyle: TextStyle(color: context.textMutedColor, fontSize: 13),
            filled: true,
            fillColor: context.bgColor,
            suffixIcon: IconButton(
              icon: Icon(
                obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                size: 20,
                color: context.textMutedColor,
              ),
              onPressed: onVisibilityToggle,
              tooltip: obscured ? 'Show' : 'Hide',
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.accentColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textColor,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: context.accentColor.withOpacity(0.5),
          activeThumbColor: context.accentColor,
        ),
      ],
    );
  }
}
