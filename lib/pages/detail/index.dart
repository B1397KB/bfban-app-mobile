/// 举报信息详情

import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:bfban/component/_Time/index.dart';
import 'package:bfban/pages/not_found/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluro/fluro.dart';
import 'package:flutter_elui_plugin/elui.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:bfban/data/index.dart';
import 'package:bfban/constants/api.dart';
import 'package:bfban/utils/index.dart';
import 'package:bfban/widgets/index.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../component/_bfvHackers/index.dart';
import '../../component/_gamesTag/index.dart';
import '../../component/_recordLink/index.dart';
import '../../provider/userinfo_provider.dart';
import 'time_line.dart';

class PlayerDetailPage extends StatefulWidget {
  /// User Db id
  String? dbId;

  /// EA persona Id
  String? personaId;

  PlayerDetailPage({
    Key? key,
    this.dbId,
    this.personaId,
  }) : super(key: key);

  @override
  _PlayerDetailPageState createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> with TickerProviderStateMixin {
  GlobalKey<TimeLineState> timeLineKey = GlobalKey<TimeLineState>();

  UrlUtil _urlUtil = UrlUtil();

  Storage storage = Storage();

  /// 作弊者参数
  PlayerStatus playerStatus = PlayerStatus(
    load: true,
    data: PlayerStatusData(),
    parame: PlayerParame(
      history: true,
      personaId: "",
    ),
  );

  ViewedStatus viewedStatus = ViewedStatus(
    load: false,
    parame: ViewedStatusParame(),
  );

  /// 异步
  Future? futureBuilder;

  /// TAB导航控制器
  TabController? _tabController;

  /// 导航下标
  int _tabControllerIndex = 0;

  /// 导航个体
  List<Tab> cheatersTabs = <Tab>[const Tab(text: "content"), const Tab(text: "list")];

  /// 曾用名按钮状态 or 列表状态
  Map userNameList = {
    "buttonLoad": false,
    "listLoad": false,
  };

  /// 举报记录
  Widget cheatersRecordWidgetList = Container();

  Map subscribes = {
    "load": false,
    "isThisUserSubscribes": false,
  };

  Map statusColors = {
    0: Colors.green,
    1: Colors.red,
    2: Colors.green,
    3: Colors.yellow,
    4: Colors.grey,
    5: Colors.yellow,
    6: Colors.deepOrangeAccent,
    7: Colors.green,
    8: Colors.green,
    9: Colors.yellow,
  };

  @override
  void initState() {
    super.initState();

    if (widget.personaId != null) playerStatus.parame!.personaId = widget.personaId!;
    if (widget.dbId != null) playerStatus.parame!.dbId = widget.dbId!;
  }

  @override
  void didChangeDependencies() {
    ready();
    super.didChangeDependencies();
  }

  void ready() async {
    _tabController = TabController(vsync: this, length: cheatersTabs.length)
      ..addListener(() {
        setState(() {
          _tabControllerIndex = _tabController!.index;
        });
      });

    if (ProviderUtil().ofUser(context).isLogin) _getUserInfo();
    futureBuilder = _getCheatersInfo();
  }

  /// [Response]
  /// 获取作弊玩家 档案
  Future _getCheatersInfo() async {
    setState(() {
      playerStatus.load = true;
    });

    Response result = await Http.request(
      Config.httpHost["cheaters"],
      parame: playerStatus.parame?.toMap,
      method: Http.GET,
    );

    if (result.data["success"] == 1) {
      final d = result.data["data"];

      setState(() {
        playerStatus.data!.setData(d);
        viewedStatus.parame!.id = d["id"];
      });

      _onViewd();
    } else {
      EluiMessageComponent.error(context)(
        child: Text(result.data.code),
      );
    }

    setState(() {
      playerStatus.load = false;
    });

    return playerStatus.data!.toMap;
  }

  /// [Event]
  /// 更新游览值
  Future _onViewd() async {
    StorageData? viewedData = await storage.get("viewed");
    Map<String, dynamic> viewed = viewedData.value ?? {};
    String? id = viewedStatus.parame!.id.toString();

    if (id.isEmpty) return;

    // 校验,含id且1天内，则不更新游览值
    if (viewed.containsKey(id) && (viewed[id]! < viewed[id]! + 10 * 60 * 60 * 1000)) return;

    Response result = await Http.request(
      Config.httpHost["player_viewed"],
      data: viewedStatus.parame!.toMap,
      method: Http.POST,
    );

    if (result.data["success"] == 1) {
      viewed[id] = DateTime.now().millisecondsSinceEpoch;
      storage.set("viewed", value: viewed);

      setState(() {
        playerStatus.data!.viewNum = playerStatus.data!.viewNum! + 1;
      });
    }
  }

  /// [Event]
  /// 作弊玩家信息 刷新
  Future<void> _onRefreshCheatersInfo() async {
    await _getCheatersInfo();
  }

  /// [Response]
  /// 请求更新用户名称列表
  void _seUpdateUserNameList() async {
    UserInfoProvider provider = ProviderUtil().ofUser(context);

    // 检查登录状态
    if (!provider.checkLogin() && provider.isAdmin) return;

    if (userNameList['buttonLoad'] && playerStatus.data!.originUserId == "" || playerStatus.data!.originUserId == null) {
      return;
    }

    setState(() {
      userNameList["buttonLoad"] = true;
    });

    Response result = await Http.request(
      Config.httpHost["player_update"],
      data: {
        "personaId": playerStatus.data!.originPersonaId,
      },
      method: Http.POST,
    );

    if (result.data["success"] == 1) {
      _getCheatersInfo();

      setState(() {
        userNameList["buttonLoad"] = false;
      });
      return;
    }

    EluiMessageComponent.error(context)(
      child: Text(result.data["message"] ?? result.data["code"]),
    );

    setState(() {
      userNameList["buttonLoad"] = false;
    });
  }

  /// [Response]
  /// 追踪此玩家
  void _onSubscribes(isLogin) async {
    if (subscribes["load"]) return;
    if (!isLogin) {
      _urlUtil.opEnPage(context, "/login/panel");
      return;
    }

    StorageData subscribeData = await storage.get("subscribes");
    List? subscribesLocal = subscribeData.value;
    List? subscribesArray = [];
    subscribesLocal ??= [];

    setState(() {
      subscribes["load"] = true;
    });

    // 取得用户已追踪列表
    if (ProviderUtil().ofUser(context).isLogin) {
      Response userInfoResult = await _getUserInfo();
      if (userInfoResult.data["success"] == 1) subscribesArray.addAll(userInfoResult.data["data"]["subscribes"]);
    }

    // 添加或移除订阅
    if (!subscribesArray.contains(playerStatus.data!.id)) {
      subscribes["isThisUserSubscribes"] = false;
      subscribesArray.add(playerStatus.data!.id);
    } else {
      subscribes["isThisUserSubscribes"] = true;
      subscribesArray.remove(playerStatus.data!.id);
    }

    // 提交
    Response result = await Http.request(
      Config.httpHost["user_me"],
      data: {
        "data": {"subscribes": subscribesArray},
      },
      method: Http.POST,
    );

    if (result.data["success"] == 1) {
      _checkSubscribesStatus(subscribesArray);
      storage.set("subscribes", value: subscribesArray);
    }

    setState(() {
      subscribes["load"] = false;
    });
  }

  /// [Response]
  /// 获取账户信息
  Future<Response> _getUserInfo() async {
    setState(() {
      subscribes["load"] = true;
    });

    Response result = await UserInfoProvider().getUserInfo();

    if (result.data["success"] == 1) {
      _checkSubscribesStatus(result.data["data"]["subscribes"]);
    }

    setState(() {
      subscribes["load"] = false;
    });

    return result;
  }

  /// [Evnet]
  /// 检查订阅状态，并赋予
  void _checkSubscribesStatus(List subscribesList) {
    subscribes["isThisUserSubscribes"] = subscribesList.contains(playerStatus.data!.id);
  }

  /// [Event]
  /// 补充举报用户信息
  dynamic _onReport() {
    return () {
      // 检查登录状态
      if (!ProviderUtil().ofUser(context).checkLogin()) return null;

      String data = jsonEncode({"originName": playerStatus.data!.originName});

      _urlUtil.opEnPage(context, '/report/$data', transition: TransitionType.cupertinoFullScreenDialog).then((value) {
        if (value != null) {
          _getCheatersInfo();
          timeLineKey.currentState?.getTimeline();
          timeLineKey.currentState?.scrollController.jumpTo(timeLineKey.currentState?.scrollController.position.maxScrollExtent as double);
        }
      });
    };
  }

  /// [Event]
  /// 审核人员判决
  dynamic onJudgement() {
    return () {
      // 检查登录状态
      if (!ProviderUtil().ofUser(context).checkLogin()) return;

      _urlUtil.opEnPage(context, "/report/manage/${playerStatus.data!.id}", transition: TransitionType.cupertinoFullScreenDialog).then((value) {
        _getCheatersInfo();
        timeLineKey.currentState?.getTimeline();
        timeLineKey.currentState?.scrollController.jumpTo(timeLineKey.currentState?.scrollController.position.maxScrollExtent as double);
      });
    };
  }

  /// [Event]
  /// 查看图片
  void _onEnImgInfo(context) async {
    String? imageUrl = playerStatus.data!.avatarLink!.toString();

    if (imageUrl.isEmpty) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) {
        return PhotoViewSimpleScreen(
          type: PhotoViewFileType.network,
          imageUrl: imageUrl,
        );
      },
    ));
  }

  /// [Event]
  /// 曾经使用过的名称
  static Widget _updateUserName(BuildContext context, playerInfo) {
    List<DataRow> list = [];

    playerInfo["history"].asMap().keys.forEach((index) {
      var i = playerInfo["history"][index];

      list.add(
        DataRow(
          cells: [
            DataCell(
              SelectableText(i["originName"]),
            ),
            DataCell(
              TimeWidget(data: i["fromTime"]),
            ),
          ],
        ),
      );
    });

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: BorderSide(
          color: Theme.of(context).dividerTheme.color!,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
      child: DataTable(
        sortAscending: true,
        sortColumnIndex: 0,
        columns: [
          DataColumn(
            label: Text(
              FlutterI18n.translate(context, "list.colums.playerId"),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              FlutterI18n.translate(context, "list.colums.updateTime"),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        rows: list,
      ),
    );
  }

  /// [Event]
  /// 分享
  void _onShare(Map i) {
    _urlUtil.onPeUrl(
      "${Config.apiHost["web_site"]!.url}/player/${i["originPersonaId"]}/share",
      mode: LaunchMode.externalApplication,
    );
  }

  /// [Event]
  /// 分享
  void _opEnExplorePlayerDetail(Map i) {
    _urlUtil.onPeUrl(
      "${Config.apiHost["web_site"]!.url}/player/${i["originPersonaId"]}",
      mode: LaunchMode.externalApplication,
    );
  }

  /// [Event]
  /// 用户回复
  dynamic setReply(num type, {timelineItem}) {
    return () {
      // 检查登录状态
      if (!ProviderUtil().ofUser(context).checkLogin()) return;

      String parameter = "";

      switch (type) {
        case 0:
          // 回复
          parameter = jsonEncode({
            "type": type,
            "toCommentId": null,
            "toPlayerId": playerStatus.data!.id,
          });
          break;
        case 1:
          // 回复楼层
          parameter = jsonEncode({
            "type": type,
            "toCommentId": playerStatus.data!.id,
            "toPlayerId": timelineItem["toPlayerId"],
          });
          break;
      }

      _urlUtil.opEnPage(context, "/reply/$parameter", transition: TransitionType.cupertinoFullScreenDialog).then((value) {
        if (value != null) {
          timeLineKey.currentState!.scrollController.jumpTo(timeLineKey.currentState!.scrollController.position.maxScrollExtent);
        }
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    cheatersTabs = <Tab>[
      Tab(text: FlutterI18n.translate(context, "detail.info.cheatersInfo")),
      Tab(text: FlutterI18n.translate(context, "detail.info.timeLine")),
    ];

    return FutureBuilder(
      future: futureBuilder,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        /// 数据未加载完成时
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            if (snapshot.data == null) {
              return const NotFoundPage();
            }

            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomRight,
                      colors: ProviderUtil().ofTheme(context).currentThemeName == "default" ? [Colors.transparent, Colors.black54] : [Colors.transparent, Colors.black12],
                    ),
                  ),
                ),
                title: TabBar(
                  labelStyle: const TextStyle(fontSize: 16),
                  controller: _tabController,
                  tabs: cheatersTabs,
                ),
                elevation: 0,
                actions: <Widget>[
                  PopupMenuButton(
                    icon: Icon(
                      Icons.adaptive.more,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    offset: const Offset(0, 45),
                    onSelected: (value) {
                      switch (value) {
                        case 1:
                          _onShare(snapshot.data);
                          break;
                        case 2:
                          _opEnExplorePlayerDetail(snapshot.data);
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          value: 1,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                Icons.share_outlined,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              const SizedBox(width: 10),
                              Text(FlutterI18n.translate(context, "share.title")),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 2,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                Icons.explore,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              const SizedBox(width: 10),
                              Text(FlutterI18n.translate(context, "app.detail.openExplorePlayerDetail")),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
                centerTitle: true,
              ),

              /// 内容
              body: DefaultTabController(
                length: cheatersTabs.length,
                child: Consumer<UserInfoProvider>(
                  builder: (BuildContext context, UserInfoProvider data, Widget? child) {
                    return TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        RefreshIndicator(
                          edgeOffset: MediaQuery.of(context).padding.top,
                          onRefresh: _onRefreshCheatersInfo,
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: <Widget>[
                              Stack(
                                alignment: AlignmentDirectional.topCenter,
                                children: [
                                  Positioned(
                                    child: Opacity(
                                      opacity: .1,
                                      child: SizedBox(
                                        // width: 800,
                                        height: 350,
                                        child: ShaderMask(
                                          blendMode: BlendMode.dstIn,
                                          shaderCallback: (Rect bounds) {
                                            return const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [Colors.black, Colors.transparent],
                                            ).createShader(Rect.fromLTRB(0, 0, bounds.width, bounds.height));
                                          },
                                          child: EluiImgComponent(
                                            src: snapshot.data!["avatarLink"].toString(),
                                            fit: BoxFit.fitWidth,
                                            width: MediaQuery.of(context).size.width,
                                            height: 350,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: BackdropFilter(
                                      filter: ui.ImageFilter.blur(
                                        sigmaX: 0,
                                        sigmaY: 0,
                                      ),
                                      child: Center(
                                        child: GestureDetector(
                                          onTap: () => _onEnImgInfo(context),
                                          child: Container(
                                            margin: const EdgeInsets.only(top: 100, right: 10, left: 10),
                                            child: Center(
                                              child: Card(
                                                elevation: 0,
                                                clipBehavior: Clip.antiAlias,
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      top: 0,
                                                      child: Image.asset("assets/images/default-player-avatar.jpg"),
                                                    ),
                                                    EluiImgComponent(
                                                      src: snapshot.data!["avatarLink"],
                                                      fit: BoxFit.contain,
                                                      width: 150,
                                                      height: 150,
                                                    ),
                                                    Positioned(
                                                      right: 0,
                                                      bottom: 0,
                                                      child: Container(
                                                        padding: const EdgeInsets.only(top: 40, left: 40, right: 5, bottom: 5),
                                                        decoration: const BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                            colors: [
                                                              Colors.transparent,
                                                              Colors.transparent,
                                                              Colors.black87,
                                                            ],
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.search,
                                                          color: Colors.white70,
                                                          size: 30,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      flex: 1,
                                      child: Row(
                                        children: <Widget>[
                                          /// 用户名称
                                          Expanded(
                                            flex: 1,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SelectableText(
                                                  snapshot.data["originName"] ?? "User Name",
                                                  style: const TextStyle(fontSize: 33),
                                                ),
                                                const SizedBox(height: 2),
                                                Wrap(
                                                  spacing: 5,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: (statusColors[snapshot.data?["status"]] as Color).withOpacity(.3),
                                                        border: Border.all(color: statusColors[snapshot.data?["status"]] as Color),
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                      child: Text(
                                                        FlutterI18n.translate(context, "basic.status.${snapshot.data["status"]}"),
                                                        style: TextStyle(color: statusColors[snapshot.data?["status"]] as Color),
                                                      ),
                                                    ),
                                                    BfvHackersWidget(
                                                      data: snapshot.data,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          OutlinedButton(
                                            onPressed: () => _onSubscribes(data.isLogin),
                                            child: subscribes["load"]
                                                ? ELuiLoadComponent(
                                                    type: "line",
                                                    lineWidth: 1,
                                                    color: Theme.of(context).textTheme.displayMedium!.color!,
                                                    size: 16,
                                                  )
                                                : subscribes["isThisUserSubscribes"]
                                                    ? const Icon(Icons.notifications_off)
                                                    : const Icon(Icons.notifications),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Player Attr
                              SelectionArea(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  child: Wrap(
                                    spacing: 40,
                                    runSpacing: 25,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Opacity(
                                            opacity: .5,
                                            child: Text(
                                              FlutterI18n.translate(context, "detail.info.firstReportTime"),
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          TimeWidget(
                                            data: snapshot.data!["createTime"],
                                            style: const TextStyle(fontSize: 18),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Opacity(
                                            opacity: .5,
                                            child: Text(
                                              FlutterI18n.translate(context, "detail.info.recentUpdateTime"),
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          TimeWidget(
                                            data: snapshot.data!["updateTime"],
                                            style: const TextStyle(fontSize: 18),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Opacity(
                                            opacity: .5,
                                            child: Text(
                                              FlutterI18n.translate(context, "detail.info.viewTimes"),
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "${snapshot.data!["viewNum"]}",
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Opacity(
                                            opacity: .5,
                                            child: Text(
                                              FlutterI18n.translate(context, "basic.button.reply"),
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "${snapshot.data["commentsNum"]}",
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Opacity(
                                            opacity: .5,
                                            child: Text(
                                              FlutterI18n.translate(context, "report.labels.game"),
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          GamesTagWidget(
                                            data: snapshot.data["games"],
                                            size: GamesTagSize.no3,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Opacity(
                                            opacity: .5,
                                            child: Text(
                                              FlutterI18n.translate(context, "signup.form.originId"),
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text("${snapshot.data?["originPersonaId"]}", style: const TextStyle(fontSize: 18))
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          const Opacity(
                                            opacity: .5,
                                            child: Text(
                                              "ID",
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text("${snapshot.data?["id"]}", style: const TextStyle(fontSize: 18))
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Consumer<UserInfoProvider>(
                                builder: (context, data, child) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          FlutterI18n.translate(context, "detail.info.historyID"),
                                          style: TextStyle(
                                            fontSize: FontSize.xLarge.value,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.refresh,
                                            size: 25,
                                          ),
                                          onPressed: () => _seUpdateUserNameList(),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),

                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                child: userNameList['listLoad']
                                    ? EluiVacancyComponent(
                                        title: "-",
                                      )
                                    : _updateUserName(context, snapshot.data),
                              ),

                              RecordLinkWidget(
                                data: snapshot.data,
                              ),

                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                        TimeLine(
                          key: timeLineKey,
                          playerStatus: playerStatus,
                        ),
                      ],
                    );
                  },
                ),
              ),

              /// 底栏
              bottomNavigationBar: SafeArea(
                top: false,
                child: Consumer<UserInfoProvider>(
                  builder: (context, data, child) {
                    return Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
                        border: const Border(
                          top: BorderSide(
                            width: 1.0,
                            color: Colors.black12,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: IndexedStack(
                        index: _tabControllerIndex,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: TextButton(
                                  onPressed: _onReport(),
                                  child: Text(
                                    FlutterI18n.translate(context, "report.title"),
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: TextButton(
                                  onPressed: setReply(0),
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 10,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.message,
                                        color: Colors.orangeAccent,
                                      ),
                                      I18nText(
                                        "basic.button.reply",
                                        child: const Text(
                                          "",
                                          style: TextStyle(fontSize: 14),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 管理员 判决
                              data.isAdmin
                                  ? const SizedBox(
                                      width: 10,
                                    )
                                  : const SizedBox(),
                              data.isAdmin
                                  ? Expanded(
                                      flex: 1,
                                      child: TextButton(
                                        onPressed: onJudgement(),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(FlutterI18n.translate(context, "detail.info.judgement")),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
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
