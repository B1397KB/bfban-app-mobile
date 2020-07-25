/// 举报信息详情

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluro/fluro.dart';
import 'package:flutter_plugin_elui/elui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bfban/constants/api.dart';
import 'package:bfban/router/router.dart';
import 'package:bfban/utils/index.dart';
import 'package:bfban/widgets/index.dart';

class CheatersPage extends StatefulWidget {
  /// BFBAN举报iD
  final id;

  CheatersPage({
    this.id = "",
  });

  @override
  _CheatersPageState createState() => _CheatersPageState();
}

class _CheatersPageState extends State<CheatersPage> with SingleTickerProviderStateMixin {
  /// 作弊者结果
  Map cheatersInfo = Map();

  /// 作弊者基本信息
  /// 从[cheatersInfo]取的结果，方便取
  Map cheatersInfoUser = Map();

  /// 异步
  Future futureBuilder;

  /// TAB导航控制器
  TabController _tabController;

  /// 滚动控制器
  ScrollController _listViewController = new ScrollController();

  /// 滚动坐标
  num _listViewValue = 0;

  /// 导航个体
  final List<Tab> myTabs = <Tab>[
    Tab(text: '举报信息'),
    Tab(text: '审核记录'),
    Tab(text: '曾用名称'),
  ];

  /// 作弊行为
  static Map cheatingTpyes = Config.cheatingTpyes;

  /// 进度状态
  final List<dynamic> startusIng = Config.startusIng;

  dynamic _login;

  @override
  void initState() {
    super.initState();

    this.ready();

    this._getCheatersInfo();


  }

  void ready () async {
    _login = await Storage.get('com.bfban.login');

    _tabController = TabController(vsync: this, length: myTabs.length);

    _listViewController.addListener(() {
      setState(() {
        _listViewValue = _listViewController.offset;
      });
    });

    futureBuilder = this._getCheatersInfo();
  }

  /// 获取tracker上用户信息
  Future _getTrackerCheatersInfo(String name, List games) async {
    Response result = await Http.request(
      'api/v2/${games[0]["game"]}/standard/profile/origin/$name',
      method: Http.GET,
      typeUrl: "tracker",
    );

//    if (result.data["error"] == 0) {}
  }

  /// 获取bfban用户信息
  Future _getCheatersInfo() async {
    Response result = await Http.request(
      'api/cheaters/${widget.id}',
      method: Http.GET,
    );

    if (result.data != null && result.data["error"] == 0) {
      setState(() {
        cheatersInfo = result.data ?? new Map();
        cheatersInfoUser = result.data["data"]["cheater"][0];
      });

      /// 取最新ID查询
      if (result.data["data"]["origins"].length > 0) {
//        this._getTrackerCheatersInfo(result.data["data"]["origins"][0]["cheaterGameName"], result.data["data"]["games"]);
      }

      return cheatersInfo;
    }
  }

  /// 获取游戏类型
  String _getGames(List games) {
    String t = "";
    games.forEach((element) {
      t += "${element["game"].toString().toUpperCase()} ";
    });
    return t;
  }

  /// 请求更新用户名称列表
  void _seUpdateUserNameList() async {
    if (_login == null) {
      EluiMessageComponent.error(context)(
        child: Text("请先登录BFBAN"),
      );
      return;
    }

    Response result = await Http.request(
      'api/cheaters/updateCheaterInfo',
      method: Http.POST,
    );

    if (result.data["error"] == 0) {
      this._getCheatersInfo();
    } else {
      EluiMessageComponent.error(context)(
        child: Text("请求异常请联系开发者"),
      );
    }
  }

  /// 管理员裁判
  void _onAdminEdit(String uid) {
    if (_login == null) {
      EluiMessageComponent.error(context)(
        child: Text("请先登录BFBAN"),
      );
      return;
    }

    Routes.router.navigateTo(
      context,
      '/edit/manage/$uid',
      transition: TransitionType.cupertino,
    ).then((value) => {
      this._getCheatersInfo()
    });
  }

