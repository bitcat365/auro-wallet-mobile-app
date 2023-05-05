import 'package:flutter/material.dart';
import 'package:auro_wallet/store/app.dart';
import 'package:auro_wallet/store/staking/types/validatorData.dart';
import 'package:auro_wallet/utils/i18n/index.dart';
import 'package:auro_wallet/utils/colorsUtil.dart';
import 'package:auro_wallet/utils/UI.dart';
import 'package:mobx/mobx.dart';
import 'package:collection/collection.dart';
import 'package:auro_wallet/page/staking/components/searchInput.dart';
import 'package:auro_wallet/page/staking/components/validatorItem.dart';
import 'package:auro_wallet/common/components/normalButton.dart';
import 'package:auro_wallet/page/staking/delegatePage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

import '../../common/components/browserLink.dart';
import '../../service/api/api.dart';

class ValidatorsPage extends StatefulWidget {
  ValidatorsPage(this.store);

  static final String route = '/staking/validators';

  final AppStore store;

  @override
  _ValidatorsPageState createState() => _ValidatorsPageState(store);
}

class _ValidatorsPageState extends State<ValidatorsPage>
    with SingleTickerProviderStateMixin {
  _ValidatorsPageState(this.store);

  final AppStore store;
  List<ValidatorData> validatorsList = [];
  List<ValidatorData> uiList = [];
  late ReactionDisposer monitorListDisposer;
  TextEditingController editingController = new TextEditingController();
  String? keywords;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      monitorListDisposer =
          reaction((_) => store.staking!.validatorsInfo, _onListChange);
      editingController.addListener(_onKeywordsChange);
      Future.delayed(const Duration(milliseconds: 230), () {
        validatorsList = store.staking!.validatorsInfo;
        setState(() {
          uiList = validatorsList;
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    monitorListDisposer();
    editingController.dispose();
  }

  void _onKeywordsChange() {
    setState(() {
      keywords = editingController.text.trim();
      uiList = _filter(validatorsList);
    });
  }

  void _onListChange(List<ValidatorData> vs) {
    validatorsList = vs;
    setState(() {
      uiList = _filter(vs);
    });
  }

  List<ValidatorData> _filter(List<ValidatorData> list) {
    if (keywords == null || keywords!.isEmpty) {
      return list;
    }
    var res = list.where((element) {
      return (element.address != null &&
              element.address
                  .toLowerCase()
                  .contains(keywords!.toLowerCase())) ||
          (element.name != null &&
              element.name!.toLowerCase().contains(keywords!.toLowerCase()));
    }).toList();
    return res;
  }

  Future<void> onRefresh() async {
    await webApi.staking.fetchValidators();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> i18n = I18n.of(context).main;
    return RefreshIndicator(
        onRefresh: onRefresh,
        child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                i18n['nodeProviders']!,
                style: TextStyle(fontSize: 20),
              ),
              centerTitle: true,
              elevation: 0.0,
            ),
            resizeToAvoidBottomInset: false,
            body: SafeArea(
                maintainBottomViewPadding: true,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: SearchInput(
                        editingController: editingController,
                      ),
                    ),
                    Expanded(
                        child: ListView.builder(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, bottom: 20, top: 0),
                      itemCount: uiList.length + 2,
                      itemBuilder: (context, index) {
                        if (index == uiList.length) {
                          return ManualAddValidatorButton();
                        }
                        if (index == uiList.length + 1) {
                          return SubmitNodeButton();
                        }
                        return ValidatorItem(
                          data: uiList[index],
                        );
                      },
                    ))
                  ],
                ))));
  }
}

class ManualAddValidatorButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, String> i18n = I18n.of(context).main;
    var theme = Theme.of(context).textTheme;
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, DelegatePage.route,
                  arguments: DelegateParams(
                      validatorData: null, manualAddValidator: true));
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(i18n['manualAdd']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).primaryColor,
                    )),
              ],
            ))));
  }
}

class SubmitNodeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, String> stakingI18n = I18n.of(context).staking;
    var theme = Theme.of(context).textTheme;
    return Padding(
        padding: EdgeInsets.only(top: 10, bottom: 0),
        child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, DelegatePage.route,
                  arguments: DelegateParams(
                      validatorData: null, manualAddValidator: true));
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BrowserLink(
                    'https://github.com/aurowallet/launch/tree/master/validators',
                    showIcon: false,
                    text: stakingI18n['submitList']!,
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0x4D000000),
                    )),
              ],
            ))));
  }
}
