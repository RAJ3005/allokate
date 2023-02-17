import 'package:allokate/model/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'funds.dart';

/// Represents all projection data for a given set of [Fund] ids
class ProjectionData extends ChangeNotifier {
  /// List of all data points associated with the user, in time order
  List<ProjectionDataPoint> _points = [];

  List<ProjectionDataPoint> get points => List.from(_points);

  ProjectionDataPoint get getLatestData => points.isEmpty ? null : points[0];
  double get getLatestBalance => getLatestData?.monthlySavings ?? 0.0;

  Future<double> get getBalance30DaysAgo async {
    Map userData =
        (await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).get()).data();
    var balanceHistory = userData['balanceHistory'] as Map;
    List<BalanceHistory> history = [];
    balanceHistory.forEach((key, value) {
      var balanceHistory = BalanceHistory(timestamp: int.parse(key), balance: (value as num).toDouble());
      history.add(balanceHistory);
    });
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return history[0].balance;
  }

  Future<List<BalanceHistory>> get getBalanceHistory async {
    Map userData =
        (await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).get()).data();
    var balanceHistory = userData['balanceHistory'] as Map;
    List<BalanceHistory> history = [];
    balanceHistory.forEach((key, value) {
      var balanceHistory = BalanceHistory(timestamp: int.parse(key), balance: (value as num).toDouble());
      history.add(balanceHistory);
    });
    return history;
  }

  Future<List<BalanceHistory>> getFundBalanceHistory(String fundId) async {
    Map fundData = (await FirebaseFirestore.instance.collection('funds').doc(fundId).get()).data();
    var balanceHistory = fundData['fundHistory'] as Map;
    List<BalanceHistory> history = [];
    balanceHistory.forEach((key, value) {
      var balanceHistory = BalanceHistory(timestamp: int.parse(key), balance: (value as num).toDouble());
      history.add(balanceHistory);
    });
    return history;
  }

  ProjectionData() {
    FirebaseFirestore.instance
        .collection(projectionDataCollection)
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser.uid)
        .orderBy('dateUnix', descending: true)
        .snapshots()
        .listen((snap) {
      if (snap != null && snap.docs != null && snap.size > 0) {
        _points = snap.docs.map((doc) => ProjectionDataPoint.fromDoc(doc.data())).toList();
      } else {
        _points.clear();
      }

      notifyListeners();
    });
  }
}

/// Represents a set of projection data (for multiple funds) at 1 particular time
class ProjectionDataPoint {
  const ProjectionDataPoint({this.dateUnix, this.uid, this.fundSnapshots, this.monthlySavings});

  final int dateUnix;
  final String uid;
  final Map<String, FundDataSnapshot> fundSnapshots;
  final double monthlySavings;

  factory ProjectionDataPoint.fromDoc(Map<String, dynamic> map) {
    return ProjectionDataPoint(
      dateUnix: map['dateUnix'],
      uid: map['uid'],
      monthlySavings: (map['monthlySavings'] as num).toDouble(),
      fundSnapshots: (map['fundSnapshots'] as Map).map((key, value) => MapEntry(key, FundDataSnapshot.fromDoc(value))),
    );
  }

  double get getTotalAmount => monthlySavings;
  double get getTotalAllocatedAmount => fundSnapshots.values.fold(0, (prev, element) => prev + element.amount);

  Map<String, dynamic> toDoc() {
    return {
      'dateUnix': dateUnix,
      'uid': uid,
      'monthlySavings': monthlySavings,
      'fundSnapshots': fundSnapshots.map((key, value) => MapEntry(key, value.toDoc())),
    };
  }

  FundDataSnapshot getFundById(String fundId) => !fundSnapshots.containsKey(fundId) ? null : fundSnapshots[fundId];

  @override
  String toString() {
    return toDoc().toString();
  }
}

class BalanceHistory {
  final int timestamp;
  final double balance;

  BalanceHistory({@required this.timestamp, @required this.balance});

  @override
  String toString() {
    return 'BalanceHistory{timestamp: $timestamp, balance: $balance}';
  }
}
