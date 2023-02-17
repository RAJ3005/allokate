import 'package:allokate/constants/styles.dart';
import 'package:allokate/model/constants.dart';
import 'package:allokate/model/funds.dart';
import 'package:allokate/model/icons.dart';
import 'package:allokate/model/projection_data.dart';
import 'package:allokate/utils/alerts.dart';
import 'package:allokate/utils/decimal_text_input_formatter.dart';
import 'package:allokate/utils/design_utils.dart';
import 'package:allokate/utils/string_utils.dart';
import 'package:allokate/widgets/account_icon.dart';
import 'package:allokate/widgets/blue_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:provider/provider.dart';

class AllokatePage extends StatefulWidget {
  final CupertinoTabController mainTabsController;
  const AllokatePage({Key key, this.mainTabsController}) : super(key: key);

  @override
  _AllokatePageState createState() => _AllokatePageState();
}

class _AllokatePageState extends State<AllokatePage> {
  @override
  void initState() {
    super.initState();

    _savingsAmountController.addListener(() {
      setState(() {
        double value = double.tryParse(_savingsAmountController.text);
        if (_savingsAmountController.text == '') value = 0.0;
        if (value != null) {
          _totalMonthlySavingsAmount = value;
          _refreshAmounts();
        }
      });
    });
  }

  double _totalMonthlySavingsAmount = 0.0;
  double _percentAllocated = 0.0;
  final _savingsAmountController = TextEditingController();

