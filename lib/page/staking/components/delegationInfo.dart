import 'package:auro_wallet/common/components/copyContainer.dart';
import 'package:auro_wallet/l10n/app_localizations.dart';
import 'package:auro_wallet/store/staking/types/delegatedValidator.dart';
import 'package:auro_wallet/store/wallet/types/walletData.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:auro_wallet/store/app.dart';
import 'package:auro_wallet/store/staking/staking.dart';
import 'package:auro_wallet/store/staking/types/validatorData.dart';
import 'package:auro_wallet/store/assets/types/accountInfo.dart';
import 'package:auro_wallet/common/components/formPanel.dart';
import 'package:auro_wallet/utils/colorsUtil.dart';
import 'package:auro_wallet/utils/format.dart';
import 'package:auro_wallet/common/components/loadingPanel.dart';
import 'package:auro_wallet/common/consts/settings.dart';
import 'package:auro_wallet/page/staking/validatorsPage.dart';
import 'package:auro_wallet/common/components/browserLink.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';

class DelegationInfo extends StatelessWidget {
  DelegationInfo({required this.store, required this.loading});

  final AppStore store;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    AppLocalizations dic = AppLocalizations.of(context)!;
    AccountInfo? acc =
        store.assets!.accountsInfo[store.wallet!.currentAccountPubKey];
    bool isDelegated = acc != null ? acc.isDelegated : false;
    String? delegate = isDelegated ? acc.delegate : null;
    var theme = Theme.of(context).textTheme;
    var languageCode = store.settings!.localeCode.isNotEmpty
        ? store.settings!.localeCode
        : dic.localeName.toLowerCase();
    var url = languageCode == 'zh'
        ? store.settings!.aboutus!.stakingGuideCN
        : store.settings!.aboutus!.stakingGuide;

    return Container(
        margin: EdgeInsets.only(top: 30, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/stake/icon_delegation.svg',
                      width: 16,
                      color: Colors.black,
                    ),
                    Container(
                      width: 8,
                    ),
                    Text(
                      dic.delegationInfo,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w600),
                    )
                  ],
                ),
                BrowserLink(
                  url,
                  text: dic.emptyDelegateDesc3,
                  showIcon: false,
                )
              ],
            ),
            Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.black.withOpacity(0.05), width: 0.5)),
                margin: EdgeInsets.only(top: 10),
                child: loading
                    ? LoadingBox()
                    : (!isDelegated
                        ? EmptyInfo(store: store)
                        : DelegateInfo(delegate: delegate!, store: store))),
          ],
        ));
  }
}

class DelegateInfo extends StatelessWidget {
  DelegateInfo({required this.delegate, required this.store});

  final String delegate;
  final AppStore store;

  void _onChangeNode(context) {
    Navigator.pushNamed(
      context,
      ValidatorsPage.route,
    );
  }

  Widget _buildDelegateInfo(BuildContext context) {
    AppLocalizations dic = AppLocalizations.of(context)!;
    final DelegatedValidator? delegatedValidator =
        store.staking!.delegatedValidator;
    DelegatedValidator? validatorInfo;
    if (delegatedValidator != null &&
        delegatedValidator.publicKey == delegate) {
      validatorInfo = delegatedValidator;
    }
    final ValidatorData? validatorItem = store.staking!.validatorsInfo
        .firstWhereOrNull((e) => e.address == delegate);
    String? validatorName = validatorItem?.name;
    if (validatorName == null) {
      return Container(
          constraints: BoxConstraints(minHeight: 100),
          child: Column(
            children: [
              Row(children: [
                DelegateInfoItem(
                  labelText: dic.blockProducerAddress,
                  value: Fmt.address(delegate, pad: 10),
                  noBottom: false,
                )
              ]),
            ],
          ));
    } else {
      
      WalletData acc = store.wallet!.currentWallet;
      AccountInfo? balancesInfo = store.assets!.accountsInfo[acc.pubKey];
      BigInt total = balancesInfo != null ? balancesInfo.total : BigInt.from(0);

      return Container(
          child: Column(
        children: [
          Row(children: [
            Expanded(
                child: Container(
              margin: EdgeInsets.only(right: 100),
              child: DelegateInfoItem(
                  labelText: dic.blockProducerName,
                  value: validatorName),
            ))
          ]),
          Row(children: [
            DelegateInfoItem(
              labelText: dic.blockProducerAddress,
              value: Fmt.address(delegate, pad: 10),
              copyValue: delegate,
            )
          ]),
          Row(children: [
            DelegateInfoItem(
                labelText: dic.stakedBalance,
                value: Fmt.balance(total.toString(), COIN.decimals,
                        maxLength: COIN.decimals) +
                    ' ' +
                    COIN.coinSymbol)
          ]),
        ],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations dic = AppLocalizations.of(context)!;
    var theme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Observer(builder: (_) {
          return _buildDelegateInfo(context);
        }),
        Positioned(
            right: 0,
            top: 0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: Color(0xFF594AF1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(0, 32),
                  elevation: 0,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(
                dic.changeNode,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                _onChangeNode(context);
              },
            )),
      ],
    );
  }
}

class DelegateInfoItem extends StatelessWidget {
  DelegateInfoItem(
      {required this.labelText,
      required this.value,
      this.copyValue,
      this.noBottom = false});

  final String labelText;
  final String value;
  final String? copyValue;
  final bool noBottom;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        labelText,
        textAlign: TextAlign.left,
        style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.5),
            height: 1.42,
            fontWeight: FontWeight.w500),
      ),
      Padding(
        padding: EdgeInsets.only(top: 0, bottom: noBottom ? 0 : 10),
        child: CopyContainer(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.16,
                fontWeight: FontWeight.w500),
          ),
          text: copyValue,
          showIcon: true,
        ),
      )
    ]);
  }
}

class EmptyInfo extends StatelessWidget {
  EmptyInfo({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    AppLocalizations dic = AppLocalizations.of(context)!;
    var theme = Theme.of(context).textTheme;
    var languageCode = store.settings!.localeCode.isNotEmpty
        ? store.settings!.localeCode
        : dic.localeName.toLowerCase();
    return Container(
      margin: EdgeInsets.only(top: 60, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(dic.emptyDelegateTitle,
                        style: theme.headline4
                            ?.copyWith(color: Colors.black, fontSize: 16)))
              ]),
          Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                dic.emptyDelegateDesc1,
                style: theme.headline5!.copyWith(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.3),
              )),
          Padding(
              padding: EdgeInsets.only(top: 14, bottom: 20),
              child: Wrap(
                children: [
                  new RichText(
                    textScaleFactor: MediaQuery.of(context).textScaleFactor,
                    text: TextSpan(children: [
                      new TextSpan(
                        text: dic.emptyDelegateDesc2,
                        style: theme.headline5!.copyWith(
                            color: Colors.black.withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.3),
                      ),
                      new TextSpan(
                        text: dic.emptyDelegateDesc3,
                        style: theme.headline5!.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.3),
                        recognizer: new TapGestureRecognizer()
                          ..onTap = () {
                            var url = languageCode == 'zh'
                                ? store.settings!.aboutus!.stakingGuideCN
                                : store.settings!.aboutus!.stakingGuide;
                            print('url' + url);
                            launch(url);
                          },
                      ),
                    ]),
                  ),
                ],
              ))
        ],
      ),
    );
  }
}
