import 'dart:math';

import 'package:allokate/constants/styles.dart';
import 'package:allokate/model/constants.dart';
import 'package:allokate/model/funds.dart';
import 'package:allokate/model/icons.dart';
import 'package:allokate/model/info_cards.dart';
import 'package:allokate/model/projection_data.dart';
import 'package:allokate/screens/category_options.dart';
import 'package:allokate/services/database.dart';
import 'package:allokate/services/push_notifications.dart';
import 'package:allokate/utils/alerts.dart';
import 'package:allokate/utils/decimal_text_input_formatter.dart';
import 'package:allokate/utils/design_utils.dart';
import 'package:allokate/utils/icon_picker_form_field.dart';
import 'package:allokate/utils/string_utils.dart';
import 'package:allokate/utils/color_picker_form_field.dart';
import 'package:allokate/utils/validators.dart';
import 'package:allokate/widgets/account_icon.dart';
import 'package:allokate/widgets/blue_button.dart';
import 'package:allokate/widgets/enlarged_pie_chart.dart';
import 'package:allokate/widgets/red_button.dart';
import 'package:allokate/widgets/nav_drawer.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

final pounds = NumberFormat('#,##0', 'en_UK');

class _HomePageState extends State<HomePage> {
  List<String> categoriesValues = [
    'Savings',
    'Investments',
    'Bills',
    'Charity',
    'Entertainment',
    'Family',
    'Finances',
    'General',
    'Gifts',
    'Groceries',
    'Holidays',
    'Housing',
    'Leisure',
    'Lunch',
    'Mortgage',
    'Rent',
    'Shopping',
    'Vehicle',
  ];

  List<FundCategory> categories = FundCategory.values.toList();

  void zoomClicked() {
    var fundList = Provider.of<FundList>(context, listen: false);

    if (fundList.getFundIds.isNotEmpty) {
      onEnlargePressed(context);
    }
  }

