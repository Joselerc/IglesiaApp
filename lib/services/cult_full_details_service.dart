import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/announcement_model.dart';
import '../models/church_location.dart';
import '../models/cult.dart';
import '../models/cult_song.dart';
import '../models/prayer.dart';
import '../models/service.dart';
import '../models/time_slot.dart';

/// Persona asignada a un rol en una franja del culto
class CultAssignedPerson {
  final String userId;
  final String name;
  final String? photoUrl;
  final String status; // pending, accepted, rejected, seen, confirmed

  CultAssignedPerson({
    required this.userId,
    required this.name,
    required this.status,
    this.photoUrl,
  });
}

/// Rol disponible para un ministerio en una franja, con sus personas asignadas
class CultMinistryRoleSummary {
  final String role;
  final int capacity;
  final int currentCount;
  final List<CultAssignedPerson> people;

  CultMinistryRoleSummary({
    required this.role,
    required this.capacity,
    required this.currentCount,
    required this.people,
  });
}

/// Resumen agrupado por ministerio en una franja
class CultMinistrySummary {
  final String ministryId;
  final String ministryName;
  final List<CultMinistryRoleSummary> roles;

  CultMinistrySummary({
    required this.ministryId,
    required this.ministryName,
    required this.roles,
  });
}

/// Resumen completo de una franja: tiempo + ministerios y sus roles/personas
class CultTimeSlotSummary {
  final TimeSlot timeSlot;
  final List<CultMinistrySummary> ministries;

  CultTimeSlotSummary({required this.timeSlot, required this.ministries});
}

/// Resultado completo con todos los datos del culto
class CultFullDetails {
  final Cult cult;
  final Service? service;
  final ChurchLocation? location;
  final Map<String, String>? embeddedLocation; // si el culto guarda location como map
  final TimeSlot? myTimeSlot;
  final List<CultTimeSlotSummary> timeSlots;
  final List<CultSong> songs;
  final List<AnnouncementModel> announcements;
  final List<Prayer> prayers;

  CultFullDetails({
    required this.cult,
    this.service,
    this.location,
    this.embeddedLocation,
    this.myTimeSlot,
    required this.timeSlots,
    required this.songs,
    required this.announcements,
    required this.prayers,
  });
}

