import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) => UserModel.fromFirestore(doc));
  }

  Stream<List<TournamentModel>> streamTournaments(String category) {
    Query query = _db.collection('tournaments');
    if (category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TournamentModel.fromFirestore(doc)).toList());
  }

  Future<String> joinTournament(String tournamentId, String uid, double entryFee) async {
    DocumentReference userRef = _db.collection('users').doc(uid);
    DocumentReference tournamentRef = _db.collection('tournaments').doc(tournamentId);

    return _db.runTransaction((transaction) async {
      DocumentSnapshot userSnap = await transaction.get(userRef);
      DocumentSnapshot tourneySnap = await transaction.get(tournamentRef);

      if (!userSnap.exists || !tourneySnap.exists) {
        return "User or Tournament not found.";
      }

      double currentBalance = (userSnap.get('wallet_balance') ?? 0).toDouble();
      int joinedSlots = tourneySnap.get('joined_slots') ?? 0;
      int totalSlots = tourneySnap.get('total_slots') ?? 0;
      List<dynamic> joinedUsers = tourneySnap.get('joined_users') ?? [];

      if (joinedUsers.contains(uid)) {
        return "You have already joined.";
      }

      if (currentBalance < entryFee) {
        return "Insufficient balance.";
      }

      if (joinedSlots >= totalSlots) {
        return "Slots full.";
      }

      transaction.update(userRef, {'wallet_balance': currentBalance - entryFee});
      transaction.update(tournamentRef, {
        'joined_slots': joinedSlots + 1,
        'joined_users': FieldValue.arrayUnion([uid])
      });

      return "Successfully joined!";
    });
  }

  Future<void> requestDeposit(String uid, double amount, String trxId, String method) async {
    await _db.collection('transactions').add({
      'user_id': uid,
      'amount': amount,
      'trx_id': trxId,
      'method': method,
      'status': 'Pending',
      'type': 'Deposit',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveDeposit(String trxDocId, String uid, double amount) async {
    WriteBatch batch = _db.batch();
    
    DocumentReference userRef = _db.collection('users').doc(uid);
    DocumentReference trxRef = _db.collection('transactions').doc(trxDocId);

    batch.update(userRef, {'wallet_balance': FieldValue.increment(amount)});
    batch.update(trxRef, {'status': 'Approved'});

    await batch.commit();
  }
}
