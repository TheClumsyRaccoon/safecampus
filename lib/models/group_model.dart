import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupRole { owner, admin, member }

class GroupMember {
  final String userId;
  final String pseudo;
  final GroupRole role;

  GroupMember({required this.userId, required this.pseudo, required this.role});

  // Persistance
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'pseudo': pseudo,
        'role': role.name,
      };

  factory GroupMember.fromMap(Map<String, dynamic> map) => GroupMember(
        userId: map['userId'] ?? '',
        pseudo: map['pseudo'] ?? 'Inconnu',
        role: GroupRole.values.firstWhere((e) => e.name == map['role'],
            orElse: () => GroupRole.member),
      );
}

class GroupTrip {
  final String id;
  final String authorId;
  final String depart;
  final String arrivee;
  final DateTime date;
  final List<String> participantIds;

  GroupTrip({
    required this.id,
    required this.authorId,
    required this.depart,
    required this.arrivee,
    required this.date,
    required this.participantIds,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'depart': depart,
        'arrivee': arrivee,
        'date': Timestamp.fromDate(date),
        'participantIds': participantIds,
      };

  factory GroupTrip.fromMap(Map<String, dynamic> map) {
    return GroupTrip(
      id: map['id'] ?? '',
      authorId: map['authorId'] ?? '',
      depart: map['depart'] ?? '',
      arrivee: map['arrivee'] ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : throw FormatException(
              'GroupTrip: champ "date" manquant ou invalide (id: ${map['id']})'),
      participantIds: List<String>.from(map['participantIds'] ?? []),
    );
  }

  GroupTrip copyWith({
    String? id,
    String? authorId,
    String? depart,
    String? arrivee,
    DateTime? date,
    List<String>? participantIds,
  }) {
    return GroupTrip(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      depart: depart ?? this.depart,
      arrivee: arrivee ?? this.arrivee,
      date: date ?? this.date,
      participantIds: participantIds ?? this.participantIds,
    );
  }
}

class Group {
  final String id;
  final String name;
  final List<GroupMember> members;
  final List<GroupTrip> trips;
  final List<String> memberIds;

  Group({
    required this.id,
    required this.name,
    required this.members,
    this.trips = const [],
  }) : memberIds = members.map((m) => m.userId).toList();

  // Persistance
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'members': members.map((m) => m.toMap()).toList(),
        'memberIds': members.map((m) => m.userId).toList(),
        'trips': trips.map((t) => t.toMap()).toList(),
      };

  factory Group.fromMap(Map<String, dynamic> map) {
    // On filtre les trajets pour ignorer ceux qui sont invalides (ex: date manquante) au lieu de faire planter tout le chargement du groupe.
    List<GroupTrip> safeTrips = [];
    if (map['trips'] != null && (map['trips'] as List).isNotEmpty) {
      for (var t in (map['trips'] as List)) {
        try {
          safeTrips.add(GroupTrip.fromMap(Map<String, dynamic>.from(t as Map)));
        } catch (e) {
          // On ignore le trajet corrompu
        }
      }
    }

    return Group(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Groupe sans nom',
      members: (map['members'] as List)
          .map((m) => GroupMember.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      trips: safeTrips,
    );
  }

  Group copyWith({
    String? id,
    String? name,
    List<GroupMember>? members,
    List<GroupTrip>? trips,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      trips: trips ?? this.trips,
    );
  }
}