  final Map<String, TextEditingController> _percentageControllers = {};
  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, FocusNode> _percentageFocusNodes = {};
  final Map<String, FocusNode> _amountFocusNodes = {};
  final FocusNode _nodeText1 = FocusNode();

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      nextFocus: false,
      actions: [
        KeyboardActionsItem(
          focusNode: _nodeText1,
        ),
      ],
    );
  }

  _refreshPercentAllocated() {
    var fundList = Provider.of<FundList>(context, listen: false);
    setState(() {
      _percentAllocated = _percentageControllers.keys
          .where((k) => fundList.getFundIds.contains(k))
          .map((k) => _percentageControllers[k])
          .fold(0, (v1, v2) => v1 + ((double.tryParse(v2.text) ?? 0.0) / 100.0));
    });
  }

  _refreshAmounts() {
    var fundList = Provider.of<FundList>(context, listen: false);
    setState(() {
      for (var key in _percentageControllers.keys.where((k) => fundList.getFundIds.contains(k))) {
        double percent = double.tryParse(_percentageControllers[key].text);
        if (percent != null) {
          String newText = StringUtils.formatUpTo2DecimalPlaces((percent / 100) * _totalMonthlySavingsAmount);
          _amountControllers[key].value =
              TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
        }
      }
    });
  }

  onPercentageChanged(String fundId, String value) {
    _refreshPercentAllocated();
    if (_amountFocusNodes.values.any((node) => node.hasFocus)) return;

    var amountController = _amountControllers.containsKey(fundId) ? _amountControllers[fundId] : null;
    if (amountController == null || !isFundIdValid(fundId)) return;

    double newPercentage = double.tryParse(value);
    if (newPercentage == null) return;

    newPercentage /= 100;
    double newAmount = newPercentage * _totalMonthlySavingsAmount;
    double currentAmount = double.tryParse(amountController.text);

    if (newAmount != currentAmount) {
      String newText = StringUtils.formatUpTo2DecimalPlaces(newAmount);
      amountController.value =
          TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
    }
  }

  onAmountChanged(String fundId, String value) {
    if (_percentageFocusNodes.values.any((node) => node.hasFocus)) return;

    var percentageController = _percentageControllers.containsKey(fundId) ? _percentageControllers[fundId] : null;
    if (percentageController == null || !isFundIdValid(fundId)) return;

    double newAmount = double.tryParse(value);
    if (newAmount == null || _totalMonthlySavingsAmount == 0.0) return;

    double newPercentage = newAmount / _totalMonthlySavingsAmount;
    double currentPercentage = double.tryParse(percentageController.text);

    if (newPercentage != currentPercentage) {
      String newText = StringUtils.formatUpTo2DecimalPlaces(newPercentage * 100);
      percentageController.value =
          TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
    }
  }

  _onSettingsSaved(context) async {
    var fundList = Provider.of<FundList>(context, listen: false);

    if (_percentAllocated > 1.0) {
      Alerts.showErrorAlert(context: context, title: 'You cannot allocate more than 100% of your savings');
      return;
    }

    if (_savingsAmountController.text == '' || double.tryParse(_savingsAmountController.text) == null) {
      Alerts.showErrorAlert(context: context, title: 'Your total savings value is invalid/empty');
      return;
    }

    if (_percentAllocated != 1.0 &&
        _percentageControllers.values.any((c) => c.text == '' || double.tryParse(c.text) == null)) {
      Alerts.showErrorAlert(context: context, title: 'One or more of your percentages are invalid/empty');
      return;
    }

    if (_percentAllocated != 1.0 &&
        _amountControllers.values.any((c) => c.text == '' || double.tryParse(c.text) == null)) {
      Alerts.showErrorAlert(context: context, title: 'One or more of your amounts are invalid/empty');
      return;
    }

    List<Future> futureFundUpdates = [];
    Map<String, FundDataSnapshot> fundSnapshots = {};
    double monthlySavings = double.tryParse(_savingsAmountController.text);

    for (int i = 0; i < fundList.length; i++) {
      String fundId = fundList.getFundId(i);
      double amount = double.tryParse(_amountControllers[fundId].text) ?? 0;
      double percentage = double.tryParse(_percentageControllers[fundId].text) ?? 0;

      FundDataSnapshot snapshot = fundList.setAmountAndPercentage(fundId, amount, percentage);

      var editedFund = fundList.getFundById(fundId);
      var update = FirebaseFirestore.instance.collection(fundsCollection).doc(fundId).update(editedFund.toDoc());

      futureFundUpdates.add(update);
      fundSnapshots.addAll({fundId: snapshot});
    }

    await Future.wait(futureFundUpdates);

    await FirebaseFirestore.instance.collection(projectionDataCollection).add(ProjectionDataPoint(
            dateUnix: DateTime.now().millisecondsSinceEpoch,
            uid: FirebaseAuth.instance.currentUser.uid,
            monthlySavings: monthlySavings,
            fundSnapshots: fundSnapshots)
        .toDoc());

    await Alerts.showSuccessAlert(
        context: context,
        title: 'Allocation '
            'Confirmed!');
    widget.mainTabsController.index = 0;
  }

  @override
  Widget build(BuildContext context) {
    var fundList = Provider.of<FundList>(context);

    // If ANY fund IDs are missing from the controller map keys...
    if (fundList.getFundIds.any((element) => !_percentageControllers.keys.contains(element))) {
      List<String> missingIds =
          fundList.getFundIds.where((element) => !_percentageControllers.keys.contains(element)).toList();
      for (var id in missingIds) {
        _addPercentageController(context, id);
      }
    }

    if (fundList.getFundIds.any((element) => !_amountControllers.keys.contains(element))) {
      List<String> missingIds =
          fundList.getFundIds.where((element) => !_amountControllers.keys.contains(element)).toList();
      for (var id in missingIds) {
        _addAmountController(context, id);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kMainColor,
        toolbarHeight: 0,
      ),
      backgroundColor: Colors.white,
      body: KeyboardActions(
        config: _buildConfig(context),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/wave_background.png'), fit: BoxFit.cover),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Allokate',
                            style: DesignUtils.defaultStyle(
                                fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(
                          height: 40,
                        ),
                        Text(
                          'Total Savings Amount',
                          style: DesignUtils.defaultStyle(fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        _buildMonthlySavingsTextField(context),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text((_percentAllocated * 100).round().toString() + '% Allocated',
                                style: DesignUtils.defaultStyle(fontSize: 14, color: Colors.white))
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(100.0),
                            child: LinearProgressIndicator(
                              value: _percentAllocated,
                              minHeight: 10,
                            )),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Provider.of<FundList>(context).getFundIds.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                        child: Text(
                          'Add funds on the home page first, then allokate savings to funds here',
                          style: DesignUtils.defaultStyle(fontSize: 17, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: [
                          _buildList(context),
                          BlueButton(
                              buttonTitle: 'Save allocated settings',
                              onPressed: fundList.getFundIds.isEmpty ? null : () => _onSettingsSaved(context))
                        ],
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _buildList(BuildContext context) {
    var fundList = Provider.of<FundList>(context);
    var iconList = Provider.of<IconList>(context);

    return ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, i) {
          return Divider(
            thickness: 3,
            color: kMainColor.withOpacity(0.3),
          );
        },
        itemCount: fundList.length,
        itemBuilder: (context, i) {
          var fundId = fundList.getFundId(i);
          var fund = fundList.getFundById(fundId);

          var iconImageData = iconList.getImage(fund.imageUrl);

          KeyboardActionsConfig _buildConfig(BuildContext context) {
            return KeyboardActionsConfig(
              keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
              nextFocus: false,
              actions: List.generate(_percentageFocusNodes.length + _amountFocusNodes.length, (index) {
                return KeyboardActionsItem(
                  focusNode: [..._percentageFocusNodes.values, ..._amountFocusNodes.values][index],
                );
              }),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: SizedBox(
                        height: 35,
                        width: 35,
                        child: iconImageData == null
                            ? const CircularProgressIndicator()
                            : AccountIcon(color: Color(fund.color), image: iconImageData.getImage),
                      ),
                    ),
                    Text(fund.name, style: DesignUtils.defaultStyle(fontWeight: FontWeight.bold))
                  ],
                ),
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        focusNode: _percentageFocusNodes[fundId],
                        controller: _percentageControllers[fundId],
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: const InputDecoration(labelText: 'Percentage', suffixText: '%'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        focusNode: _amountFocusNodes[fundId],
                        controller: _amountControllers[fundId],
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                        decoration: const InputDecoration(labelText: 'Amount', prefixText: '£'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        key: Key(fundId),
                        readOnly: true,
                        initialValue: StringUtils.capitalise(fund.categoryString),
                        decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                            labelText: 'Category'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        key: Key(fundId),
                        readOnly: true,
                        initialValue: fund.heldIn,
                        decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                            labelText: 'Held in'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  _buildMonthlySavingsTextField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        child: TextField(
            focusNode: _nodeText1,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
            decoration: InputDecoration(
                fillColor: Colors.white.withOpacity(0.2),
                filled: true,
                prefixText: '£',
                prefixStyle: DesignUtils.defaultStyle(color: Colors.white),
                suffixIcon: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                        height: 30,
                        width: 25,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2))),
                    IconButton(
                        color: Colors.white,
                        iconSize: 15,
                        onPressed: () => _savingsAmountController.clear(),
                        icon: const Icon(Icons.close))
                  ],
                )),
            controller: _savingsAmountController,
            style: DesignUtils.defaultStyle(color: Colors.white)),
      ),
    );
  }

  void _addPercentageController(BuildContext context, String fundId) {
    var controller = TextEditingController();
    controller.addListener(() {
      onPercentageChanged(fundId, controller.text);
    });
    _percentageControllers.addAll({fundId: controller});
    _percentageFocusNodes.addAll({fundId: FocusNode()});

    var data = Provider.of<ProjectionData>(context).getLatestData;
    if (data == null) return;
    var latestFundSnapshot = data.getFundById(fundId);
    if (latestFundSnapshot == null) return;

    String initialPercentage = latestFundSnapshot.percentage.toString();
    controller.text = initialPercentage;
  }

  void _addAmountController(BuildContext context, String fundId) {
    var controller = TextEditingController();
    controller.addListener(() {
      onAmountChanged(fundId, controller.text);
    });
    _amountControllers.addAll({fundId: controller});
    _amountFocusNodes.addAll({fundId: FocusNode()});

    var data = Provider.of<ProjectionData>(context).getLatestData;
    if (data == null) return;
    var latestFundSnapshot = data.getFundById(fundId);
    if (latestFundSnapshot == null) return;

    String initialAmount = latestFundSnapshot.amount.toString();
    controller.text = initialAmount;
  }

  bool isFundIdValid(String fundId) {
    return context.read<FundList>().getFundIds.contains(fundId);
  }
}
