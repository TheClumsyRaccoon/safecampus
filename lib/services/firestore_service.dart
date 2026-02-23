import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safecampus/models/group_model.dart';
import 'package:safecampus/models/invitation_code.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- GROUPES ---

  // Créer un groupe
  Future<void> createGroup(String name, String pseudo) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newGroupRef = _db.collection('groups').doc();
    final newGroup = Group(
      id: newGroupRef.id,
      name: name,
      members: [
        GroupMember(userId: user.uid, pseudo: pseudo, role: GroupRole.owner)
      ],
      trips: [],
    );

    await newGroupRef.set(newGroup.toMap());
  }

  // Obtenir les groupes de l'utilisateur
  Stream<List<Group>> getUserGroups() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('groups')
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Group.fromMap(doc.data());
      }).toList();
    });
  }

  // Obtenir un groupe spécifique
  Stream<Group> getGroupStream(String groupId) {
    return _db.collection('groups').doc(groupId).snapshots().map((doc) {
      if (!doc.exists) throw "Groupe introuvable";
      return Group.fromMap(doc.data()!);
    });
  }

  // Quitter un groupe
  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final groupRef = _db.collection('groups').doc(groupId);
    final doc = await groupRef.get();
    if (!doc.exists) return;

    final group = Group.fromMap(doc.data()!);
    final updatedMembers =
        group.members.where((m) => m.userId != user.uid).toList();

    // Si plus personne supprimer le groupe
    if (updatedMembers.isEmpty) {
      await groupRef.delete();
    } else {
      await groupRef.update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'memberIds': updatedMembers.map((m) => m.userId).toList(),
      });
    }
  }

  // Supprime les données d'un utilisateur dans tous les groupes
  Future<void> deleteUserGroupData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final groupsQuery =
        _db.collection('groups').where('memberIds', arrayContains: user.uid);

    final snapshot = await groupsQuery.get();
    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      final group = Group.fromMap(doc.data());
      final updatedMembers =
          group.members.where((m) => m.userId != user.uid).toList();

      if (updatedMembers.isEmpty) {
        // Si l'utilisateur était le dernier supprimer le groupe
        batch.delete(doc.reference);
      } else {
        // Sinon juste retirer l'utilisateur de la liste des membres
        batch.update(doc.reference, {
          'members': updatedMembers.map((m) => m.toMap()).toList(),
          'memberIds': updatedMembers.map((m) => m.userId).toList(),
        });
      }
    }
    await batch.commit();
  }

  Future<void> updatePseudoInGroups(String newPseudo) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _db
        .collection('groups')
        .where('memberIds', arrayContains: user.uid)
        .get();

    for (final doc in snapshot.docs) {
      final group = Group.fromMap(doc.data());
      final updatedMembers = group.members.map((m) {
        return m.userId == user.uid
            ? GroupMember(userId: m.userId, pseudo: newPseudo, role: m.role)
            : m;
      }).toList();
      await doc.reference.update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
      });
    }
  }

  // Promouvoir un membre
  Future<void> updateMemberRole(
      String groupId, String userId, GroupRole newRole) async {
    await _db.runTransaction((transaction) async {
      final groupRef = _db.collection('groups').doc(groupId);
      final snapshot = await transaction.get(groupRef);

      if (!snapshot.exists) return;

      final group = Group.fromMap(snapshot.data()!);
      final updatedMembers = group.members.map((m) {
        return m.userId == userId
            ? GroupMember(userId: m.userId, pseudo: m.pseudo, role: newRole)
            : m;
      }).toList();

      transaction.update(groupRef, {
        'members': updatedMembers.map((m) => m.toMap()).toList(),
      });
    });
  }

  // Transférer la propriété
  Future<void> transferOwnership(
      String groupId, String currentOwnerId, String newOwnerId) async {
    await _db.runTransaction((transaction) async {
      final groupRef = _db.collection('groups').doc(groupId);
      final snapshot = await transaction.get(groupRef);

      if (!snapshot.exists) return;

      final group = Group.fromMap(snapshot.data()!);
      final updatedMembers = group.members.map((m) {
        if (m.userId == currentOwnerId) {
          return GroupMember(
              userId: m.userId, pseudo: m.pseudo, role: GroupRole.admin);
        }
        if (m.userId == newOwnerId) {
          return GroupMember(
              userId: m.userId, pseudo: m.pseudo, role: GroupRole.owner);
        }
        return m;
      }).toList();

      transaction.update(
          groupRef, {'members': updatedMembers.map((m) => m.toMap()).toList()});
    });
  }

  // Retirer un membre
  Future<void> removeMember(String groupId, String userId) async {
    await _db.runTransaction((transaction) async {
      final groupRef = _db.collection('groups').doc(groupId);
      final snapshot = await transaction.get(groupRef);

      if (!snapshot.exists) return;

      final group = Group.fromMap(snapshot.data()!);
      final updatedMembers =
          group.members.where((m) => m.userId != userId).toList();

      transaction.update(groupRef, {
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'memberIds': updatedMembers.map((m) => m.userId).toList(),
      });
    });
  }

  // Supprimer un groupe et ses invitations
  Future<void> deleteGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).delete();
    final invSnapshot = await _db
        .collection('invitations')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (var doc in invSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // --- INVITATIONS ---

  // Créer un code d'invitation
  Future<void> createInvitation(InvitationCode invitation) async {
    await _db
        .collection('invitations')
        .doc(invitation.code)
        .set(invitation.toMap());
  }

  // Rejoindre via code
  Future<void> joinGroupWithCode(String code, String pseudo) async {
    final user = _auth.currentUser;
    if (user == null) throw "Non connecté";

    final invRef = _db.collection('invitations').doc(code);
    final invDoc = await invRef.get();

    if (!invDoc.exists) throw "Code invalide";

    final invitation = InvitationCode.fromMap(invDoc.data()!);

    if (DateTime.now().isAfter(invitation.expiresAt)) {
      await invRef.delete(); // Nettoyage
      throw "Code expiré";
    }

    if (invitation.currentUses >= invitation.maxUses) {
      throw "Code utilisé au maximum";
    }

    // Ajouter au groupe
    final groupRef = _db.collection('groups').doc(invitation.groupId);
    final groupDoc = await groupRef.get();
    if (!groupDoc.exists) throw "Groupe introuvable";

    final group = Group.fromMap(groupDoc.data()!);
    if (group.members.any((m) => m.userId == user.uid)) {
      throw "Vous êtes déjà membre";
    }

    final newMember =
        GroupMember(userId: user.uid, pseudo: pseudo, role: GroupRole.member);
    final updatedMembers = List<GroupMember>.from(group.members)
      ..add(newMember);

    // Groupe et compteur mis à jour ensemble
    await _db.runTransaction((transaction) async {
      transaction.update(groupRef, {
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'memberIds': updatedMembers.map((m) => m.userId).toList(),
      });
      transaction.update(invRef, {
        'currentUses': invitation.currentUses + 1,
      });
    });
  }

  // --- TRAJETS ---

  Future<void> addTrip(String groupId, GroupTrip trip) async {
    final groupRef = _db.collection('groups').doc(groupId);
    await groupRef.update({
      'trips': FieldValue.arrayUnion([trip.toMap()])
    });
  }

  Future<void> updateTrip(String groupId, GroupTrip updatedTrip) async {
    // Évite les mises à jour concurrentes
    await _db.runTransaction((tx) async {
      final ref = _db.collection('groups').doc(groupId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final group = Group.fromMap(snap.data()!);
      final updatedTrips = group.trips
          .map((t) => t.id == updatedTrip.id ? updatedTrip : t)
          .toList();
      tx.update(ref, {'trips': updatedTrips.map((t) => t.toMap()).toList()});
    });
  }

  Future<void> deleteTrip(String groupId, String tripId) async {
    await _db.runTransaction((tx) async {
      final ref = _db.collection('groups').doc(groupId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final group = Group.fromMap(snap.data()!);
      final updatedTrips = group.trips.where((t) => t.id != tripId).toList();
      tx.update(ref, {'trips': updatedTrips.map((t) => t.toMap()).toList()});
    });
  }
}
