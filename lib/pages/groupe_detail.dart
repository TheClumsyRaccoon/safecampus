import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safecampus/models/group_model.dart';
import 'package:safecampus/models/invitation_code.dart';
import 'package:safecampus/pages/alerte.dart';
import 'package:safecampus/pages/nouveau_trajet_groupe.dart';
import 'package:safecampus/services/firestore_service.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';

class GroupeDetailPage extends StatefulWidget {
  final Group group;
  const GroupeDetailPage({super.key, required this.group});

  @override
  State<GroupeDetailPage> createState() => _GroupeDetailPageState();
}

class _GroupeDetailPageState extends State<GroupeDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();

  GroupRole _getCurrentUserRole(Group group) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return GroupRole.member;
    return group.members
        .firstWhere((m) => m.userId == userId,
            orElse: () =>
                GroupMember(userId: '', pseudo: '', role: GroupRole.member))
        .role;
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  void _generateInviteCode(Group group) async {
    final code = _generateRandomCode(6);
    final newInvite = InvitationCode(
      code: code,
      groupId: group.id,
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );

    // Sauvegarde du code d'invitation sur Firestore
    await _firestoreService.createInvitation(newInvite);

    // Copie dans le presse-papier
    await Clipboard.setData(ClipboardData(text: code));

    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Code copié ! Valable 1 jour.",
            style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _setMemberRole(
      Group group, GroupMember member, GroupRole newRole) async {
    await _firestoreService.updateMemberRole(group.id, member.userId, newRole);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "${member.pseudo} est maintenant ${newRole == GroupRole.admin ? 'administrateur' : 'membre'}."),
          backgroundColor: Theme.of(context).colorScheme.primary));
    }
  }

  void _transferOwnership(Group group, GroupMember newOwner) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Transférer la propriété ?"),
        content: Text(
            "Vous deviendrez administrateur et ${newOwner.pseudo} sera le nouveau propriétaire. Cette action est irréversible."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirmer")),
        ],
      ),
    );
    if (confirm != true) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _firestoreService.transferOwnership(
        group.id, currentUser.uid, newOwner.userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Vous avez transféré la propriété à ${newOwner.pseudo}."),
          backgroundColor: Theme.of(context).colorScheme.primary));
    }
  }

  void _removeMember(Group group, GroupMember member) async {
    await _firestoreService.removeMember(group.id, member.userId);

    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${member.pseudo} a été retiré du groupe."),
          backgroundColor: theme.colorScheme.primary));
    }
  }

  void _showMemberActions(
      BuildContext context, Group group, GroupMember member) {
    final theme = Theme.of(context);
    final currentUserRole = _getCurrentUserRole(group);
    final isCurrentUserOwner = currentUserRole == GroupRole.owner;
    final isTargetAdmin = member.role == GroupRole.admin;
    final isTargetMember = member.role == GroupRole.member;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  "Actions pour ${member.pseudo}",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 10),

              // Options réservées à l'owner
              if (isCurrentUserOwner) ...[
                if (isTargetMember || isTargetAdmin)
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                          isTargetAdmin
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: theme.colorScheme.onSurface),
                    ),
                    title: Text(isTargetAdmin
                        ? "Rétrograder membre"
                        : "Promouvoir administrateur"),
                    onTap: () {
                      Navigator.pop(ctx);
                      final newRole =
                          isTargetAdmin ? GroupRole.member : GroupRole.admin;
                      _setMemberRole(group, member, newRole);
                    },
                  ),
                if (isTargetAdmin)
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child:
                          Icon(Icons.vpn_key, color: theme.colorScheme.primary),
                    ),
                    title: const Text("Nommer propriétaire (Transfert)"),
                    onTap: () {
                      Navigator.pop(ctx);
                      _transferOwnership(group, member);
                    },
                  ),
              ],

              // Option de suppression
              if (isCurrentUserOwner ||
                  (currentUserRole == GroupRole.admin && isTargetMember))
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.person_remove_outlined,
                        color: theme.colorScheme.secondary),
                  ),
                  title: Text("Retirer du groupe",
                      style: TextStyle(color: theme.colorScheme.secondary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeMember(group, member);
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _leaveGroup(Group group) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentUserRole = _getCurrentUserRole(group);

    // Gestion du cas où le propriétaire quitte le groupe
    if (currentUserRole == GroupRole.owner && group.members.length > 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text(
                "Vous êtes propriétaire. Nommez un autre propriétaire avant de quitter."),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
      return;
    }
    await _firestoreService.leaveGroup(group.id);

    if (mounted) {
      final theme = Theme.of(context);
      Navigator.pop(context); // Retour à la liste des groupes
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Vous avez quitté le groupe."),
          backgroundColor: theme.colorScheme.primary));
    }
  }

  void _deleteGroup(Group group) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Supprimer le groupe ?",
            style: TextStyle(color: theme.colorScheme.error)),
        content: const Text(
            "Cette action est irréversible. Le groupe sera dissous pour tous les membres."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _firestoreService.deleteGroup(group.id);

    if (mounted) {
      Navigator.pop(context); // Retour à la liste
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Groupe supprimé.",
            style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
      ));
    }
  }

  void _addTrajet(Group group, Map<String, dynamic> trajetData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newTrip = GroupTrip(
      id: FirebaseFirestore.instance.collection('groups').doc().id,
      authorId: user.uid,
      depart: trajetData['depart'] ?? 'Départ',
      arrivee: trajetData['arrivee'] ?? 'Arrivée',
      date:
          trajetData['date'] is DateTime ? trajetData['date'] : DateTime.now(),
      participantIds: [user.uid], // L'auteur participe par défaut
    );

    await _firestoreService.addTrip(group.id, newTrip);

    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Trajet ajouté !",
            style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
      ));
    }
  }

  void _toggleParticipation(Group group, GroupTrip trip) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isParticipating = trip.participantIds.contains(user.uid);
    final List<String> newParticipants = List.from(trip.participantIds);

    if (isParticipating) {
      newParticipants.remove(user.uid);
    } else {
      newParticipants.add(user.uid);
    }

    final updatedTrip = trip.copyWith(participantIds: newParticipants);
    await _firestoreService.updateTrip(group.id, updatedTrip);
  }

  void _deleteTrip(Group group, GroupTrip trip) async {
    await _firestoreService.deleteTrip(group.id, trip.id);

    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Trajet supprimé.",
            style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<Group>(
      stream: _firestoreService.getGroupStream(widget.group.id),
      initialData:
          widget.group, // Affiche les données passées en attendant le stream
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: const CustomAppBar(title: "Erreur"),
            body: Center(child: Text("Erreur: ${snapshot.error}")),
          );
        }

        final group = snapshot.data ?? widget.group;
        final currentUserRole = _getCurrentUserRole(group);
        final isOwner = currentUserRole == GroupRole.owner;
        final isAdmin = currentUserRole == GroupRole.admin;
        final hasAdminRights = isOwner || isAdmin;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: CustomAppBar(
            title: group.name,
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_active,
                    color: theme.colorScheme.secondary),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AlertePage())),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Membres
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Membres (${group.members.length})",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary)),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          color: theme.colorScheme.onSurface),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'leave') _leaveGroup(group);
                        if (value == 'delete') _deleteGroup(group);
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'leave',
                          child: Row(
                            children: [
                              Icon(Icons.exit_to_app,
                                  color: theme.colorScheme.secondary),
                              const SizedBox(width: 10),
                              Text("Quitter le groupe",
                                  style: TextStyle(
                                      color: theme.colorScheme.secondary)),
                            ],
                          ),
                        ),
                        if (isOwner)
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_forever,
                                    color: theme.colorScheme.secondary),
                                const SizedBox(width: 10),
                                Text("Supprimer le groupe",
                                    style: TextStyle(
                                        color: theme.colorScheme.secondary)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: group.members.length,
                  itemBuilder: (context, index) {
                    final member = group.members[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: theme.colorScheme.onSurfaceVariant,
                              width: 0.5)),
                      child: ListTile(
                        onLongPress: (hasAdminRights &&
                                member.userId !=
                                    FirebaseAuth.instance.currentUser?.uid)
                            ? () => _showMemberActions(context, group, member)
                            : null,
                        title: Text(member.pseudo),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (member.role == GroupRole.owner)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text("PROPRIÉTAIRE",
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold)),
                              ),
                            if (member.role == GroupRole.admin)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text("ADMIN",
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Section Trajets
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text("Trajets proposés",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
              ),
              Expanded(
                flex: 2,
                child: group.trips.isEmpty
                    ? Center(
                        child: Text("Aucun trajet proposé pour le moment.",
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: group.trips.length,
                        itemBuilder: (context, index) {
                          final trip = group.trips[index];
                          final user = FirebaseAuth.instance.currentUser;
                          final isParticipating = user != null &&
                              trip.participantIds.contains(user.uid);

                          // Récupération des pseudos des participants
                          final participants = group.members
                              .where(
                                  (m) => trip.participantIds.contains(m.userId))
                              .map((m) => m.pseudo)
                              .toList();

                          final date = trip.date;
                          final dateStr =
                              "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}";

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    width: 0.5)),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(dateStr,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                              fontSize: 16)),
                                      Row(
                                        children: [
                                          if (isParticipating)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Chip(
                                                  label: const Text("Inscrit",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10)),
                                                  backgroundColor:
                                                      theme.colorScheme.primary,
                                                  padding: EdgeInsets.zero,
                                                  visualDensity:
                                                      VisualDensity.compact),
                                            ),
                                          if (hasAdminRights)
                                            IconButton(
                                              icon: Icon(Icons.delete_outline,
                                                  color: theme
                                                      .colorScheme.secondary,
                                                  size: 20),
                                              onPressed: () =>
                                                  _deleteTrip(group, trip),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 16,
                                          color: theme
                                              .colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                            "${trip.depart} ➔ ${trip.arrivee}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    "Participants (${participants.length}) : ${participants.join(', ')}",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _toggleParticipation(group, trip),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: isParticipating
                                                ? theme.colorScheme.secondary
                                                : theme.colorScheme.primary),
                                      ),
                                      child: Text(
                                          isParticipating
                                              ? "Se désister"
                                              : "Rejoindre ce trajet",
                                          style: TextStyle(
                                              color: isParticipating
                                                  ? theme.colorScheme.secondary
                                                  : theme.colorScheme.primary)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          // Affichage des boutons d'action en fonction du rôle
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasAdminRights) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _generateInviteCode(group),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text("Inviter un membre"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const NouveauTrajetGroupePage()));
                      if (result != null) {
                        _addTrajet(group, result);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text("Proposer un trajet",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
