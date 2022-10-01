/// 我

import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_elui_plugin/elui.dart';

import 'package:bfban/constants/api.dart';
import 'package:bfban/utils/index.dart';
import 'package:bfban/widgets/index.dart';
import 'package:provider/provider.dart';

import '../../provider/userinfo_provider.dart';

class UserCenterPage extends StatefulWidget {
  final int num;

  const UserCenterPage({
    Key? key,
    this.num = 0,
  }) : super(key: key);

  get getNum {
    return num;
  }

  @override
  _UserCenterPageState createState() => _UserCenterPageState();
}

class _UserCenterPageState extends State<UserCenterPage> {
  final UrlUtil _urlUtil = UrlUtil();

  /// [Response]
  /// 注销用户信息
  Future<void> removeUserInfo(token) async {
    Response result = await Http.request(
      Config.httpHost["account_signout"],
      headers: {
        "x-access-token": token,
      },
      method: Http.POST,
    );

    if (result.data["success"] == 1) {
      // 擦除持久数据
      await removeStorage();

      EluiMessageComponent.success(context)(
        child: const Text("\u6ce8\u9500\u6210\u529f"),
      );
    } else {
      EluiMessageComponent.error(context)(
        child: const Text("\u6ce8\u518c\u9519\u8bef\u002c\u8bf7\u8054\u7cfb\u5f00\u53d1\u8005"),
      );
    }
  }

  /// [Event]
  /// 擦除
  Future removeStorage() async {
    List<Future> Futures = [
      Storage().remove("com.bfban.cookie"),
      Storage().remove("com.bfban.token"),
      Storage().remove("com.bfban.login"),
    ];

    await Future.wait(Futures);

    // 清空 用户状态管理机
    ProviderUtil().ofUser(context).clear();

    return true;
  }

  /// [Event]
  /// 应用设置
  void _opEnSetting() {
    _urlUtil.opEnPage(context, '/my/setting');
  }

  /// [Event]
  /// 前往消息列表
  void _opEnMessage() {
    // 检查登录状态
    if (!ProviderUtil().ofUser(context).checkLogin()) return;

    _urlUtil.opEnPage(context, "/message/list");
  }

  /// [Event]
  /// 前往空间
  _opEnSpace() {
    return () {
      // 检查登录状态
      if (!ProviderUtil().ofUser(context).checkLogin()) return;

      Map userdata = ProviderUtil().ofUser(context).userinfo;

      _urlUtil.opEnPage(context, "/detail/user/${userdata["userId"]}");
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserInfoProvider>(
      builder: (context, data, child) {
        return ListView(
          children: <Widget>[
            /// 用户信息板块
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
              child: Card(
                elevation: 15,
                borderOnForeground: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(
                    color: Theme.of(context).dividerTheme.color!.withOpacity(.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: textLoad(
                                    value: data.userinfo["username"] ?? translate("signin.title"),
                                    fontSize: 20,
                                  ),
                                ),
                                Visibility(
                                  visible: data.isLogin,
                                  child: Text(
                                    "id: ${data.userinfo["userId"]}",
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.subtitle2!.color),
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: _opEnSpace(),
                          ),
                          const SizedBox(height: 20),
                          AnimatedOpacity(
                            opacity: data.isLogin ? 1 : .3,
                            duration: const Duration(seconds: 1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      data.isLogin ? "0" : "-",
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const Text(
                                      "已举报",
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    )
                                  ],
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20),
                                  height: 30,
                                  width: 1,
                                  color: Theme.of(context).dividerTheme.color,
                                ),
                                GestureDetector(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        data.isLogin ? ProviderUtil().ofMessage(context).total.toString() : "-",
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const Text(
                                        "消息",
                                        style: TextStyle(
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                  onTap: () => _opEnMessage(),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20),
                                  height: 30,
                                  width: 1,
                                  color: Theme.of(context).dividerTheme.color,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Wrap(
                                      spacing: 5,
                                      children: !data.isLogin
                                          ? [
                                              EluiTagComponent(
                                                color: EluiTagType.none,
                                                size: EluiTagSize.no2,
                                                theme: EluiTagTheme(
                                                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor!.withOpacity(.2),
                                                ),
                                                value: translate("basic.privilege.none"),
                                              )
                                            ]
                                          : data.userinfo["privilege"].map<Widget>((i) {
                                              return EluiTagComponent(
                                                color: EluiTagType.none,
                                                size: EluiTagSize.no2,
                                                theme: EluiTagTheme(
                                                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor!.withOpacity(.2),
                                                ),
                                                value: translate("basic.privilege.$i"),
                                              );
                                            }).toList(),
                                    ),
                                    Text(
                                      translate("userspace.row.privilege"),
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Visibility(
              visible: data.isLogin,
              child: EluiCellComponent(
                title: "账户",
                label: "管理BFBAN的账户信息",
                theme: EluiCellTheme(
                  titleColor: Theme.of(context).textTheme.subtitle1?.color,
                  labelColor: Theme.of(context).textTheme.subtitle2?.color,
                  linkColor: Theme.of(context).textTheme.subtitle1?.color,
                  backgroundColor: Theme.of(context).cardTheme.color,
                ),
                islink: true,
                onTap: () => _urlUtil.opEnWebView(Config.apiHost["bfban_web_site"] + "/profile/account"),
              ),
            ),
            EluiCellComponent(
              title: "\u7f51\u7ad9\u5730\u5740",
              label: "\u0042\u0046\u0042\u0041\u004e\u8054\u76df\u7f51\u7ad9",
              theme: EluiCellTheme(
                titleColor: Theme.of(context).textTheme.subtitle1?.color,
                labelColor: Theme.of(context).textTheme.subtitle2?.color,
                linkColor: Theme.of(context).textTheme.subtitle1?.color,
                backgroundColor: Theme.of(context).cardTheme.color,
              ),
              islink: true,
              onTap: () => _urlUtil.onPeUrl("https://bfban.com"),
            ),
            EluiCellComponent(
              title: "\u652f\u63f4",
              label: "\u7a0b\u5e8f\u6570\u636e\u7531\u4e0d\u540c\u670d\u52a1\u5546\u63d0\u4f9b",
              theme: EluiCellTheme(
                titleColor: Theme.of(context).textTheme.subtitle1?.color,
                labelColor: Theme.of(context).textTheme.subtitle2?.color,
                linkColor: Theme.of(context).textTheme.subtitle1?.color,
                backgroundColor: Theme.of(context).cardTheme.color,
              ),
              islink: true,
              onTap: () => _urlUtil.opEnPage(context, '/my/support'),
            ),
            const SizedBox(
              height: 20,
            ),
            EluiCellComponent(
              title: translate("setting.title"),
              theme: EluiCellTheme(
                titleColor: Theme.of(context).textTheme.subtitle1?.color,
                labelColor: Theme.of(context).textTheme.subtitle2?.color,
                linkColor: Theme.of(context).textTheme.subtitle1?.color,
                backgroundColor: Theme.of(context).cardTheme.color,
              ),
              islink: true,
              onTap: () => _opEnSetting(),
            ),

            Offstage(
              offstage: !data.isLogin,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 30,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: EluiButtonComponent(
                  child: const Text(
                    "\u6ce8\u9500",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  radius: true,
                  size: ButtonSize.mini,
                  type: ButtonType.error,
                  onTap: () => removeUserInfo(data.getToken.toString()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
