import 'dart:math';
import 'package:allokate/constants/number.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

enum FundCategory {
  savings,
  investments,
  bills,
  charity,
  entertainment,
  family,
  finances,
  general,
  gifts,
  groceries,
  holidays,
  housing,
  leisure,
  lunch,
  mortgage,
  rent,
  shopping,
  vehicle,
}

/// Provides the list of all the current funds associated with the current user,
/// and their current values/percentage Allokated
class FundList extends ChangeNotifier {
  List<String> _fundIds = [];
  final Map<String, Fund> _map = {};

  get length => _fundIds.length;
  List<String> get getFundIds => _map.keys.toList();

  /// Returns true of at least some percentage data is non-zero for some fund
  bool get percentageDataExists => _map.values.any((f) => f.percentage != 0.0);

  /// Returns the total aggregated amount of value of all funds in the list
  double get totalAmount => _map.values.fold(0, (prev, e) => prev + e.amount);

  /// Returns the number passed through as a percentage of the funds total value
  double percentageOfTotalAmount(double amount) => amount / totalAmount;

  /// Sets fund data just before a fund is updated and snapshot taken
  FundDataSnapshot setAmountAndPercentage(String fundId, double amount, double percentage) {
    var fund = _map[fundId];
    fund.amount += amount; // Total amount in fund increases by the amount allokated
    fund.amountAllokated = amount; // New allokated amount assigned
    fund.percentage = percentage; // New percentage assigned
    return FundDataSnapshot(amount: fund.amount, amountAllokated: fund.amountAllokated, percentage: fund.percentage);
  }

  Fund getFund(int i) => _indexInBounds(i) ? getFundById(getFundId(i)) : null;
  Fund getFundById(String s) => _map.containsKey(s) ? _map[s] : null;
  String getFundId(int i) => i < length ? _fundIds[i] : null;
  bool _indexInBounds(int i) => (i >= 0 && i < _fundIds.length);

  FundList() {
    FirebaseFirestore.instance
        .collection(fundsCollection)
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser.uid)
        .orderBy('amount', descending: true)
        .snapshots()
        .listen((snap) {
      _fundIds.clear();
      _map.clear();
      if (snap != null && snap.docs != null && snap.size > 0) {
        _fundIds = snap.docs.map((snap) => snap.id).toList();
        var entries = snap.docs.map((snap) => MapEntry(snap.id, Fund.fromDoc(snap.data()))).toList();
        _map.addEntries(entries);
      }

      notifyListeners();
    });
  }

  bool fundNameExists(String name) => _map.values.any((e) => e.name == name);

  Future<void> deleteFund(String fundId) async {
    await FirebaseFirestore.instance.collection(fundsCollection).doc(fundId).delete();

    notifyListeners();
  }

  /// For Pie Chart data: groups smallest funds into "Other" fund
  int get pieChartListLength => min(_totalSlicesIncludingOther, length);
  int get _totalSlicesIncludingOther => _totalSlicesExcludingOther + 1;
  int get _totalSlicesExcludingOther => maxPieChartSlices;

  Fund getFundForPieChart(int i) {
    if (i < _totalSlicesExcludingOther) {
      return getFund(i);
    } else if (i == _totalSlicesExcludingOther) {
      double amount = 0.0;
      for (int j = _totalSlicesExcludingOther; j < pieChartListLength; j++) {
        amount += getFund(j).amount;
      }
      return Fund(name: 'Other', color: Colors.grey.value, amount: amount);
    }
    return null;
  }

  getFundIdForPieChart(int i) {
    if (i < _totalSlicesExcludingOther) {
      return getFundId(i);
    } else if (i == _totalSlicesExcludingOther) {
      return null;
    }
  }
}

class Fund {
  Fund(
      {this.dateCreatedUnix,
      this.uid,
      this.name,
      this.imageUrl,
      this.color,
      this.percentage,
      this.amount,
      this.amountAllokated,
      this.category,
      this.heldIn});
  final String uid;
  final String name;
  final String imageUrl;
  final String heldIn;
  final int dateCreatedUnix;

  double percentage;
  double amountAllokated;
  double amount;

  final FundCategory category;
  String get categoryString => category.toString().split('.').sublist(1).join('.');

  final int color;
  Color get getColor => Color(color);

  factory Fund.fromDoc(Map<String, dynamic> map) {
    return Fund(
      dateCreatedUnix: map['dateCreatedUnix'],
      uid: map['uid'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      color: map['color'],
      percentage: (map['percentage'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      amountAllokated: (map['amountAllokated'] as num).toDouble(),
      category: FundCategory.values[map['category']],
      heldIn: map['heldIn'],
    );
  }
  Map<String, dynamic> toDoc() {
    return {
      'uid': uid,
      'name': name,
      'imageUrl': imageUrl,
      'color': color,
      'percentage': percentage,
      'amount': amount,
      'amountAllokated': amountAllokated,
      'category': category.index,
      'heldIn': heldIn,
      'dateCreatedUnix': dateCreatedUnix,
    };
  }
}

/// Represents a snapshot of a particular [Fund] at a particular time
class FundDataSnapshot {
  const FundDataSnapshot({this.amount, this.amountAllokated, this.percentage});

  final double amount;
  final double amountAllokated;
  final double percentage;

  factory FundDataSnapshot.fromDoc(Map<String, dynamic> map) {
    return FundDataSnapshot(
      amount: (map['amount'] as num).toDouble(),
      percentage: (map['percentage'] as num).toDouble(),
      amountAllokated: (map['amountAllokated'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toDoc() {
    return {
      'amount': amount,
      'percentage': percentage,
      'amountAllokated': amountAllokated,
    };
  }
}
