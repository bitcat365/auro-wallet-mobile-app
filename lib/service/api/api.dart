import 'dart:async';
import 'dart:convert';
import 'package:auro_wallet/l10n/app_localizations.dart';
import 'package:auro_wallet/service/webview/bridgeService.dart';
import 'package:auro_wallet/store/settings/types/customNode.dart';
import 'package:auro_wallet/store/settings/types/networkType.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:auro_wallet/common/consts/settings.dart';
import 'package:auro_wallet/service/api/apiAccount.dart';
import 'package:auro_wallet/service/api/apiAssets.dart';
import 'package:auro_wallet/service/api/apiStaking.dart';
import 'package:auro_wallet/service/api/apiSetting.dart';
import 'package:auro_wallet/store/app.dart';
import 'package:auro_wallet/store/app.dart';
import 'package:auro_wallet/utils/UI.dart';
import 'package:auro_wallet/service/graphql.dart';

// global api instance
late Api webApi;

class Api {
  Api(this.context, this.store);

  final BuildContext context;
  final AppStore store;
  late GraphQLClient graphQLClient;

  final configStorage = GetStorage('configuration');

  late ApiAccount account;
  late ApiAssets assets;
  late ApiStaking staking;
  late ApiSetting setting;

  late BridgeService bridge;

  void init() async {
    bridge = BridgeService();
    await launchWebview();

    account = ApiAccount(this);
    assets = ApiAssets(this);
    staking = ApiStaking(this);
    setting = ApiSetting(this);
    graphQLClient =
        clientFor(uri: store.settings!.currentNode!.url, subscriptionUri: null)
            .value;
    fetchInitialInfo();
  }

  Future<void> launchWebview() async {
    await bridge.init();
  }

  void dispose() {}

  void updateGqlClient(String endpoint) {
    graphQLClient = clientFor(uri: endpoint, subscriptionUri: null).value;
  }

  Future<void> fetchInitialInfo() async {
    setting.fetchAboutUs();
    setting.fetchNetworkTypes();
    assets.fetchScamInfo();
    assets.queryTxFees();
    if (store.wallet!.walletListAll.length > 0) {
      await Future.wait([
        assets.fetchAccountInfo(showIndicator: true),
      ]);
    }
    staking.fetchStakingOverview();
  }

  bool getIsMainApi() {
    return store.settings!.isMainnet;
    // List<NetworkType> networks = store.settings!.networks;
    // List<CustomNode> customNodes = store.settings!.customNodeListV2;
    // if (store.settings!.endpoint == GRAPH_QL_TESTNET_NODE_URL) {
    //   return false;
    // } else if(store.settings!.endpoint == GRAPH_QL_MAINNET_NODE_URL){
    //   return true;
    // } else { // custom node
    //   final targetNets = customNodes.where((customNode) => customNode.url == currentUrl);
    //   if (targetNets.isNotEmpty) {
    //     CustomNode targetNet = targetNets.first;
    //     if (targetNet.networksType == '0') { // mainnet
    //       return true;
    //     } else if (targetNet.networksType == '1') { // testnet
    //       return false;
    //     } else {
    //       return true;
    //     }
    //   } else {
    //     return true;
    //   }
    // }
  }


  String getTxRecordsApiUrl() {
    String? txUrl = store.settings!.currentNode?.txUrl;
    if(txUrl!=null){
      return txUrl;
    }
    return MAIN_TX_RECORDS_GQL_URL;
  }

  Future<void> refreshNetwork() async {
    assets.fetchAccountInfo();
    staking.refreshStaking();
    assets.fetchPendingTransactions(store.wallet!.currentAddress);
    assets.fetchTransactions(store.wallet!.currentAddress);
  }

  Future<GqlResult> gqlRequest(dynamic options,
      {required BuildContext context, int timeout = 20}) async {
    QueryResult? result;
    Future<QueryResult> req;
    if (options is MutationOptions) {
      req = graphQLClient.mutate(options);
    } else {
      req = graphQLClient.query(options);
    }
    AppLocalizations dic = AppLocalizations.of(context)!;
    try {
      result = await req.timeout(Duration(seconds: timeout));
    } on TimeoutException catch (_) {
      return GqlResult(result: null, error: true, errorMessage: dic.timeout);
    }
    if (result!.hasException) {
      print('gql出错了：' + result.exception.toString());
      String message = '';
      if (result.exception!.graphqlErrors.length > 0) {
        message = result.exception!.graphqlErrors[0].message;
      } else {
        message = result.exception.toString();
      }
      return GqlResult(result: null, error: true, errorMessage: message);
    }
    return GqlResult(result: result);
  }
}

class GqlResult {
  GqlResult({this.result, this.error = false, this.errorMessage = ''});

  QueryResult? result;
  final bool error;
  final String errorMessage;
}
