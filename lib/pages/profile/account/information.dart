import 'package:bfban/component/_Time/index.dart';
import 'package:bfban/component/_privilegesTag/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_elui_plugin/_cell/cell.dart';
import 'package:flutter_elui_plugin/_img/index.dart';
import 'package:flutter_elui_plugin/_load/index.dart';
import 'package:flutter_elui_plugin/_message/index.dart';
import 'package:flutter_elui_plugin/_tip/index.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../constants/api.dart';
import '../../../data/index.dart';
import '../../../provider/userinfo_provider.dart';
import '../../../utils/index.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  final UrlUtil _urlUtil = UrlUtil();

  StationUserInfoStatus informationStatus = StationUserInfoStatus(
    load: false,
    data: StationUserInfoData(),
  );

  StationUserInfoData informationDiffData = StationUserInfoData();

  bool saveLoad = false;

  /// 异步
  Future? futureBuilder;

  /// 语言列表
  List languages = [];

  @override
  void initState() {
    ready();
    super.initState();
  }

  void ready() async {
    await getLanguageList();
    futureBuilder = _getUserInfo();
  }

  /// [Response]
  /// 获取账户信息
  Future<Map> _getUserInfo() async {
    setState(() {
      informationStatus.load = true;
    });

    Response result = await UserInfoProvider().getUserInfo();

    if (result.data["success"] == 1) {
      Map d = result.data["data"];
      informationDiffData.setData(d);
      informationStatus.data!.setData(d);
    }

    setState(() {
      informationStatus.load = false;
    });

    return informationStatus.data!.toMap;
  }

  /// [Response]
  /// 保存表单
  void _onSave() async {
    if (saveLoad) return;

    setState(() {
      saveLoad = true;
    });

    Response result = await Http.request(
      Config.httpHost["user_me"],
      method: Http.POST,
      data: {
        "data": {"attr": informationStatus.data!.attr!.toMap}
      },
    );

    if (result.data["success"] == 1) {
      EluiMessageComponent.success(context)(
        child: Text(result.data["code"].toString()),
      );
      setState(() {
        informationDiffData = informationStatus.data!;
      });
    }

    setState(() {
      saveLoad = false;
    });
  }

  /// [Response]
  /// 获取语言列表
  Future getLanguageList() async {
    Response result = await Http.request(
      "config/languages.json",
      httpDioValue: "app_web_site",
      method: Http.GET,
    );

    if (result.data.toString().isNotEmpty) {
      setState(() {
        languages = result.data["child"];
      });
    }

    return true;
  }

  /// [Event]
  /// 对比内容是否修改
  bool _contrastModification(StationUserInfoData a, StationUserInfoData b) {
    int l = 0;
    (a.attr!.toMap as Map).forEach((key, value) {
      if (b.attr!.toMap[key] != value) l += 1;
    });
    return l == 0;
  }

  /// [Event]
  /// 站内用户信息 刷新
  Future<void> _onRefreshUserInfo() async {
    await _getUserInfo();
  }

  /// [Event]
  /// 是否绑定
  bool isBindAccount() {
    StationUserInfoData? formItem = informationStatus.data;
    if (formItem!.origin!.isEmpty) return false;
    if (formItem.origin!.containsKey('originName') || formItem.origin!.containsKey('originUserId')) return true;
    return false;
  }

  /// [Event]
  /// 修改名称
  void _opEnSetUserName() {
    _urlUtil.opEnPage(context, "/account/information/setUserName");
  }

  /// [Event]
  /// 重置密码
  void _opEnChangePassword() {
    _urlUtil.opEnPage(context, "/account/information/changePassword");
  }

  /// [Event]
  /// 头像服务商
  void _opEnWebUserAvatar() {
    _urlUtil.onPeUrl("https://www.gravatar.com");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureBuilder,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        /// 数据未加载完成时
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            return Scaffold(
              appBar: AppBar(
                title: Text(FlutterI18n.translate(context, "app.setting.cell.information.title")),
                actions: [
                  if (!_contrastModification(informationDiffData, informationStatus.data!))
                    IconButton(
                      onPressed: () {
                        _onSave();
                      },
                      icon: saveLoad
                          ? ELuiLoadComponent(
                              type: "line",
                              lineWidth: 2,
                              color: Theme.of(context).textTheme.displayMedium!.color!,
                              size: 20,
                            )
                          : const Icon(Icons.done),
                    )
                ],
              ),
              body: RefreshIndicator(
                onRefresh: _onRefreshUserInfo,
                child: ListView(
                  children: [
                    Form(
                      onChanged: () {
                        setState(() {});
                      },
                      child: Column(
                        children: [
                          EluiCellComponent(
                            title: "Avatar",
                            label: "Avatar support is provided by third parties, click to register",
                            islink: true,
                            onTap: () {
                              _opEnWebUserAvatar();
                            },
                            cont: ClipOval(
                              clipBehavior: Clip.hardEdge,
                              child: informationStatus.data!.toMap.containsKey('userAvatar')
                                  ? EluiImgComponent(
                                      src: informationStatus.data!.userAvatar!,
                                      width: 40,
                                      height: 40,
                                    )
                                  : const CircleAvatar(
                                      minRadius: 4,
                                      child: Icon(
                                        Icons.account_circle,
                                        size: 10.0,
                                      ),
                                    ),
                            ),
                          ),
                          const Divider(height: 5),
                          EluiCellComponent(
                            title: FlutterI18n.translate(context, "signup.form.username"),
                            cont: Row(
                              children: [
                                SelectionArea(
                                  child: Text(
                                    informationStatus.data!.username.toString(),
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                      decorationStyle: TextDecorationStyle.dashed,
                                      decorationThickness: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    _opEnSetUserName();
                                  },
                                  child: const Icon(Icons.edit),
                                )
                              ],
                            ),
                          ),
                          EluiCellComponent(
                            title: FlutterI18n.translate(context, "signup.form.password"),
                            cont: Row(
                              children: [
                                const Text("******"),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    _opEnChangePassword();
                                  },
                                  child: const Icon(Icons.edit),
                                )
                              ],
                            ),
                          ),
                          EluiCellComponent(
                            title: FlutterI18n.translate(context, "account.joinedAt"),
                            cont: Wrap(
                              spacing: 5,
                              children: [
                                const Icon(Icons.date_range, size: 18),
                                TimeWidget(data: informationStatus.data!.joinTime.toString()),
                              ],
                            ),
                          ),
                          EluiCellComponent(
                            title: FlutterI18n.translate(context, "account.lastOnlineTime"),
                            cont: Wrap(
                              spacing: 5,
                              children: [
                                const Icon(Icons.date_range, size: 18),
                                TimeWidget(data: informationStatus.data!.lastOnlineTime.toString()),
                              ],
                            ),
                          ),
                          EluiCellComponent(
                            title: FlutterI18n.translate(context, "profile.account.form.privileges"),
                            cont: Container(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: PrivilegesTagWidget(
                                data: informationStatus.data!.privilege,
                              ),
                            ),
                          ),
                          const Divider(height: 5),
                          if (!isBindAccount())
                            EluiTipComponent(
                              type: EluiTip.warning,
                              child: Wrap(
                                children: [
                                  Text(FlutterI18n.translate(context, "account.bindOrigin.title")),
                                  Text(FlutterI18n.translate(context, "account.bindOrigin.content")),
                                ],
                              ),
                            ),
                          EluiCellComponent(
                            title: FlutterI18n.translate(context, "signup.form.originName"),
                            cont: SelectionArea(
                              child: Text(informationStatus.data!.origin!['originName'].toString()),
                            ),
                          ),
                          EluiCellComponent(
                            title: FlutterI18n.translate(context, "signup.form.originId"),
                            cont: SelectionArea(
                              child: Text(informationStatus.data!.origin!['originUserId'].toString()),
                            ),
                          ),
                          const Divider(height: 5),
                          EluiCellComponent(
                            title: FlutterI18n.translate(context, "profile.account.form.language"),
                            label: FlutterI18n.translate(context, "profile.account.form.languageSyncDescribe"),
                            cont: Container(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: DropdownButton(
                                isDense: false,
                                dropdownColor: Theme.of(context).bottomAppBarTheme.color,
                                style: Theme.of(context).dropdownMenuTheme.textStyle,
                                onChanged: (value) {
                                  setState(() {
                                    informationStatus.data!.attr!.language = value.toString();
                                  });
                                },
                                value: informationStatus.data!.attr!.language,
                                items: languages.map<DropdownMenuItem<String>>((i) {
                                  return DropdownMenuItem(value: i["name"].toString(), child: Text(i["label"].toString()));
                                }).toList(),
                              ),
                            ),
                          ),
                          EluiCellComponent(
                            title: FlutterI18n.translate(context, "profile.account.form.showOrigin"),
                            label: FlutterI18n.translate(context, "profile.account.form.showOriginDescribe"),
                            cont: Checkbox(
                              value: informationStatus.data!.attr!.showOrigin,
                              onChanged: (bool? value) {
                                setState(() {
                                  informationStatus.data!.attr!.showOrigin = !informationStatus.data!.attr!.showOrigin!;
                                });
                              },
                            ),
                          ),
                          EluiCellComponent(
                            title: FlutterI18n.translate(context, "profile.account.form.allowDM"),
                            label: FlutterI18n.translate(context, "profile.account.form.allowDMdescribe"),
                            cont: Checkbox(
                              value: informationStatus.data!.attr!.allowDM,
                              onChanged: (bool? value) {
                                setState(() {
                                  informationStatus.data!.attr!.allowDM = !informationStatus.data!.attr!.allowDM!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          default:
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
        }
      },
    );
  }
}
