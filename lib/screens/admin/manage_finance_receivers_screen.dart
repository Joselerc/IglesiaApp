import 'package:flutter/material.dart';
import '../../services/permission_service.dart';
import '../../services/finance_receiver_service.dart';
import '../../models/finance_receiver.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ManageFinanceReceiversScreen extends StatefulWidget {
  const ManageFinanceReceiversScreen({super.key});

  @override
  State<ManageFinanceReceiversScreen> createState() => _ManageFinanceReceiversScreenState();
}

class _ManageFinanceReceiversScreenState extends State<ManageFinanceReceiversScreen> {
  final PermissionService _permissionService = PermissionService();
  final FinanceReceiverService _receiverService = FinanceReceiverService();

  Future<void> _openReceiverForm({FinanceReceiver? receiver}) async {
    final nameController = TextEditingController(text: receiver?.name ?? '');
    final idReceiverController = TextEditingController(text: receiver?.idReceiver ?? '');
    final paymentAccountIdController =
        TextEditingController(text: receiver?.paymentAccountId ?? '');
    bool isActive = receiver?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  receiver == null ? loc.addFinanceAccount : loc.editFinanceAccount,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: loc.financeAccountNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.financeAccountInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: idReceiverController,
                  decoration: InputDecoration(
                    labelText: loc.financeAccountIdReceiverLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.financeAccountInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: paymentAccountIdController,
                  decoration: InputDecoration(
                    labelText: loc.financeAccountPaymentAccountIdLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.financeAccountInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                  title: Text(loc.financeAccountActiveLabel),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    try {
                      if (receiver == null) {
                        await _receiverService.addReceiver(
                          name: nameController.text.trim(),
                          idReceiver: idReceiverController.text.trim(),
                          paymentAccountId: paymentAccountIdController.text.trim(),
                          isActive: isActive,
                        );
                      } else {
                        await _receiverService.updateReceiver(
                          id: receiver.id,
                          name: nameController.text.trim(),
                          idReceiver: idReceiverController.text.trim(),
                          paymentAccountId: paymentAccountIdController.text.trim(),
                          isActive: isActive,
                        );
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.financeAccountSaved), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.financeAccountSaveError), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(loc.save),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessDenied() {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            loc.accessDenied,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            loc.noPermissionAccessPage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.financeAccountsTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_finance_accounts'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (permissionSnapshot.hasError || permissionSnapshot.data == false) {
            return _buildAccessDenied();
          }
          return StreamBuilder<List<FinanceReceiver>>(
            stream: _receiverService.streamReceivers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final receivers = snapshot.data ?? [];
              if (receivers.isEmpty) {
                return Center(
                  child: Text(
                    loc.financeAccountsEmpty,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: receivers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final receiver = receivers[index];
                  return ListTile(
                    leading: Icon(
                      receiver.isActive ? Icons.account_balance_wallet_outlined : Icons.block,
                      color: receiver.isActive ? AppColors.primary : Colors.grey,
                    ),
                    title: Text(receiver.name),
                    subtitle: Text(
                      '${loc.financeAccountIdReceiverLabel}: ${receiver.idReceiver}\n'
                      '${loc.financeAccountPaymentAccountIdLabel}: ${receiver.paymentAccountId}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () => _openReceiverForm(receiver: receiver),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReceiverForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(loc.addFinanceAccount, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
