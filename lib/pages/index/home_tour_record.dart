import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';

import '../../data/index.dart';
import '../../provider/userinfo_provider.dart';
import '../../utils/index.dart';
import '../../widgets/index/cheat_list_card.dart';
import '../../component/_empty/index.dart';

class HomeTourRecordPage extends StatefulWidget {
  const HomeTourRecordPage({Key? key}) : super(key: key);

  @override
  State<HomeTourRecordPage> createState() => _HomeTourRecordPageState();
}

class _HomeTourRecordPageState extends State<HomeTourRecordPage> with AutomaticKeepAliveClientMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  // 列表视图控制器
  final ScrollController _scrollController = ScrollController();

  TourRecordStatus tourRecordStatus = TourRecordStatus(
    load: false,
    list: [],
  );

  Storage storage = Storage();

  StoragePlayer storagePlayer = StoragePlayer();

  bool isEdit = false;

  bool selectAll = false;

  Map selectMap = {};

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    _getTourRecordList();

    super.initState();
  }

  /// [Result]
  /// 获取游览历史
  Future _getTourRecordList() async {
    if (tourRecordStatus.load!) return;

    Map viewed = jsonDecode(await storage.get("viewed")) ?? {};
    List<TourRecordPlayerBaseData>? viewedWidgets = [];
    tourRecordStatus.list!.clear();

    setState(() {
      tourRecordStatus.load = true;
    });

    for (var i in viewed.entries) {
      Map playerData = await storagePlayer.query(i.key);

      if (playerData.isEmpty) return;
      TourRecordPlayerBaseData tourRecordPlayerBaseData = TourRecordPlayerBaseData();
      tourRecordPlayerBaseData.setData(playerData);
      viewedWidgets.add(tourRecordPlayerBaseData);
    }

    setState(() {
      tourRecordStatus.list = viewedWidgets;
      tourRecordStatus.load = false;
    });
  }

  /// [Event]
  /// 下拉刷新方法,为list重新赋值
  Future _onRefresh() async {
    await _getTourRecordList();
  }

  /// [Event]
  /// 下拉 追加数据
  Future _getMore() async {
    await _getTourRecordList();
  }

  /// [Evnet]
  /// 全选
  void _selectAllItem(bool status) async {
    Map selectMap = {};

    setState(() {
      selectAll = status;
    });

    if (isEdit) {
      tourRecordStatus.list!.forEach((i) {
        selectMap.addAll({i.id: status});
      });

      setState(() {
        this.selectMap = selectMap;
      });
    }
  }

  /// [Event]
  /// 选择删除
  void _selectDeleteItem() async {
    if (isEdit && selectMap.isNotEmpty) {
      Map viewed = jsonDecode(await storage.get("viewed") ?? "{}");

      for (var i in selectMap.entries) {
        if (i.value) {
          viewed.remove(i.key.toString());
        }
      }

      storage.set("viewed", value: jsonEncode(viewed));

      await _getTourRecordList();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<UserInfoProvider>(
      builder: (context, data, child) {
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _onRefresh,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: tourRecordStatus.list!.length,
            itemBuilder: (BuildContext context, int index) {
              if (tourRecordStatus.list!.isEmpty) {
                return const EmptyWidget();
              }

              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  height: 35,
                  color: Theme.of(context).primaryColorDark.withOpacity(.1),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: isEdit
                            ? Row(
                                children: [
                                  Checkbox(
                                    value: selectAll,
                                    onChanged: (status) => _selectAllItem(status!),
                                  ),
                                  TextButton(
                                    onPressed: () => _selectDeleteItem(),
                                    child: const Icon(Icons.delete, size: 15),
                                  ),
                                ],
                              )
                            : Container(),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            isEdit = !isEdit;
                          });
                        },
                        child: Text(!isEdit ? FlutterI18n.translate(context, "basic.button.submit") : FlutterI18n.translate(context, "basic.button.cancel")),
                      )
                    ],
                  ),
                );
              }

              return Row(
                children: [
                  if (isEdit)
                    Container(
                      margin: const EdgeInsets.only(left: 15),
                      child: Checkbox(
                        visualDensity: VisualDensity.standard,
                        value: selectMap[tourRecordStatus.list![index].id] ?? false,
                        onChanged: (status) {
                          setState(() {
                            selectMap[tourRecordStatus.list![index].id] = status;
                          });
                        },
                      ),
                    ),
                  Expanded(
                    flex: 1,
                    child: CheatListCard(
                      item: tourRecordStatus.list![index].toMap,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