  /// 获取用户BFBAN中举报数据
  static Widget _getUserInfo(context, Map cheatersInfo, cheatersInfoUser, startusIng) {
    List<Widget> list = [];

    /// 数据
    Map _data = cheatersInfo["data"];

    /// 所有用户回复信息
    List _allReply = new List();

    /// 回答
    (_data["replies"] ?? []).forEach((i) => {
          i["SystemType"] = 0,
          _allReply.add(i),
        });

    /// 举报
    (_data["reports"] ?? []).forEach((i) => {
          i["SystemType"] = 1,
          _allReply.add(i),
        });

    /// 审核
    (_data["verifies"] ?? []).forEach((i) => {
          i["SystemType"] = 2,
          _allReply.add(i),
        });

    /// 赞同。审核员
    (_data["confirms"] ?? []).forEach((i) => {
          i["SystemType"] = 3,
          _allReply.add(i),
        });

    /// 排序时间帖子
    /// 序列化时间
    _allReply.sort((time, timeing) =>
        new Date().getTurnTheTimestamp(time["createDatetime"])["millisecondsSinceEpoch"] -
        new Date().getTurnTheTimestamp(timeing["createDatetime"])["millisecondsSinceEpoch"]);

    _allReply.forEach(
      (i) {
        /// 作弊类型 若干
        List<Widget> _cheatMethods = new List();
        i['cheatMethods'].toString().split(",").forEach((i) {
          _cheatMethods.add(EluiTagComponent(
            value: cheatingTpyes[i] ?? '未知行为',
            size: EluiTagSize.no2,
            color: EluiTagColor.warning,
          ));
        });

        switch (i["SystemType"].toString()) {
          case "0":
            list.add(CheatUserCheaters(i: i));
            break;
          case "1":
            list.add(CheatReports(
              i: i,
              cheatMethods: _cheatMethods,
              cheatersInfo: cheatersInfo,
              cheatersInfoUser: cheatersInfoUser,
            ));
            break;
          case "2":
            list.add(CheatVerifies(
              i: i,
              cheatMethods: _cheatMethods,
              cheatersInfo: cheatersInfo,
              cheatersInfoUser: cheatersInfoUser,
            ));
            break;
          case "3":
            list.add(
              CheatConfirms(
                i: i,
                cheatMethods: _cheatMethods,
                cheatersInfo: cheatersInfo,
                cheatersInfoUser: cheatersInfoUser,
              ),
            );
            break;
        }
      },
    );

    return Column(
      children: list,
    );
  }

