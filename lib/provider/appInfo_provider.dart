/// 全局状态管理
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/api.dart';
import '../utils/http.dart';
import '../utils/index.dart';

class AppInfoProvider with ChangeNotifier {
  NetwrokConf conf = NetwrokConf();
  AppInfoNetwrokStatus connectivity = AppInfoNetwrokStatus();
}

class AppInfoNetwrokStatus with ChangeNotifier {
  var _connectivity;

  Future init(context) async {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _connectivity = result;
      notifyListeners();
    });
  }

  get CurrentAppNetwrok => _connectivity;

  /// ConnectivityResult.none
  /// 获取连接的网络类型
  Future<ConnectivityResult> getConnectivity() async {
    notifyListeners();
    return _connectivity;
  }

  /// 是否已连接有效网络
  bool isConnectivity() {
    if (_connectivity == null) return true;
    notifyListeners();
    return !(_connectivity == ConnectivityResult.none);
  }
}

class NetwrokConf with ChangeNotifier {
  String? packageName = "netwrok_conf";

  // 从远程服务获取配置
  NetworkConfData data = NetworkConfData(
    confList: ["privilege", "gameName", "cheatMethodsGlossary", "cheaterStatus", "action"],
    privilege: {},
    gameName: {},
    cheatMethodsGlossary: {},
    cheaterStatus: {},
    action: {},
  );

  /// [Event]
  /// 初始化
  Future init() async {
    for (int index = 0; index < data.confList!.length; index++) {
      await getConf(data.confList![index]);
    }

    // 更新类
    Config.game = data.gameName!;
    Config.privilege = data.privilege!;
    Config.cheatMethodsGlossary = data.cheatMethodsGlossary!;
    Config.cheaterStatus = data.cheaterStatus!;
    Config.action = data.action!;

    notifyListeners();
    return Config;
  }

  /// [Response]
  /// 请求获取
  Future getConf(String fileName) async {
    Response result = await Http.request(
      "config/$fileName.json",
      typeUrl: "web_site",
      method: Http.GET,
    );

    switch (fileName) {
      case "gameName":
        data.gameName = result.data;
        break;
      case "action":
        data.action = result.data;
        break;
      case "cheatMethodsGlossary":
        data.cheatMethodsGlossary = result.data;
        break;
      case "cheaterStatus":
        data.cheaterStatus = result.data;
        break;
      case "privilege":
        data.privilege = result.data;
        break;
    }

    return result;
  }
}

// 网络配置
class NetworkConfData {
  List? confList;

  // 身份配置
  Map? privilege;

  // 游戏类型配置
  Map? gameName;

  // 作弊行为配置
  Map? cheatMethodsGlossary;

  Map? cheaterStatus;

  // 判决类型配置
  Map? action;

  NetworkConfData({
    this.confList,
    this.privilege,
    this.gameName,
    this.cheatMethodsGlossary,
    this.cheaterStatus,
    this.action,
  });
}