/// Servicio que carga todos los detalles relacionados con un culto en paralelo.
class CultFullDetailsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<CultFullDetails?> loadAll({
    required String cultId,
    String? myTimeSlotId,
  }) async {
    if (cultId.isEmpty) return null;

    final cultDoc = await _firestore.collection('cults').doc(cultId).get();
    if (!cultDoc.exists) return null;
    final cultData = cultDoc.data() as Map<String, dynamic>;
    final cult = Cult.fromFirestore(cultDoc);

    final results = await Future.wait([
      _loadService(cult.serviceId),
      _loadLocation(cultData),
      _loadTimeSlots(cultId),
      _loadSongs(cultId),
      _loadAnnouncements(cultId),
      _loadPrayers(cultId),
      if (myTimeSlotId != null && myTimeSlotId.isNotEmpty)
        _loadSingleTimeSlot(myTimeSlotId)
      else
        Future.value(null),
    ]);

    return CultFullDetails(
      cult: cult,
      service: results[0] as Service?,
      location: (results[1] as _LocationResult).location,
      embeddedLocation: (results[1] as _LocationResult).embedded,
      timeSlots: results[2] as List<CultTimeSlotSummary>,
      songs: results[3] as List<CultSong>,
      announcements: results[4] as List<AnnouncementModel>,
      prayers: results[5] as List<Prayer>,
      myTimeSlot: results[6] as TimeSlot?,
    );
  }

  Future<Service?> _loadService(String serviceId) async {
    if (serviceId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();
      if (!doc.exists) return null;
      return Service.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error cargando service: $e');
      return null;
    }
  }

  Future<_LocationResult> _loadLocation(Map<String, dynamic> cultData) async {
    final locationIdRaw = cultData['locationId'];
    String? locationId;
    if (locationIdRaw is DocumentReference) {
      locationId = locationIdRaw.id;
    } else if (locationIdRaw is String && locationIdRaw.isNotEmpty) {
      locationId = locationIdRaw;
    }

    if (locationId != null) {
      try {
        final doc =
            await _firestore.collection('churchLocations').doc(locationId).get();
        if (doc.exists) {
          return _LocationResult(location: ChurchLocation.fromFirestore(doc));
        }
      } catch (e) {
        debugPrint('Error cargando location: $e');
      }
    }

    final embeddedRaw = cultData['location'];
    if (embeddedRaw is Map) {
      final embedded = <String, String>{};
      embeddedRaw.forEach((key, value) {
        if (value != null) embedded[key.toString()] = value.toString();
      });
      if (embedded.isNotEmpty) {
        return _LocationResult(embedded: embedded);
      }
    }

    return _LocationResult();
  }

  Future<List<CultTimeSlotSummary>> _loadTimeSlots(String cultId) async {
    try {
      final tsSnapshot = await _firestore
          .collection('time_slots')
          .where('entityId', isEqualTo: cultId)
          .where('entityType', isEqualTo: 'cult')
          .where('isActive', isEqualTo: true)
          .get();

      final timeSlots = tsSnapshot.docs
          .map((d) => TimeSlot.fromFirestore(d))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      return Future.wait(timeSlots.map(_buildTimeSlotSummary));
    } catch (e) {
      debugPrint('Error cargando time_slots: $e');
      return [];
    }
  }

  Future<CultTimeSlotSummary> _buildTimeSlotSummary(TimeSlot slot) async {
    final rolesSnapshot = await _firestore
        .collection('available_roles')
        .where('timeSlotId', isEqualTo: slot.id)
        .where('isActive', isEqualTo: true)
        .get();

    // Agrupar roles por ministerio
    final Map<String, _MinistryGroupAccumulator> byMinistry = {};
    for (final doc in rolesSnapshot.docs) {
      final data = doc.data();
      final mIdRaw = data['ministryId'];
      final ministryId =
          mIdRaw is DocumentReference ? mIdRaw.id : (mIdRaw?.toString() ?? '');
      final ministryName = (data['ministryName'] as String?) ?? '';
      final role = (data['role'] as String?) ?? '';
      final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
      final current = (data['current'] as num?)?.toInt() ?? 0;

      final key = ministryId.isNotEmpty ? ministryId : ministryName;
      final acc = byMinistry.putIfAbsent(
        key,
        () => _MinistryGroupAccumulator(
          ministryId: ministryId,
          ministryName: ministryName,
        ),
      );

      final people = await _loadAssignmentsForRole(slot.id, role);
      acc.roles.add(
        CultMinistryRoleSummary(
          role: role,
          capacity: capacity,
          currentCount: current,
          people: people,
        ),
      );
    }

    final ministries = byMinistry.values
        .map((acc) => CultMinistrySummary(
              ministryId: acc.ministryId,
              ministryName: acc.ministryName,
              roles: acc.roles..sort((a, b) => a.role.compareTo(b.role)),
            ))
        .toList()
      ..sort((a, b) => a.ministryName.compareTo(b.ministryName));

    return CultTimeSlotSummary(timeSlot: slot, ministries: ministries);
  }

  Future<List<CultAssignedPerson>> _loadAssignmentsForRole(
    String timeSlotId,
    String role,
  ) async {
    try {
      final snap = await _firestore
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .get();

      final List<CultAssignedPerson> people = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final userRaw = data['userId'];
        final userId = userRaw is DocumentReference
            ? userRaw.id
            : (userRaw?.toString() ?? '');
        final status = (data['status'] as String?) ?? 'pending';
        if (userId.isEmpty) continue;

        final userDoc = await _firestore.collection('users').doc(userId).get();
        String name = 'Usuário';
        String? photoUrl;
        if (userDoc.exists) {
          final ud = userDoc.data() as Map<String, dynamic>;
          name = (ud['displayName'] as String?) ??
              '${ud['name'] ?? ''} ${ud['surname'] ?? ''}'.trim();
          if (name.isEmpty) name = 'Usuário';
          photoUrl = ud['photoUrl'] as String?;
        }
        people.add(CultAssignedPerson(
          userId: userId,
          name: name,
          status: status,
          photoUrl: photoUrl,
        ));
      }
      // Aceptados primero, luego pendientes, luego rechazados
      const order = {'accepted': 0, 'confirmed': 0, 'pending': 1, 'seen': 1, 'rejected': 2};
      people.sort((a, b) =>
          (order[a.status] ?? 3).compareTo(order[b.status] ?? 3));
      return people;
    } catch (e) {
      debugPrint('Error cargando assignments para rol $role: $e');
      return [];
    }
  }

  Future<List<CultSong>> _loadSongs(String cultId) async {
    try {
      final cultRef = _firestore.collection('cults').doc(cultId);
      // Por la inconsistencia conocida del campo cultId (Ref vs String),
      // consultamos las dos formas y unimos resultados sin duplicados.
      final results = await Future.wait([
        _firestore
            .collection('cult_songs')
            .where('cultId', isEqualTo: cultRef)
            .get(),
        _firestore
            .collection('cult_songs')
            .where('cultId', isEqualTo: cultId)
            .get(),
      ]);
      final Map<String, CultSong> bySongId = {};
      for (final snap in results) {
        for (final doc in snap.docs) {
          bySongId[doc.id] = CultSong.fromFirestore(doc);
        }
      }
      final list = bySongId.values.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return list;
    } catch (e) {
      debugPrint('Error cargando cult_songs: $e');
      return [];
    }
  }

  Future<List<AnnouncementModel>> _loadAnnouncements(String cultId) async {
    try {
      final snap = await _firestore
          .collection('announcements')
          .where('cultId', isEqualTo: cultId)
          .where('type', isEqualTo: 'cult')
          .get();
      final list = snap.docs
          .map((d) => AnnouncementModel.fromFirestore(d))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('Error cargando announcements: $e');
      return [];
    }
  }

  Future<List<Prayer>> _loadPrayers(String cultId) async {
    try {
      final cultRef = _firestore.collection('cults').doc(cultId);
      final snap = await _firestore
          .collection('prayers')
          .where('cultRef', isEqualTo: cultRef)
          .get();
      final list = snap.docs.map((d) => Prayer.fromFirestore(d)).toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      return list;
    } catch (e) {
      debugPrint('Error cargando prayers: $e');
      return [];
    }
  }

  Future<TimeSlot?> _loadSingleTimeSlot(String timeSlotId) async {
    try {
      final doc =
          await _firestore.collection('time_slots').doc(timeSlotId).get();
      if (!doc.exists) return null;
      return TimeSlot.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error cargando time_slot $timeSlotId: $e');
      return null;
    }
  }
}

class _LocationResult {
  final ChurchLocation? location;
  final Map<String, String>? embedded;
  _LocationResult({this.location, this.embedded});
}

class _MinistryGroupAccumulator {
  final String ministryId;
  final String ministryName;
  final List<CultMinistryRoleSummary> roles = [];
  _MinistryGroupAccumulator({
    required this.ministryId,
    required this.ministryName,
  });
}