  /// 曾经使用过的名称
  static Widget _getUsedname(cheatersInfo) {
    List<TableRow> list = [
      new TableRow(
        children: <Widget>[
          new TableCell(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                '游戏ID',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          new TableCell(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                '更改时间',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ];

    cheatersInfo["data"]["origins"].forEach((i) {
      list.add(
        TableRow(
          children: <Widget>[
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  i["cheaterGameName"],
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  i["createDatetime"],
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });

    return Container(
      color: Colors.black12,
      child: Table(
        border: new TableBorder.all(
          width: 1.0,
          color: Color.fromRGBO(251, 251, 251, 0.01),
        ),
        children: list,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: this.futureBuilder,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        /// 数据未加载完成时
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bk-companion.jpg'),
                fit: BoxFit.fitHeight,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  "",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Opacity(
                      opacity: 0.8,
                      child: textLoad(
                        value: "BFBAN",
                        fontSize: 30,
                      ),
                    ),
                    Text(
                      "Legion of BAN Coalition",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white38,
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        /// 数据完成加载
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bk-companion.jpg'),
              fit: BoxFit.fitHeight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomRight,
                    colors: [Colors.transparent, Colors.black38],
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.share,
                  ),
                  onPressed: () {
                    EluiMessageComponent.success(context)(child: Text("链接已复制到剪切板中, 你可以粘贴到任何地方:D"));
                    Clipboard.setData(
                      ClipboardData(
                        text: 'https://bfban.com/#/cheaters/${cheatersInfoUser["originUserId"]}',
                      ),
                    );
                  },
                ),
              ],
              iconTheme: IconThemeData(
                color: _listViewValue > 0 ? Colors.white : Colors.white,
              ),
              title: _listViewValue > 180
                  ? Text(
                      cheatersInfoUser["originId"].toString(),
                      style: TextStyle(
                        shadows: <Shadow>[
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(1, 2),
                          )
                        ],
                      ),
                    )
                  : null,
              centerTitle: true,
            ),

            /// 内容
            body: DefaultTabController(
              length: myTabs.length,
              child: ListView(
                controller: _listViewController,
                children: <Widget>[
                  /// S 主体框架
                  Container(
                    margin: EdgeInsets.only(
                      top: 100,
                    ),
                    color: Color(0xff111b2b),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        /// S header
                        Row(
                          children: <Widget>[
                            Stack(
                              overflow: Overflow.visible,
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(
                                    left: 100,
                                  ),
                                  color: Color(0xff364e80),
                                  height: 50,
                                  width: MediaQuery.of(context).size.width,

                                  /// Tab 导航
                                  child: TabBar(
                                    unselectedLabelColor: Colors.white38,
                                    labelColor: Colors.yellow,
                                    labelStyle: TextStyle(
                                      fontSize: 15,
                                    ),
                                    indicatorColor: Colors.yellow,
                                    controller: _tabController,
                                    labelPadding: EdgeInsets.only(
                                      left: 0,
                                      right: 0,
                                    ),
                                    tabs: myTabs,
                                    onTap: (i) {
                                      setState(() {
                                        this._tabController.index = i;
                                      });
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: -25,
                                  left: 100,
                                  child: Row(
                                    children: <Widget>[
                                      /// 用户名称
                                      GestureDetector(
                                        child: Text(
                                          cheatersInfoUser["originId"].toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            shadows: <Shadow>[
                                              Shadow(
                                                color: Colors.black12,
                                                offset: Offset(1, 2),
                                              )
                                            ],
                                          ),
                                        ),
                                        onTap: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: cheatersInfoUser["originId"],
                                            ),
                                          );
                                          EluiMessageComponent.success(context)(
                                            child: Text("复制成功"),
                                          );
                                        },
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),

                                      /// 最终状态
                                      Container(
                                        padding: EdgeInsets.only(
                                          left: 5,
                                          right: 5,
                                        ),
                                        margin: EdgeInsets.only(
                                          left: 10,
                                        ),
                                        color: startusIng[int.parse(cheatersInfo["data"]["cheater"][0]["status"])]["c"],
                                        child: Text(
                                          startusIng[int.parse(cheatersInfo["data"]["cheater"][0]["status"])]["s"].toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -30,
                                  left: 10,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(CupertinoPageRoute(
                                        builder: (BuildContext context) {
                                          return PhotoViewSimpleScreen(
                                            imageProvider: NetworkImage(cheatersInfoUser["avatarLink"]),
                                            heroTag: 'simple',
                                          );
                                        },
                                      ));
                                    },
                                    child: Image.network(
                                      cheatersInfoUser["avatarLink"] ?? "",
                                      width: 70,
                                      height: 70,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),

                        /// E header

                        IndexedStack(
                          index: _tabController.index,
                          children: <Widget>[
                            /// S 举报信息
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  color: Colors.black12,
                                  margin: EdgeInsets.only(
                                    top: 20,
                                    left: 10,
                                    right: 10,
                                  ),
                                  padding: EdgeInsets.only(
                                    top: 10,
                                    bottom: 10,
                                    left: 10,
                                    right: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      Container(
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              cheatersInfoUser != null
                                                  ? new Date().getTimestampTransferCharacter(cheatersInfoUser["createDatetime"])["Y_D_M"]
                                                  : "",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            Text(
                                              "第一次举报时间",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              cheatersInfoUser != null
                                                  ? new Date().getTimestampTransferCharacter(cheatersInfoUser["updateDatetime"])["Y_D_M"]
                                                  : "",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            Text(
                                              "最后更新",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  color: Colors.black12,
                                  margin: EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                  ),
                                  padding: EdgeInsets.only(
                                    top: 10,
                                    bottom: 10,
                                    left: 10,
                                    right: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      Container(
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              cheatersInfoUser != null ? cheatersInfo["data"]["cheater"][0]["n"].toString() + "/次" : "",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "围观",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              (cheatersInfo["data"]["reports"].length + cheatersInfo["data"]["verifies"].length)
                                                      .toString() +
                                                  "/条",
                                              //cheatersInfo["data"]["verifies"]
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "回复",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  color: Colors.black12,
                                  margin: EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                  ),
                                  padding: EdgeInsets.only(
                                    top: 10,
                                    bottom: 10,
                                    left: 10,
                                    right: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      Container(
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              cheatersInfo["data"] != null ? this._getGames(cheatersInfo["data"]["games"]) : "",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "被举报游戏",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              "PC",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "游玩平台",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding: EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    top: 20,
                                    bottom: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        "判决",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => this._onAdminEdit(
                                            cheatersInfo["data"]["cheater"][0]["originUserId"]
                                        ),
                                      )
                                    ],
                                  ),
                                ),
//                                (cheatersInfo["data"]["confirms"])
                                cheatersInfo["data"]["confirms"].length > 0
                                    ? Container(
                                        color: Colors.black12,
                                        margin: EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                        ),
                                        padding: EdgeInsets.only(
                                          top: 10,
                                          bottom: 10,
                                          left: 10,
                                          right: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Container(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    cheatersInfo["data"]["confirms"][0]["username"].toString(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                  Text(
                                                    "裁决人",
                                                    style: TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 12,
                                                    ),
                                                  )
                                                ],
                                              ),
                                              padding: EdgeInsets.only(
                                                right: 20,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    left: BorderSide(
                                                      width: 1,
                                                      color: Colors.white12,
                                                    ),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: <Widget>[
                                                    Text(
                                                      "石锤作弊",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 30,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                    Text(
                                                      cheatersInfo["data"]["confirms"][0]["cheatMethods"].toString(),
                                                      style: TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    : Container(
                                        color: Colors.black12,
                                        margin: EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                        ),
                                        padding: EdgeInsets.all(120),
                                        child: Center(
                                          child: Text(
                                            "该玩家没有违规行为",
                                            style: TextStyle(
                                              color: Colors.white12,
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),

                            /// E 举报信息

                            /// S 审核记录
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                /// S记录
//                                Container(
//                                  padding: EdgeInsets.all(20),
//                                  child: Text(
//                                    "管理记录",
//                                    style: TextStyle(
//                                      fontSize: 20,
//                                      fontWeight: FontWeight.bold,
//                                      color: Colors.white,
//                                    ),
//                                  ),
//                                ),
//                                Container(
//                                  color: Colors.white,
//                                  child: Column(
//                                    children: this._getExamineLog(),
//                                  ),
//                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 10),
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    "玩家举报记录",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                _getUserInfo(context, snapshot.data, cheatersInfoUser, startusIng),

                                /// E记录
                              ],
                            ),

                            /// E 审核记录

                            /// S 曾用名称
                            Container(
                              padding: EdgeInsets.only(
                                top: 5,
                                left: 10,
                                right: 10,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Container(
                                          child: Column(
                                        children: <Widget>[
                                          Text(
                                            "过去该用户使用的账户名称",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "如果无法更新列表或获取,仅出现该用户未游玩过该游戏以及已被封禁二种状态.",
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ],
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                      )),
                                      FlatButton.icon(
                                        color: Colors.black12,
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.refresh,
                                          size: 25,
                                          color: Colors.white,
                                        ),
                                        textTheme: ButtonTextTheme.primary,
                                        label: Text(
                                          "刷新",
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        onPressed: () => {
                                          this._seUpdateUserNameList(),
                                        },
                                      )
                                    ],
                                  ),
                                  Container(
                                    child: _getUsedname(snapshot.data),
                                    margin: EdgeInsets.only(
                                      top: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// E 曾用名称

                            /// S 比赛表
                            Column(
                              children: <Widget>[],
                            )

                            /// E 比赛表
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// E 主体框架
                ],
              ),
            ),

            /// 底部栏
            bottomNavigationBar: _tabController.index == 1
                ? Container(
                    decoration: BoxDecoration(
                      color: Color(0xffffffff),
                      border: Border(
                        top: BorderSide(
                          width: 1.0,
                          color: Colors.black12,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: 10,
                      left: 20,
                      right: 20,
                      bottom: 10,
                    ),
                    height: 50,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.message,
                          color: Colors.orangeAccent,
                        ),
                        Expanded(
                            flex: 1,
                            child: GestureDetector(
                              child: Text(
                                "补充证据",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              onTap: () {
                                if (_login == null) {
                                  EluiMessageComponent.error(context)(
                                    child: Text("请先登录BFBAN"),
                                  );
                                  return;
                                }

                                /// 补充（追加）回复
                                Routes.router.navigateTo(
                                  context,
                                  '/reply/${jsonEncode({
                                    "type": 0,
                                    "id": cheatersInfoUser["id"],
                                    "originUserId": cheatersInfoUser["originUserId"],
                                    "userId": cheatersInfo["data"]["reports"][0]["userId"],
                                    "foo": cheatersInfo["data"]["reports"][0]["username"],

                                    /// 取第一条举报信息下的userId
                                  })}',
                                  transition: TransitionType.cupertino,
                                );
                              },
                            ))
                      ],
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// WG九宫格
class detailCellCard extends StatelessWidget {
  final text;
  final value;

  detailCellCard({
    this.text = "",
    this.value = "",
  });

  @override
  Widget build(BuildContext context) {
    throw Column(
      children: <Widget>[
        Text(
          text ?? "",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        )
      ],
    );
  }
}

/// WG单元格
class detailCheatersCard extends StatelessWidget {
  final value;
  final cont;
  final type;
  final onTap;
  final fontSize;

  detailCheatersCard({
    this.value,
    this.cont,
    this.type = '0',
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        color: type == '0' ? Color.fromRGBO(0, 0, 0, .3) : Color.fromRGBO(255, 255, 255, .07),
        padding: EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize ?? 20,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  '$cont',
                  style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, .6),
                    fontSize: 13,
                  ),
                )
              ],
            )
          ],
        ),
      ),
      onTap: onTap != null ? onTap : null,
    );
  }
}
