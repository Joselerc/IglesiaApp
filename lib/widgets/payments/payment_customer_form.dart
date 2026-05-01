import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class PaymentCustomerFormResult {
  final Map<String, dynamic> data;

  const PaymentCustomerFormResult(this.data);
}

Future<PaymentCustomerFormResult?> showPaymentCustomerForm({
  required BuildContext context,
  required Map<String, dynamic> initialData,
  required Set<String> missingFields,
}) {
  return showModalBottomSheet<PaymentCustomerFormResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return PaymentCustomerForm(
        initialData: initialData,
        missingFields: missingFields,
      );
    },
  );
}

class PaymentCustomerForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Set<String> missingFields;

  const PaymentCustomerForm({
    super.key,
    required this.initialData,
    required this.missingFields,
  });

  @override
  State<PaymentCustomerForm> createState() => _PaymentCustomerFormState();
}

class _PaymentCustomerFormState extends State<PaymentCustomerForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _identityController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _zipCodeController;
  late final TextEditingController _streetController;
  late final TextEditingController _numberController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _cityIbgeController;
  late final TextEditingController _complementController;

  @override
  void initState() {
    super.initState();
    final address = Map<String, dynamic>.from(widget.initialData['address'] ?? {});
    _nameController =
        TextEditingController(text: (widget.initialData['name'] ?? '').toString());
    _identityController =
        TextEditingController(text: (widget.initialData['identity'] ?? '').toString());
    _emailController =
        TextEditingController(text: (widget.initialData['email'] ?? '').toString());
    _phoneController =
        TextEditingController(text: (widget.initialData['phone'] ?? '').toString());
    _zipCodeController =
        TextEditingController(text: (address['zipCode'] ?? '').toString());
    _streetController =
        TextEditingController(text: (address['street'] ?? '').toString());
    _numberController =
        TextEditingController(text: (address['number'] ?? '').toString());
    _districtController =
        TextEditingController(text: (address['district'] ?? '').toString());
    _cityController =
        TextEditingController(text: (address['cityName'] ?? '').toString());
    _stateController =
        TextEditingController(text: (address['stateInitials'] ?? '').toString());
    _countryController = TextEditingController(
      text: (address['countryName'] ?? 'Brasil').toString(),
    );
    _cityIbgeController =
        TextEditingController(text: (widget.initialData['cityIbge'] ?? '').toString());
    _complementController =
        TextEditingController(text: (address['complement'] ?? '').toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _zipCodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _cityIbgeController.dispose();
    _complementController.dispose();
    super.dispose();
  }

  bool _needsField(String key) => widget.missingFields.contains(key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.paymentDataTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  loc.paymentDataSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_needsField('name'))
                  _buildTextField(
                    controller: _nameController,
                    label: loc.name,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('identity'))
                  _buildTextField(
                    controller: _identityController,
                    label: loc.paymentIdentityLabel,
                    hint: loc.paymentIdentityHint,
                    keyboardType: TextInputType.number,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('email'))
                  _buildTextField(
                    controller: _emailController,
                    label: loc.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('phone'))
                  _buildTextField(
                    controller: _phoneController,
                    label: loc.phone,
                    keyboardType: TextInputType.phone,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('address.zipCode'))
                  _buildTextField(
                    controller: _zipCodeController,
                    label: loc.postalCode,
                    hint: loc.examplePostalCode,
                    keyboardType: TextInputType.number,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('address.street'))
                  _buildTextField(
                    controller: _streetController,
                    label: loc.street,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('address.number'))
                  _buildTextField(
                    controller: _numberController,
                    label: loc.number,
                    keyboardType: TextInputType.text,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('address.district'))
                  _buildTextField(
                    controller: _districtController,
                    label: loc.neighborhood,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('address.cityName'))
                  _buildTextField(
                    controller: _cityController,
                    label: loc.city,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('address.stateInitials'))
                  _buildTextField(
                    controller: _stateController,
                    label: loc.state,
                    hint: 'Ex: SP',
                    textCapitalization: TextCapitalization.characters,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('address.countryName'))
                  _buildTextField(
                    controller: _countryController,
                    label: loc.country,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('cityIbge'))
                  _buildTextField(
                    controller: _cityIbgeController,
                    label: loc.paymentCityIbgeLabel,
                    hint: loc.paymentCityIbgeHint,
                    keyboardType: TextInputType.number,
                    validator: _requiredValidator(loc),
                  ),
                if (_needsField('address.complement'))
                  _buildTextField(
                    controller: _complementController,
                    label: loc.optional,
                  ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(loc.paymentDataContinue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? Function(String?) _requiredValidator(AppLocalizations loc) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return loc.thisFieldIsRequired;
      }
      return null;
    };
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
      ),
    );
  }

  void _submit() {
    final loc = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseCorrectErrorsBeforeSaving), backgroundColor: Colors.red),
      );
      return;
    }

    final address = {
      'zipCode': _zipCodeController.text.trim(),
      'street': _streetController.text.trim(),
      'number': _numberController.text.trim(),
      'district': _districtController.text.trim(),
      'cityName': _cityController.text.trim(),
      'stateInitials': _stateController.text.trim().toUpperCase(),
      'countryName': _countryController.text.trim(),
      'complement': _complementController.text.trim(),
    };

    final data = {
      'name': _nameController.text.trim(),
      'identity': _identityController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'cityIbge': _cityIbgeController.text.trim(),
      'address': address,
    };

    final merged = Map<String, dynamic>.from(widget.initialData);
    merged.addAll(data);
    merged['address'] = address;

    Navigator.pop(context, PaymentCustomerFormResult(merged));
  }
}
