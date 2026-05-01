import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../services/payment_service.dart';
import '../../services/payment_customer_service.dart';
import '../../widgets/payments/payment_customer_form.dart';

class DonationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> configData;

  const DonationDetailsScreen({super.key, required this.configData});

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  final PaymentService _paymentService = PaymentService();
  final PaymentCustomerService _paymentCustomerService = PaymentCustomerService();
  final TextEditingController _customAmountController = TextEditingController();

  final List<double> _suggestedAmounts = [20, 50, 100, 200];
  double? _selectedAmount;
  bool _isRecurring = false;
  String _method = 'pix';
  bool _isProcessing = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  double? _resolveAmount() {
    if (_selectedAmount != null) return _selectedAmount;
    final raw = _customAmountController.text.trim();
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _startPayment() async {
    final loc = AppLocalizations.of(context)!;
    final amount = _resolveAmount();
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.donationInvalidAmount), backgroundColor: Colors.red),
      );
      return;
    }

    final receiverId = widget.configData['receiverId'] as String?;
    if (receiverId == null || receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.donationPaymentNotConfigured), backgroundColor: Colors.red),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.unauthenticatedUser), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      Map<String, dynamic> customerData =
          await _paymentCustomerService.getCustomerData(user.uid);
      final missingFields = PaymentCustomerService.getMissingFields(
        customerData,
        requireCityIbge: _isRecurring,
      );

      if (missingFields.isNotEmpty) {
        final result = await showPaymentCustomerForm(
          context: context,
          initialData: customerData,
          missingFields: missingFields,
        );
        if (result == null) {
          setState(() => _isProcessing = false);
          return;
        }
        customerData = result.data;
        await _paymentCustomerService.saveCustomerData(user.uid, customerData);
      }

      final paymentAccountId = widget.configData['paymentAccountId'] as String?;

      final session = await _paymentService.createDonationPayment(
        amount: amount,
        currency: 'BRL',
        method: _method,
        isRecurring: _isRecurring,
        receiverId: receiverId,
        paymentAccountId: paymentAccountId,
        customerData: customerData,
      );

      if (session.checkoutUrl == null || session.checkoutUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.donationPaymentNotConfigured), backgroundColor: Colors.red),
        );
        return;
      }

      final uri = Uri.parse(session.checkoutUrl!);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.somethingWentWrong), backgroundColor: Colors.red),
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.donationPaymentPending)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.somethingWentWrong}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final configData = widget.configData;

    final String screenTitle = configData['sectionTitle'] ?? 'Faça sua Doação';
    final String description = configData['description'] ?? '';
    final String imageUrl = configData['imageUrl'] ?? '';
    final List<dynamic> bankAccountsRaw = configData['bankAccounts'] ?? [];
    final String bankAccountsText = bankAccountsRaw.cast<String>().join('\n\n');
    final List<dynamic> pixKeysRaw = configData['pixKeys'] ?? [];
    final List<Map<String, String>> pixKeys = pixKeysRaw
        .map((item) => Map<String, String>.from(item as Map))
        .toList();

    String? qrPixKey;
    final cnpjKey = pixKeys.firstWhere((k) => k['type'] == 'CNPJ', orElse: () => {});
    if (cnpjKey.isNotEmpty) {
      qrPixKey = cnpjKey['key'];
    } else if (pixKeys.isNotEmpty) {
      qrPixKey = pixKeys.first['key'];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.error_outline, size: 40)),
                  ),
                ),
              ),
            if (imageUrl.isNotEmpty) const SizedBox(height: AppSpacing.xl),

            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(description, style: Theme.of(context).textTheme.bodyLarge),
              ),

            _buildDonationCard(context),

            const SizedBox(height: AppSpacing.xl),

            if (bankAccountsText.isNotEmpty) ...[
              Text('Contas Bancárias', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(bankAccountsText, style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            if (pixKeys.isNotEmpty || (qrPixKey != null && qrPixKey.isNotEmpty)) ...[
              Text('Doe com Pix', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.md),
              if (pixKeys.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: const Text('Nenhuma chave Pix configurada.', style: TextStyle(color: Colors.grey)),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pixKeys.length,
                    separatorBuilder: (_, __) => const Divider(height: AppSpacing.md, thickness: 0.5),
                    itemBuilder: (context, index) {
                      final pix = pixKeys[index];
                      final type = pix['type'] ?? 'Desconhecido';
                      final key = pix['key'] ?? '---';
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                                children: [
                                  TextSpan(text: '$type: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                                  TextSpan(text: key, style: const TextStyle(fontWeight: FontWeight.normal)),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
                            tooltip: 'Copiar Chave',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: key));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chave Pix copiada!'), duration: Duration(seconds: 2)),
                              );
                            },
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              if (qrPixKey != null && qrPixKey.isNotEmpty)
                Center(
                  child: Column(
                    children: [
                      Text('Ou escaneie o QR Code:', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5, spreadRadius: 1)],
                        ),
                        child: QrImageView(
                          data: qrPixKey,
                          version: QrVersions.auto,
                          size: 220.0,
                          gapless: false,
                          errorStateBuilder: (cxt, err) {
                            return const Center(
                              child: Text(
                                "Ops! Erro ao gerar QR Code.",
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Abra seu app do banco e escaneie o QR Code ou use Copiar e Colar.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.donateNow,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(loc.donationAmount, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedAmounts.map((amount) {
              final isSelected = _selectedAmount == amount;
              return ChoiceChip(
                label: Text('R\$ ${amount.toStringAsFixed(0)}'),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedAmount = amount;
                    _customAmountController.text = '';
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _selectedAmount = null),
            decoration: InputDecoration(
              labelText: loc.donationCustomAmount,
              prefixText: 'R\$ ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(loc.donationFrequency, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(loc.donationOneTime),
                  selected: !_isRecurring,
                  onSelected: (_) => setState(() => _isRecurring = false),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text(loc.donationRecurring),
                  selected: _isRecurring,
                  onSelected: (_) => setState(() {
                    _isRecurring = true;
                    _method = 'card';
                  }),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(loc.donationMethod, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(loc.donationMethodPix),
                  selected: _method == 'pix',
                  onSelected: _isRecurring ? null : (_) => setState(() => _method = 'pix'),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text(loc.donationMethodCard),
                  selected: _method == 'card',
                  onSelected: (_) => setState(() => _method = 'card'),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _isProcessing ? null : _startPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(loc.donationContinueToPayment),
          ),
        ],
      ),
    );
  }
}
