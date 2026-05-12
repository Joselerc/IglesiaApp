import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class DonationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> configData;

  const DonationDetailsScreen({super.key, required this.configData});

  @override
  Widget build(BuildContext context) {
    print("🔍 DonationDetailsScreen build: Received configData: $configData");

    // Extraer datos de forma segura
    final String screenTitle = configData['sectionTitle'] ?? 'Faça sua Doação';
    final String description = configData['description'] ?? '';
    final String imageUrl = configData['imageUrl'] ?? '';
    final List<dynamic> bankAccountsRaw = configData['bankAccounts'] ?? [];
    final String bankAccountsText = bankAccountsRaw.cast<String>().join('\n\n');
    final List<dynamic> pixKeysRaw = configData['pixKeys'] ?? [];
    final List<Map<String, String>> pixKeys = pixKeysRaw
        .map((item) => Map<String, String>.from(item as Map))
        .toList();

    // Seleccionar clave Pix para el QR Code
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
            // Imagen (Opcional)
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
                      child: const Center(child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.error_outline, size: 40)),
                  ),
                ),
              ),
            if (imageUrl.isNotEmpty) const SizedBox(height: AppSpacing.xl),

            // Descripción (Opcional)
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(description, style: Theme.of(context).textTheme.bodyLarge),
              ),

            // Contas Bancárias (Opcional)
            if (bankAccountsText.isNotEmpty) ...[
              Text('Contas Bancárias', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  border: Border.all(color: Colors.grey.shade300)
                ),
                child: SelectableText(bankAccountsText, style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Seção Pix
            if (pixKeys.isNotEmpty || (qrPixKey != null && qrPixKey.isNotEmpty)) ...[
              Text('Doe com Pix', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.md),

              // Lista de Chaves Pix
              if (pixKeys.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: const Text('Nenhuma chave Pix configurada.', style: TextStyle(color: Colors.grey))
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

              // QR Code (si hay alguna clave)
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
}
