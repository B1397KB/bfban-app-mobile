import 'package:bfban/component/_cheatMethodsTag/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../component/_gamesTag/index.dart';
import '../../component/_html/htmlWidget.dart';
import '../../utils/date.dart';
import 'cheaters_card_types.dart';
import 'quote_card.dart';
import 'video_link.dart';

/// 举报
class CheatReportsCard extends StatelessWidget {
  // 单条数据
  late dynamic data;

  // 数据数量
  late num maxDataCount;

  // 位置
  late int? index;

  final CardUtil _detailApi = CardUtil();

  final Function onReplySucceed;

  CheatReportsCard({
    Key? key,
    required this.onReplySucceed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TimeLineBaseCard(
      type: TimeLineItemType.report,
      isShowLine: maxDataCount > 1 && index! < maxDataCount,
      header: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 标题
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      children: [
                        TextSpan(
                          text: data["username"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dotted,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              _detailApi.openPlayerDetail(context, data["byUserId"]);
                            },
                        ),
                        TextSpan(
                          text: "\t${FlutterI18n.translate(context, "detail.info.report")}\t",
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: data["toOriginName"] + "\t",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: "${FlutterI18n.translate(context, "detail.info.inGame")}\t",
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        WidgetSpan(
                          child: GamesTagWidget(
                            data: data["cheatGame"],
                            size: GamesTagSize.no2,
                          ),
                        ),
                        TextSpan(
                          text: "\t${FlutterI18n.translate(context, "detail.info.gaming")}\t",
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        WidgetSpan(
                          child: CheatMethodsTagWidget(data: data["cheatMethods"]),
                        ),
                        TextSpan(
                          text: "\t·\t${Date().getTimestampTransferCharacter(data['createTime'])["Y_D_M"]}",
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      headerSecondary: VideoLink(data: data),
      content: HtmlWidget(
        content: data["content"],
        quote: QuoteCard(data: data),
      ),
      bottom: TimeLineItemBottomBtn(
        data: data,
        floor: index,
        isShowShare: true,
        isShowReply: true,
      ),
    );
  }
}
