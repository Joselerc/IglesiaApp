import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/announcement_model.dart';
import '../../models/church_location.dart';
import '../../models/cult_song.dart';
import '../../models/prayer.dart';
import '../../models/work_invite.dart';
import '../../services/cult_full_details_service.dart';
import '../../theme/app_colors.dart';

/// Sección que se muestra dentro de WorkInviteDetailScreen cuando la
/// invitación ya está aceptada. Carga todos los detalles del culto
/// (ubicación, programa, equipos, músicas, anuncios y oraciones) en
/// paralelo y los presenta agrupados por bloques. Los bloques con mucha
/// información (programa y equipos) están plegados por defecto.
class CultFullDetailsSection extends StatefulWidget {
  final WorkInvite invite;

  const CultFullDetailsSection({super.key, required this.invite});

  @override
  State<CultFullDetailsSection> createState() => _CultFullDetailsSectionState();
}

class _CultFullDetailsSectionState extends State<CultFullDetailsSection> {
  final CultFullDetailsService _service = CultFullDetailsService();
  late Future<CultFullDetails?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadAll(
      cultId: widget.invite.entityId,
      myTimeSlotId:
          widget.invite.timeSlotId.isNotEmpty ? widget.invite.timeSlotId : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CultFullDetails?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        return _buildContent(data);
      },
    );
  }

  Widget _buildContent(CultFullDetails data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CultHeaderCard(
          name: data.cult.name,
          serviceName: data.service?.name,
          date: data.cult.date,
          startTime: data.cult.startTime,
          endTime: data.cult.endTime,
        ),
        const SizedBox(height: 16),
        if (data.location != null || data.embeddedLocation != null) ...[
          _LocationCard(
            location: data.location,
            embedded: data.embeddedLocation,
          ),
          const SizedBox(height: 16),
        ],
        _MyAssignmentCard(invite: widget.invite, myTimeSlot: data.myTimeSlot),
        const SizedBox(height: 16),
        if (data.timeSlots.isNotEmpty) ...[
          _ProgramTimelineCard(timeSlots: data.timeSlots),
          const SizedBox(height: 16),
          _MinistriesTeamsCard(
            timeSlots: data.timeSlots,
            currentUserId: widget.invite.userId,
          ),
          const SizedBox(height: 16),
        ],
        if (data.songs.isNotEmpty) ...[
          _SongsCard(songs: data.songs),
          const SizedBox(height: 16),
        ],
        if (data.announcements.isNotEmpty) ...[
          _AnnouncementsCard(announcements: data.announcements),
          const SizedBox(height: 16),
        ],
        if (data.prayers.isNotEmpty) ...[
          _PrayersCard(prayers: data.prayers),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// ============================================================================
// Helpers de estilo (alineados con la pantalla actual: cards blancas redondas)
// ============================================================================

Widget _sectionCard({
  required IconData icon,
  required Color iconColor,
  required String title,
  String? subtitle,
  required Widget child,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _ExpandableSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget child;

  const _ExpandableSectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            title: Text(
              title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: subtitle == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
            children: [child],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 1. Cabecera del culto
// ============================================================================

class _CultHeaderCard extends StatelessWidget {
  final String name;
  final String? serviceName;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;

  const _CultHeaderCard({
    required this.name,
    required this.serviceName,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM, yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');
    return _sectionCard(
      icon: Icons.church_rounded,
      iconColor: Colors.blue,
      title: name.isEmpty ? 'Culto' : name,
      subtitle: serviceName,
      child: Column(
        children: [
          _kvRow(
            icon: Icons.calendar_today_rounded,
            text: dateFormat.format(date),
          ),
          const SizedBox(height: 12),
          _kvRow(
            icon: Icons.access_time_rounded,
            text: '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. Ubicación
// ============================================================================

class _LocationCard extends StatelessWidget {
  final ChurchLocation? location;
  final Map<String, String>? embedded;

  const _LocationCard({this.location, this.embedded});

  @override
  Widget build(BuildContext context) {
    final name = location?.name ?? embedded?['name'] ?? 'Ubicación';
    final address = location?.fullAddress ?? _buildEmbeddedAddress(embedded);
    return _sectionCard(
      icon: Icons.place_rounded,
      iconColor: Colors.red,
      title: name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address.isNotEmpty)
            _kvRow(icon: Icons.location_on_outlined, text: address),
        ],
      ),
    );
  }

  String _buildEmbeddedAddress(Map<String, String>? e) {
    if (e == null) return '';
    final parts = [
      e['street'] ?? e['address'] ?? '',
      (e['number'] ?? '').isNotEmpty ? 'nº ${e['number']}' : '',
      e['neighborhood'] ?? '',
      e['city'] ?? '',
      e['state'] ?? '',
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }
}

// ============================================================================
// 3. Mi servicio destacado
// ============================================================================

class _MyAssignmentCard extends StatelessWidget {
  final WorkInvite invite;
  final dynamic myTimeSlot; // TimeSlot? - dynamic para evitar import circular

  const _MyAssignmentCard({required this.invite, this.myTimeSlot});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    String slotText = '';
    if (myTimeSlot != null) {
      final start = timeFormat.format(myTimeSlot.startTime as DateTime);
      final end = timeFormat.format(myTimeSlot.endTime as DateTime);
      final slotName = (myTimeSlot.name as String?) ?? '';
      slotText = slotName.isNotEmpty
          ? '$slotName · $start - $end'
          : '$start - $end';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.10),
            AppColors.primary.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star_rounded,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tu servicio en este culto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _kvRow(
            icon: Icons.groups_rounded,
            label: 'Ministério',
            text: invite.ministryName,
          ),
          const SizedBox(height: 12),
          _kvRow(
            icon: Icons.person_pin_rounded,
            label: 'Papel',
            text: invite.role,
          ),
          if (slotText.isNotEmpty) ...[
            const SizedBox(height: 12),
            _kvRow(
              icon: Icons.schedule_rounded,
              label: 'Sua franja horária',
              text: slotText,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 4. Programa completo (todas las franjas)
// ============================================================================

class _ProgramTimelineCard extends StatelessWidget {
  final List<CultTimeSlotSummary> timeSlots;

  const _ProgramTimelineCard({required this.timeSlots});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    return _ExpandableSectionCard(
      icon: Icons.event_note_rounded,
      iconColor: Colors.indigo,
      title: 'Programa do culto',
      subtitle: '${timeSlots.length} franjas',
      child: Column(
        children: timeSlots.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value.timeSlot;
          final isLast = i == timeSlots.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name.isEmpty ? 'Franja' : s.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${timeFormat.format(s.startTime)} - ${timeFormat.format(s.endTime)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (s.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          s.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// 5. Equipos: ministerios + roles + personas
// ============================================================================

class _MinistriesTeamsCard extends StatelessWidget {
  final List<CultTimeSlotSummary> timeSlots;
  final String currentUserId;

  const _MinistriesTeamsCard({
    required this.timeSlots,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final totalMinistries = timeSlots
        .expand((ts) => ts.ministries.map((m) => m.ministryId))
        .toSet()
        .length;
    final totalPeople = timeSlots
        .expand((ts) => ts.ministries.expand((m) =>
            m.roles.expand((r) => r.people.map((p) => p.userId))))
        .toSet()
        .length;

    return _ExpandableSectionCard(
      icon: Icons.diversity_3_rounded,
      iconColor: Colors.teal,
      title: 'Equipes',
      subtitle: '$totalMinistries ministérios · $totalPeople pessoas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: timeSlots.map((tsSum) {
          if (tsSum.ministries.isEmpty) return const SizedBox.shrink();
          return _buildTimeSlotBlock(tsSum);
        }).toList(),
      ),
    );
  }

  Widget _buildTimeSlotBlock(CultTimeSlotSummary tsSum) {
    final timeFormat = DateFormat('HH:mm');
    final slotLabel = tsSum.timeSlot.name.isNotEmpty
        ? '${tsSum.timeSlot.name} · ${timeFormat.format(tsSum.timeSlot.startTime)} - ${timeFormat.format(tsSum.timeSlot.endTime)}'
        : '${timeFormat.format(tsSum.timeSlot.startTime)} - ${timeFormat.format(tsSum.timeSlot.endTime)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slotLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...tsSum.ministries.map(_buildMinistryBlock),
        ],
      ),
    );
  }

  Widget _buildMinistryBlock(CultMinistrySummary m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_2_rounded,
                  size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  m.ministryName.isEmpty ? 'Ministério' : m.ministryName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...m.roles.map(_buildRoleBlock),
        ],
      ),
    );
  }

  Widget _buildRoleBlock(CultMinistryRoleSummary r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.role,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: r.currentCount >= r.capacity && r.capacity > 0
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${r.currentCount}/${r.capacity}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: r.currentCount >= r.capacity && r.capacity > 0
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (r.people.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Sem pessoas designadas',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: r.people.map(_buildPersonChip).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonChip(CultAssignedPerson p) {
    final isMe = p.userId == currentUserId;
    final statusColor = _statusColor(p.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.10) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? AppColors.primary : Colors.grey.shade300,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                p.photoUrl != null && p.photoUrl!.isNotEmpty
                    ? NetworkImage(p.photoUrl!)
                    : null,
            child: p.photoUrl == null || p.photoUrl!.isEmpty
                ? Icon(Icons.person, size: 12, color: Colors.grey.shade600)
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            p.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
              color: isMe ? AppColors.primary : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      case 'seen':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ============================================================================
// 6. Repertorio musical (con botones Abrir / Descargar)
// ============================================================================

class _SongsCard extends StatelessWidget {
  final List<CultSong> songs;
  const _SongsCard({required this.songs});

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      icon: Icons.library_music_rounded,
      iconColor: Colors.deepPurple,
      title: 'Repertório musical',
      subtitle: '${songs.length} músicas',
      child: Column(
        children: songs.asMap().entries.map((entry) {
          final i = entry.key;
          final song = entry.value;
          final isLast = i == songs.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: _buildSongTile(context, song, i + 1),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, CultSong song, int index) {
    final mm = (song.duration ~/ 60).toString().padLeft(2, '0');
    final ss = (song.duration % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (song.duration > 0)
                      Text(
                        '$mm:$ss',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (song.files.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: song.files.map((f) {
                final isAudio = f.fileType == 'audio' || f.fileType == 'mp3';
                return OutlinedButton.icon(
                  onPressed: () => _openUrl(context, f.fileUrl),
                  icon: Icon(
                    isAudio
                        ? Icons.play_circle_outline_rounded
                        : Icons.picture_as_pdf_rounded,
                    size: 16,
                  ),
                  label: Text(
                    f.name,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    foregroundColor: Colors.deepPurple.shade700,
                    side: BorderSide(color: Colors.deepPurple.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o arquivo')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o arquivo')),
        );
      }
    }
  }
}

// ============================================================================
// 7. Anuncios del culto
// ============================================================================

class _AnnouncementsCard extends StatelessWidget {
  final List<AnnouncementModel> announcements;
  const _AnnouncementsCard({required this.announcements});

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      icon: Icons.campaign_rounded,
      iconColor: Colors.orange,
      title: 'Avisos do culto',
      subtitle: '${announcements.length}',
      child: Column(
        children: announcements.map(_buildAnnouncementTile).toList(),
      ),
    );
  }

  Widget _buildAnnouncementTile(AnnouncementModel a) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                dateFormat.format(a.date),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
          if (a.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              a.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ],
          if (a.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                a.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 8. Oraciones públicas asignadas al culto
// ============================================================================

class _PrayersCard extends StatelessWidget {
  final List<Prayer> prayers;
  const _PrayersCard({required this.prayers});

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      icon: Icons.volunteer_activism_rounded,
      iconColor: Colors.pink,
      title: 'Pedidos de oração',
      subtitle: '${prayers.length}',
      child: Column(
        children: prayers.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded,
                    color: Colors.pink.shade300, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// Filas reutilizables
// ============================================================================

Widget _kvRow({
  required IconData icon,
  String? label,
  required String text,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Colors.grey.shade600),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ],
  );
}