  @override
  void initState() {
    super.initState();
    PushNotificationsManager().init();
    // SendGridEmailer().sendEmail(name: 'hello', emailAddress: 'adedayoomosanya@icloud.com');
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final CarouselController _carouselController = CarouselController();
  bool privacyModeOn = false;

  int _touchedIndex = -1;
  bool _otherSelected = false; // Whether or not the selected slice is "Other"
  bool get _sliceSelected => _touchedIndex != -1;
  final FocusNode _fundAmountFocusNode = FocusNode();

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      nextFocus: false,
      actions: [
        KeyboardActionsItem(
          focusNode: _fundAmountFocusNode,
        ),
      ],
    );
  }

  bool justDeletedItem = false;

  @override
  Widget build(BuildContext context) {
    double totalAmount = Provider.of<FundList>(context).totalAmount;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: kMainColor,
      ),
      key: _scaffoldKey,
      drawer: const NavDrawer(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/wave_background.png'), fit: BoxFit.cover),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    _buildTopbar(),
                    _buildTotalBalance(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: privacyModeOn
                          ? Container()
                          : Column(
                              children: [
                                _buildNumbers(totalAmount),
                                const SizedBox(height: 5),
                                _build30DayPerformance(),
                              ],
                            ),
                    )
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoCardCarousel(context),
                  _buildCharts(context),
                  _buildButtons(context),
                  _buildFundsList(context)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_buildGreeting(), _buildAvatar()],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello!',
          style: DesignUtils.defaultStyle(color: Colors.white),
        ),
        const SizedBox(height: 5),
        if (FirebaseAuth.instance.currentUser != null)
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection(usersCollection)
                  .doc(FirebaseAuth.instance.currentUser.uid)
                  .get(),
              builder: (context, snap) {
                if (snap == null || snap.data == null) return Container();
                return Text(
                  snap.data.data()['fullName'],
                  style: DesignUtils.defaultStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                );
              }),
      ],
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () {
        _scaffoldKey.currentState.openDrawer();
      },
      child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Image.asset('assets/user.png')),
    );
  }

  Widget _buildTotalBalance() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Total Balance',
          style: DesignUtils.defaultStyle(color: Colors.white),
        ),
        const SizedBox(width: 15),
        IconButton(
            icon: Icon(
              privacyModeOn ? Ionicons.eye_off_outline : Ionicons.eye_outline,
              color: kBlueColor,
            ),
            onPressed: () {
              setState(() {
                privacyModeOn = !privacyModeOn;
              });
            })
      ],
    );
  }

  Widget _buildNumbers(number1) {
    Widget _buildThirtyDayPerformance({@required Future<double> getBalance30DaysAgo}) {
      Color textColor = Colors.white;
      String sign = '';
      String caretSymbol = '';
      double caretAngle = 0;

      const double caretOffset = 5;
      const double fontSize = 20;

      return FutureBuilder<double>(
          future: getBalance30DaysAgo,
          builder: (context, snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            double thirtyDayPerformance = number1 - snapshot.data;

            if (thirtyDayPerformance < 0) {
              textColor = Colors.red;
              sign = '';
              caretSymbol = '^';
              caretAngle = pi;
            } else if (thirtyDayPerformance > 0) {
              textColor = Colors.green;
              sign = '+';
              caretSymbol = '^';
              caretAngle = 0;
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sign + StringUtils.formatMoney(thirtyDayPerformance, decimalPlaces: 2),
                  style: DesignUtils.defaultStyle(color: textColor, fontSize: fontSize),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                        angle: caretAngle,
                        child: Transform.translate(
                          offset: const Offset(0, caretOffset),
                          child:
                              Text(caretSymbol, style: DesignUtils.defaultStyle(color: textColor, fontSize: fontSize)),
                        ))
                  ],
                )
              ],
            );
          });
    }

    List balance = StringUtils.formatMoney(number1).split('.');
    return Column(
      children: [
        RichText(
          text: TextSpan(
            text: balance[0],
            style: DesignUtils.defaultStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold),
            children: <TextSpan>[
              TextSpan(
                text: '.' + balance[1],
                style: DesignUtils.defaultStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        _buildThirtyDayPerformance(getBalance30DaysAgo: Provider.of<ProjectionData>(context).getBalance30DaysAgo),
      ],
    );
  }

  Widget _build30DayPerformance() {
    return Text(
      '30 Day Performance',
      style: DesignUtils.defaultStyle(color: Colors.white),
    );
  }

  Widget _buildInfoCardCarousel(BuildContext context) {
    double height = 125;

    var infoCardList = Provider.of<InfoCardList>(context).list;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(height: height, viewportFraction: 0.8, autoPlay: true),
          items: infoCardList.map(infoCardBuilder).toList()),
    );
  }

  Widget infoCardBuilder(InfoCardData info) {
    IconImageData imgData = Provider.of<IconList>(context).getImage(info.imageUrl);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)), gradient: info.theme.getGradient),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(info.title,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.roboto(color: info.theme.getTextColor, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AutoSizeText(info.body,
                              minFontSize: 8,
                              style: GoogleFonts.roboto(color: info.theme.getTextColor, height: 1.5, fontSize: 14)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              imgData == null
                  ? Container()
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
                        child: SizedBox(
                          child: imgData.image,
                          width: 50,
                        ),
                      ),
                    )
            ],
          )),
    );
  }

  Widget _buildCharts(BuildContext context) {
    var fundList = Provider.of<FundList>(context);

    Size size = MediaQuery.of(context).size;
    double chartSize = min(175, size.width / 2);

    var chartLegend = SizedBox(
      height: chartSize,
      child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: fundList.pieChartListLength,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, i) {
            var fund = fundList.getFundForPieChart(i);
            final bool isSelected = i == _touchedIndex;

            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        height: 15,
                        width: 15,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: fund.getColor),
                      )),
                  Flexible(
                    child: Text(
                      privacyModeOn ? '***' : fund.name,
                      style: DesignUtils.defaultStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: isSelected ? 16 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
    );

    var chart = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(
        child: _buildPieChart(context, chartSize: chartSize),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: chartLegend,
        ),
      )
    ]);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Total Funds Breakdown',
                  textAlign: TextAlign.start,
                  style: DesignUtils.defaultStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: chartSize,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: chart,
            ),
          )
        ],
      ),
    );
  }

  var buttonStyle = DesignUtils.defaultStyle(fontSize: 16, color: Colors.white);
  var buttonColor = MaterialStateProperty.all(const Color(0xFF0787D9));

  _buildButtons(BuildContext context) {
    var fundList = Provider.of<FundList>(context);
    bool pieChartIsShowing = (fundList != null && fundList.length > 0 && !privacyModeOn);

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildButton(onPressed: zoomClicked, title: 'Zoom', iconData: Icons.zoom_out_map, active: pieChartIsShowing),
        _buildSmallVerticalDivider(),
        _buildButton(
          onPressed: () => onAddPressed(),
          title: 'Add',
          iconData: Icons.add,
        ),
        _buildSmallVerticalDivider(),
        _buildButton(onPressed: () => onEditPressed(), title: 'Edit', iconData: Icons.edit, active: _sliceSelected),
        _buildSmallVerticalDivider(),
        _buildButton(
            onPressed: () => onDeletePressed(context), title: 'Delete', iconData: Icons.delete, active: _sliceSelected),
      ],
    );
  }

  _buildSmallVerticalDivider() {
    return Container(
      height: 15,
      width: 1.5,
      color: Colors.grey.withOpacity(0.75),
    );
  }

  _buildButton({onPressed, title, iconData, bool active = true}) {
    return Expanded(
      child: GestureDetector(
        onTap: !active ? null : onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Icon(
                      iconData,
                      color: !active ? kMainColorLightGreyColor : kMainColor,
                    ),
                    Text(title)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onAddPressed() {
    _openBottomSheet(edit: false);
  }

  void onEditPressed() {
    if (_touchedIndex == -1) {
      Alerts.showErrorAlert(context: context, title: 'Error', message: 'Please select a slice to edit');
      return;
    }

    if (_otherSelected) {
      Alerts.showErrorAlert(context: context, title: 'Error', message: 'Cannot edit "Other"');
      return;
    }
    var fundList = Provider.of<FundList>(context, listen: false);
    var fund = fundList.getFund(_touchedIndex);
    if (fund != null) _openBottomSheet(edit: true);
  }

  void _openBottomSheet({bool edit = false}) {
    setState(() {
      bottomSheetInEditMode = edit;
    });

    const double borderRadius = 25.0;

    var shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(topLeft: Radius.circular(borderRadius), topRight: Radius.circular(borderRadius)),
    );

    _scaffoldKey.currentState.showBottomSheet(_buildBottomSheet, shape: shape);
  }

  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _heldInController = TextEditingController();
  FundCategory _category;
  Color _selectedColor;
  String _selectedImageUrl;

  bool savingFund = false;

  _saveFundFromForm(BuildContext context, String fundId) async {
    final double fundAmount = double.parse(_amountController.text);
    final String name = _accountNameController.text;
    final String heldIn = _heldInController.text;
    final int color = _selectedColor.value;
    final FundCategory category = _category;
    final String imageUrl = _selectedImageUrl;

    setState(() {
      savingFund = true;
    });

    try {
      final fundList = Provider.of<FundList>(context, listen: false);
      if (name == 'Other') throw Exception('"Other" is a reserved word.');
      if (!bottomSheetInEditMode && fundList.fundNameExists(name)) {
        throw Exception('"$name" already exists. Choose a different name.');
      }

      if (fundId == null) {
        if (FirebaseAuth.instance.currentUser == null) {
          throw Exception('No user found');
        }

        Fund newFund = Fund(
            dateCreatedUnix: DateTime.now().millisecondsSinceEpoch,
            uid: FirebaseAuth.instance.currentUser.uid,
            percentage: 0.0,
            amountAllokated: 0.0,
            name: name,
            amount: fundAmount,
            heldIn: heldIn,
            category: category,
            color: color,
            imageUrl: imageUrl);

        var upload = FirebaseFirestore.instance.collection(fundsCollection).add(newFund.toDoc());

        await upload;
      } else {
        await FirebaseFirestore.instance.collection(fundsCollection).doc(fundId).update({
          'name': name,
          'amount': fundAmount,
          'heldIn': heldIn,
          'category': category.index,
          'color': color,
          'imageUrl': imageUrl
        });
      }

      Navigator.of(context).pop();
    } on Exception catch (e) {
      Alerts.showExceptionAlert(context: context, exception: e);
    } finally {
      setState(() {
        savingFund = false;
      });
    }
  }

  bool bottomSheetInEditMode = false;

  Widget blueSaveOrAddButton({String fundId, String title}) {
    return BlueButton(
        onPressed: () {
          _formKey.currentState.save();

          bool validated = _formKey.currentState.validate();

          if (validated) {
            _saveFundFromForm(context, fundId);
          }
        },
        buttonTitle: title);
  }

  Widget deleteFundButton({String fundId, String title}) {
    return RedButton(
        onPressed: () async {
          bool delete =
              await Alerts.showWarningAlert(context: context, message: 'Are you sure you want to delete this fund?');
          if (delete ?? false) {
            await FundList().deleteFund(fundId);
            Alerts.showSuccessAlert(context: context, title: 'Deleted fund');
            Navigator.of(context).pop();
          }
          setState(() {});
        },
        buttonTitle: title);
  }

  Widget _buildBottomSheet(BuildContext context) {
    var fundList = Provider.of<FundList>(context);
    Fund fund;
    String fundId;

    if (bottomSheetInEditMode && !justDeletedItem) {
      fund = fundList.getFund(_touchedIndex);
      fundId = fundList.getFundId(_touchedIndex);
      _accountNameController.text = fund.name ?? '';
      _amountController.text = fund.amount.toString() ?? '';
      _heldInController.text = fund.heldIn ?? '';
      _category = fund.category;
      _categoryController.text = StringUtils.capitalise(fund.categoryString);
      _selectedColor = fund.getColor;
      _selectedImageUrl = fund.imageUrl;
    } else {
      _accountNameController.clear();
      _categoryController.clear();
      _amountController.clear();
      _heldInController.clear();
      _category = null;
      _selectedColor = null;
      _selectedImageUrl = null;
    }

    var iconList = Provider.of<IconList>(context).list;
    var colorList = kAllPastelColors;

    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
      height: size.height - 100,
      child: Column(
        children: [
          Expanded(
            child: KeyboardActions(
              config: _buildConfig(context),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('${bottomSheetInEditMode ? 'Edit' : 'Add'} Fund',
                                style: DesignUtils.defaultStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          _buildMenuCloseButton(context)
                        ],
                      ),
                      TextFormField(
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Fund Name'),
                        controller: _accountNameController,
                        validator: Validators.defaultTextValidator,
                        style: DesignUtils.defaultStyle(),
                      ),
                      TextFormField(
                        readOnly: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Category'),
                        controller: _categoryController,
                        validator: Validators.defaultTextValidator,
                        style: DesignUtils.defaultStyle(),
                        onTap: () {
                          Navigator.of(context)
                              .push(
                            CupertinoPageRoute(
                              builder: (context) => CategoryOptions(
                                categoriesValues: categoriesValues,
                                fundCategory: categories,
                              ),
                            ),
                          )
                              .then((value) {
                            if (value != null) {
                              _categoryController.text = categoriesValues[value];
                              _category = categories[value];
                            }
                          });
                        },
                      ),
                      TextFormField(
                          controller: _amountController,
                          focusNode: _fundAmountFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Amount', prefixText: '£'),
                          inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                          validator: Validators.defaultNumberValidator),
                      TypeAheadFormField<String>(
                        textFieldConfiguration: TextFieldConfiguration(
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Held in (e.g. Lloyds Bank)'),
                          controller: _heldInController,
                        ),
                        validator: Validators.defaultTextValidator,
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Text(
                              suggestion,
                              style: DesignUtils.defaultStyle(),
                            ),
                          );
                        },
                        onSuggestionSelected: (suggestion) {
                          _heldInController.text = suggestion;
                        },
                        suggestionsCallback: (pattern) {
                          return DatabaseService.getHeldInSuggestions(pattern);
                        },
                      ),
                      const SizedBox(height: 16.0),
                      Text('Pick a Color', style: DesignUtils.defaultStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ColorPickerFormField(
                          initialValue: _selectedColor == null
                              ? null
                              : max(0, colorList.indexWhere((e) => e.value == _selectedColor.value)),
                          list: colorList,
                          onSaved: (i) {
                            if (i == null) {
                              Alerts.showErrorAlert(context: context, title: 'Please select an account color');
                              return;
                            }
                            setState(() {
                              _selectedColor = colorList[i];
                            });
                          }),
                      const SizedBox(height: 8.0),
                      Text('Pick a Account Icon',
                          style: DesignUtils.defaultStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Flexible(
                          child: IconPickerFormField(
                              initialValue: _selectedImageUrl == null
                                  ? null
                                  : max(0, iconList.indexWhere((e) => e.downloadUrl == _selectedImageUrl)),
                              list: iconList,
                              onSaved: (i) {
                                if (i == null) {
                                  Alerts.showErrorAlert(context: context, title: 'Please select an account icon');
                                }
                                setState(() {
                                  _selectedImageUrl = iconList[i].downloadUrl;
                                });
                              },
                              iconSize: 50.0))
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: bottomSheetInEditMode
                ? Column(
                    children: [
                      blueSaveOrAddButton(fundId: fundId, title: 'Save changes'),
                      const SizedBox(
                        height: 10,
                      ),
                      deleteFundButton(fundId: fundId, title: 'Delete')
                    ],
                  )
                : blueSaveOrAddButton(fundId: fundId, title: 'Add'),
          )
        ],
      ),
    );
  }

  _buildMenuCloseButton(BuildContext context) {
    justDeletedItem = false;

    return Container(
        decoration: BoxDecoration(color: kMainColor, borderRadius: BorderRadius.circular(100)),
        child: IconButton(
            iconSize: 15, color: Colors.white, onPressed: Navigator.of(context).pop, icon: const Icon(Icons.close)));
  }

  _buildFundsList(BuildContext context) {
    var icons = Provider.of<IconList>(context);
    var fundData = Provider.of<FundList>(context);

    Widget slideLeftBackground() {
      return Container(
        color: Colors.red,
        child: Align(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Icon(
                Icons.delete,
                color: Colors.white,
              ),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(
                width: 20,
              ),
            ],
          ),
          alignment: Alignment.centerRight,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      'Funds',
                      textAlign: TextAlign.start,
                      style: DesignUtils.defaultStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (fundData.getFundIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                        child: Text(
                          'Add a fund and it will show up here',
                          textAlign: TextAlign.center,
                          style: DesignUtils.defaultStyle(fontSize: 17, color: Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: fundData.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, i) {
              Fund fund = fundData.getFund(i);
              String fundId = fundData.getFundId(i);
              var iconImageData = icons.getImage(fund.imageUrl);

              return Dismissible(
                direction: DismissDirection.endToStart,
                background: slideLeftBackground(),
                key: UniqueKey(),
                confirmDismiss: (direction) async {
                  return await Alerts.showDeleteAlert(
                      context: context,
                      title: 'Are you sure you want to delete ${fund.name}?',
                      deleteFund: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        fundData.deleteFund(fundId);
                      });
                },
                child: ListTile(
                  onTap: () {
                    _touchedIndex = i;
                    _openBottomSheet(edit: true);
                  },
                  leading: iconImageData == null
                      ? const CircularProgressIndicator()
                      : AccountIcon(color: Color(fund.color), image: iconImageData.getImage),
                  title: Text(fund.name, style: DesignUtils.defaultStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(StringUtils.capitalise(fund.categoryString),
                      style: DesignUtils.defaultStyle(color: kMainColorkGreyColor)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(privacyModeOn ? '***' : StringUtils.formatMoney(fund.amount),
                          textAlign: TextAlign.end, style: DesignUtils.defaultStyle(fontWeight: FontWeight.bold)),
                      Text(fund.heldIn,
                          textAlign: TextAlign.end, style: DesignUtils.defaultStyle(color: kMainColorkGreyColor)),
                    ],
                  ),
                ),
              );
            })
      ],
    );
  }

  void onDeletePressed(BuildContext context) {
    if (_otherSelected) {
      Alerts.showErrorAlert(context: context, title: 'Error', message: 'Cannot delete "Other"');
      return;
    }
    _deleteSelectedSlice(context);
  }

  Future<void> _deleteSelectedSlice(BuildContext context) async {
    if (_touchedIndex == null || _touchedIndex < 0) return;

    final fundList = Provider.of<FundList>(context, listen: false);

    final fundIdToDelete = fundList.getFundIdForPieChart(_touchedIndex);
    if (fundIdToDelete == null) return;

    final fundToDelete = fundList.getFundById(fundIdToDelete);
    if (fundToDelete == null) return;

    bool delete = await Alerts.showWarningAlert(
        context: context, message: 'Are you sure you want to delete "${fundToDelete.name}"?');
    if (delete ?? false) await fundList.deleteFund(fundIdToDelete);
    setState(() {});
  }

  void onEnlargePressed(BuildContext c) {
    setState(() {
      _touchedIndex = -1;
    });
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EnlargedChart(
          onWillPop: () {
            setState(() {
              _touchedIndex = -1;
            });
          },
          chart: _buildPieChart(context),
        ),
      ),
    );
  }

  _buildPieChart(BuildContext context, {double chartSize}) {
    var fundList = Provider.of<FundList>(context);
    chartSize ??= MediaQuery.of(context).size.width;

    bool showData = (fundList != null && fundList.length > 0);

    var noData = SizedBox(height: chartSize, child: const Center(child: Text('No data to show')));

    return Hero(
      tag: '',
      child: AspectRatio(
        aspectRatio: 1,
        child: !showData
            ? noData
            : PieChart(
                PieChartData(
                  centerSpaceRadius: 0,
                  sections: List.generate(fundList.pieChartListLength, (index) {
                    var fund = fundList.getFundForPieChart(index);
                    bool isTouched = index == _touchedIndex;
                    if (isTouched) {
                      _otherSelected = fund.name == 'Other';
                    }

                    return PieChartSectionData(
                      titlePositionPercentageOffset: 0.75,
                      titleStyle: DesignUtils.defaultStyle(
                          fontSize: isTouched ? 20 : 16, fontWeight: FontWeight.bold, color: Colors.white),
                      title:
                          NumberFormat.percentPattern().format(fundList.percentageOfTotalAmount(fund?.amount ?? 0.0)),
                      color: fund.name == 'Other' ? Colors.grey : fund.getColor,
                      value: fund?.amount ?? 0.0,
                      radius: isTouched ? chartSize / 2 : 0.8 * chartSize / 2,
                    );
                  }),
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (pieTouchResponse) {
                      setState(
                        () {
                          final desiredTouch = pieTouchResponse.touchInput is PointerDownEvent;
                          if (desiredTouch && pieTouchResponse.touchedSection != null) {
                            int _tempTouchedIndex = pieTouchResponse.touchedSection.touchedSectionIndex;
                            if (_tempTouchedIndex == _touchedIndex) {
                              _touchedIndex = -1;
                            } else {
                              _touchedIndex = _tempTouchedIndex;
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
