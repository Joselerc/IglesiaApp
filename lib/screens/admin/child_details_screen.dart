import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/child_model.dart';
import '../../models/user_model.dart'; // Para lista de responsables
import '../../models/family_model.dart'; // Para obtener responsables de la familia
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import './create_edit_child_screen.dart'; // Para navegar a editar
import '../../models/checkin_record_model.dart'; // <-- AÑADIR IMPORT

class ChildDetailsScreen extends StatefulWidget {
  final String childId;
  final String familyId; // Necesario para buscar los responsables de la familia

  const ChildDetailsScreen({super.key, required this.childId, required this.familyId});

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {

  String _calculateAge(Timestamp? birthDate) {
    if (birthDate == null) return '';
    final birth = birthDate.toDate();
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age > 0 ? '$age anos' : (age == 0 ? 'Menos de 1 ano' : '');
  }

  String _getInitials(String name) {
      String initials = '';
      if (name.isNotEmpty) {
        final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          initials = parts.first[0];
          if (parts.length > 1) initials += parts.last[0];
        }
      } else {
        initials = '?';
      }
      return initials.toUpperCase();
  }

  void _navigateToEditChild(String childId, String familyId) {
     Navigator.push(context, MaterialPageRoute(builder: (_) => 
        CreateEditChildScreen(familyId: familyId, childId: childId) // Pasar childId para modo edición
      ));
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $urlString')),
        );
      }
      print('Could not launch $urlString');
    }
  }

  void _showGuardianContactOptions(BuildContext context, UserModel guardian) {
    String? fullPhoneNumber = guardian.phoneComplete;
    if (fullPhoneNumber == null || fullPhoneNumber.trim().isEmpty) {
        if (guardian.phone != null && guardian.phone!.trim().isNotEmpty) {
            String countryCode = guardian.phoneCountryCode ?? '+55';
            if (!countryCode.startsWith('+')) {
                countryCode = '+' + countryCode;
            }
            fullPhoneNumber = countryCode + guardian.phone!.replaceAll(RegExp(r'\D'),'');
        } else {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Número de telefone não disponível.')),
            );
            return;
        }
    }
 
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.0,
            left: 16.0, 
            right: 16.0,
            top: 16.0,
          ),
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                title: const Text('Ligar'),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchURL('tel:$fullPhoneNumber');
                },
              ),
              ListTile(
                leading: const Icon(Icons.message_outlined, color: Colors.green),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchURL('https://api.whatsapp.com/send?phone=$fullPhoneNumber');
                },
              ),
               ListTile(
                leading: const Icon(Icons.close, color: AppColors.textSecondary),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- NUEVO HELPER PARA FORMATEAR RANGO ETARIO ---
  String _formatAgeRangeForDisplay(String? ageRangeString) {
    if (ageRangeString == null || ageRangeString.trim().isEmpty) return 'N/A';
    String range = ageRangeString.toLowerCase().trim();

    if (range == 'berçário') return '0-1 anos'; // O el rango que prefieras para Berçário
    
    // Intenta extraer números para "X a Y anos" o "Sala X a Y anos"
    RegExp patternCombined = RegExp(r'(\d+)\s*a\s*(\d+)'); // Más general
    Match? matchCombined = patternCombined.firstMatch(range);
    if (matchCombined != null) {
      return '${matchCombined.group(1)!}-${matchCombined.group(2)!} anos';
    }
    
    // Intenta extraer número para "Sala X anos" o "X anos"
    RegExp patternSingle = RegExp(r'(\d+)\s*anos');
    Match? matchSingle = patternSingle.firstMatch(range);
    if (matchSingle != null) {
      return '${matchSingle.group(1)!} anos';
    }
    
    return ageRangeString; // Devolver original si no coincide con formatos esperados
  }
  // --- FIN HELPER ---

  Widget _buildAttendanceHistory(String childId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('checkinRecords')
          .where('childId', isEqualTo: childId)
          .orderBy('checkinTime', descending: true)
          .limit(20) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (snapshot.hasError) {
          return Padding(padding: const EdgeInsets.all(16.0), child: Text('Erro ao carregar assistência: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(padding: EdgeInsets.all(16.0), child: Text('Nenhum registro de assistência encontrado.'));
        }

        final records = snapshot.data!.docs.map((doc) => CheckinRecordModel.fromFirestore(doc)).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final record = records[index];
            
            String programacaoNome = record.scheduledRoomDescription ?? record.scheduledRoomId ?? 'Programação Desconhecida';
            
            String formattedAgeRange = _formatAgeRangeForDisplay(record.childAgeRangeAtCheckin);

            String dayOfWeek = DateFormat('E', 'pt_BR').format(record.checkinTime.toDate());
            String dateShort = DateFormat('dd', 'pt_BR').format(record.checkinTime.toDate());
            String formattedCheckinDay = '$dateShort - $dayOfWeek';

            String checkinTimeFormatted = DateFormat('HH:mm').format(record.checkinTime.toDate());
            String checkoutTimeFormatted = record.checkoutTime != null ? DateFormat('HH:mm').format(record.checkoutTime!.toDate()) : '-';
            String timeDetails = '$checkinTimeFormatted às $checkoutTimeFormatted';
            if (record.checkoutTime == null) {
                timeDetails = 'Check-in: $checkinTimeFormatted - Ainda na sala';
            }
            String statusText = record.checkoutTime != null ? "Encerrada" : "Aberta";

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70, 
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        formattedAgeRange, 
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(programacaoNome, style: AppTextStyles.bodyText1?.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(timeDetails, style: AppTextStyles.caption.copyWith(color: AppTextStyles.caption.color?.withOpacity(0.8) ?? AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(formattedCheckinDay, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 11)),
                      Text(statusText, style: AppTextStyles.caption.copyWith(color: record.checkoutTime != null ? Colors.orange.shade700 : Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('children').doc(widget.childId).snapshots(),
      builder: (context, childSnapshot) {
        if (childSnapshot.connectionState == ConnectionState.waiting && !childSnapshot.hasData) {
            // Mostrar AppBar genérica mientras carga la primera vez
            return Scaffold(
              appBar: AppBar(
                title: const Text('Carregando Criança...'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
        }
        if (!childSnapshot.hasData || !childSnapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Erro'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('Criança não encontrada.')),
          );
        }
        
        // Ahora tenemos datos, podemos construir la UI completa
        final child = ChildModel.fromFirestore(childSnapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: Text('${child.firstName} ${child.lastName}'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ), 
          backgroundColor: AppColors.background, // Color de fondo para toda la pantalla
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  backgroundImage: child.photoUrl != null && child.photoUrl!.isNotEmpty 
                      ? NetworkImage(child.photoUrl!) 
                      : null,
                  child: child.photoUrl == null || child.photoUrl!.isEmpty
                      ? Text(_getInitials('${child.firstName} ${child.lastName}'), 
                          style: AppTextStyles.subtitle1.copyWith(fontSize: 30, color: AppColors.secondary, fontWeight: FontWeight.bold)
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text('${child.firstName} ${child.lastName}', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '${child.gender ?? "Não informado"}',
                  style: AppTextStyles.bodyText1?.copyWith(color: AppColors.textSecondary)
                ),
                Text(
                  'Nascimento: ${child.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(child.dateOfBirth.toDate()) : "Não informada"} (${_calculateAge(child.dateOfBirth)})',
                  style: AppTextStyles.bodyText1?.copyWith(color: AppColors.textSecondary)
                ),
                const SizedBox(height: 24),
                
                if (child.notes != null && child.notes!.isNotEmpty)
                  _buildSectionWithContent('Observações', child.notes!),
                if (child.allergies != null && child.allergies!.isNotEmpty)
                   _buildSectionWithContent('Restrições Dietéticas', child.allergies!),
                if (child.medicalNotes != null && child.medicalNotes!.isNotEmpty)
                   _buildSectionWithContent('Necessidades Específicas', child.medicalNotes!),
                
                const SizedBox(height: 16),
                _buildFamilyGuardiansSection(widget.familyId),
                
                const SizedBox(height: 16),
                ExpansionTile(
                  title: Text('Assistência', style: AppTextStyles.subtitle1?.copyWith(fontWeight: FontWeight.bold)),
                  initiallyExpanded: true,
                  children: [_buildAttendanceHistory(child.id)],
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: Text('EDITAR', style: AppTextStyles.button.copyWith(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, 
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _navigateToEditChild(child.id, child.familyId),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionWithContent(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subtitle1?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(content, style: AppTextStyles.bodyText1),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyGuardiansSection(String familyId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('families').doc(familyId).get(),
      builder: (context, familySnap) {
        if (!familySnap.hasData) return const SizedBox.shrink();
        final family = FamilyModel.fromFirestore(familySnap.data!);
        if (family.guardianUserIds.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Responsáveis da Família', style: AppTextStyles.subtitle1?.copyWith(fontWeight: FontWeight.bold)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: family.guardianUserIds.length,
              itemBuilder: (context, index) {
                final userId = family.guardianUserIds[index];
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox.shrink();
                    final user = UserModel.fromMap(userSnapshot.data!.data() as Map<String, dynamic>);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty) ? NetworkImage(user.photoUrl!) : null,
                          child: (user.photoUrl == null || user.photoUrl!.isEmpty) ? Text(_getInitials(user.displayName ?? '')) : null,
                        ),
                        title: Text(user.displayName ?? 'Nome não disponível'),
                        subtitle: Text('${user.phoneCountryCode ?? ''} ${user.phone ?? ''}\n${user.email}'),
                        isThreeLine: true,
                        onTap: () {
                          _showGuardianContactOptions(context, user);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
} 