import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive_size.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/business.dart';
import '../../modules/business_type.dart';
import '../../providers/business_provider.dart';
import '../main_layout_screen.dart';

class BusinessSetupWizardScreen extends StatefulWidget {
  final BusinessType? initialType;

  const BusinessSetupWizardScreen({super.key, this.initialType});

  @override
  State<BusinessSetupWizardScreen> createState() => _BusinessSetupWizardScreenState();
}

class _BusinessSetupWizardScreenState extends State<BusinessSetupWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  late BusinessType _selectedType;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _taxCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _currencyCtrl = TextEditingController(text: '₹');
  final TextEditingController _prefixCtrl = TextEditingController(text: 'INV-');
  double _defaultTaxRate = 5.0;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? BusinessType.grocery;
    _nameCtrl.text = 'My ${_selectedType.displayName}';
    _setDefaultsForType(_selectedType);
  }

  void _setDefaultsForType(BusinessType type) {
    switch (type) {
      case BusinessType.medical:
        _prefixCtrl.text = 'MED-';
        _defaultTaxRate = 12.0;
        break;
      case BusinessType.restaurant:
        _prefixCtrl.text = 'RES-';
        _defaultTaxRate = 5.0;
        break;
      case BusinessType.grocery:
        _prefixCtrl.text = 'GRO-';
        _defaultTaxRate = 5.0;
        break;
      case BusinessType.supermarket:
        _prefixCtrl.text = 'SUP-';
        _defaultTaxRate = 5.0;
        break;
      case BusinessType.electronics:
        _prefixCtrl.text = 'ELC-';
        _defaultTaxRate = 18.0;
        break;
      case BusinessType.garment:
        _prefixCtrl.text = 'GAR-';
        _defaultTaxRate = 12.0;
        break;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taxCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _currencyCtrl.dispose();
    _prefixCtrl.dispose();
    super.dispose();
  }

  void _saveBusiness() async {
    if (_formKey.currentState!.validate()) {
      final bizProv = context.read<BusinessProvider>();
      final newBiz = Business(
        id: _uuid.v4(),
        name: _nameCtrl.text.trim(),
        type: _selectedType,
        taxNumber: _taxCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        currencySymbol: _currencyCtrl.text.trim(),
        invoicePrefix: _prefixCtrl.text.trim(),
        defaultTaxRate: _defaultTaxRate,
      );

      await bizProv.createBusiness(newBiz);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Setup Wizard'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.widthPct(3.5).clamp(12.0, 24.0)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text(
                  'Set Up Your Store Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Configure basic details for invoice headers, taxes, and receipt footers.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: AppTokens.spaceXL),
                // Store Type Selector
                const Text('Store Business Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BusinessType.values.map((type) {
                    final isSel = _selectedType == type;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type.icon, size: 16, color: isSel ? Colors.white : type.primaryColor),
                          const SizedBox(width: 6),
                          Text(type.displayName),
                        ],
                      ),
                      selected: isSel,
                      selectedColor: type.primaryColor,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : Colors.black87,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedType = type;
                            _setDefaultsForType(type);
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTokens.spaceLG),
                AppCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Shop / Business Name *',
                          prefixIcon: Icon(Icons.store_rounded),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Please enter a shop name' : null,
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      TextFormField(
                        controller: _taxCtrl,
                        decoration: const InputDecoration(
                          labelText: 'GSTIN / Tax ID Number',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Shop Address',
                          prefixIcon: Icon(Icons.location_on_rounded),
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone_rounded),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceMD),
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.email_rounded),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _currencyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Currency Symbol',
                                prefixIcon: Icon(Icons.currency_exchange_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceMD),
                          Expanded(
                            child: TextFormField(
                              controller: _prefixCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Invoice Prefix',
                                prefixIcon: Icon(Icons.tag_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceMD),
                          Expanded(
                            child: TextFormField(
                              initialValue: _defaultTaxRate.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Tax Rate (%)',
                                suffixText: '%',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                _defaultTaxRate = double.tryParse(val) ?? 5.0;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceXL),
                AppButton(
                  label: 'Launch Store Dashboard',
                  icon: Icons.rocket_launch_rounded,
                  isFullWidth: true,
                  height: 48,
                  onPressed: _saveBusiness,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
