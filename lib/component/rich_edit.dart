
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum RichEditDataType { TEXT, IMAGE, VIDEO }

class RichEditData {
  RichEditDataType type;
  var data;

  RichEditData(this.type, this.data);
}

abstract class RichEditController {
  final List<RichEditData> _data = List.of({RichEditData(RichEditDataType.TEXT, "")});

  final TextStyle textStyle;
  final InputDecoration inputDecoration;
  final Icon deleteIcon;
  final Icon imageIcon;
  final Icon videoIcon;
  final bool isImageIcon;
  final bool isVideoIcon;

  RichEditController({
    this.textStyle,
    InputDecoration inputDecoration,
    Icon deleteIcon,
    Icon imageIcon,
    Icon videoIcon,
    bool isImageIcon = true,
    bool isVideoIcon = true,
  })  : deleteIcon = deleteIcon ?? Icon(Icons.cancel),
        inputDecoration = inputDecoration ??
            InputDecoration(
              hintText: "点击可输入内容..",
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
        imageIcon = imageIcon ?? Icon(Icons.image),
        videoIcon = videoIcon ?? Icon(Icons.videocam),
        isImageIcon = videoIcon ?? true,
        isVideoIcon = videoIcon ?? true;

  addImage();

  addVideo();

  generateImageView(RichEditData data);

  generateVideoView(RichEditData data);

  String generateHtml() {
    StringBuffer sb = StringBuffer();
    _data.forEach((element) {
      switch (element.type) {
        case RichEditDataType.TEXT:
          generateTextHtml(sb, element);
          break;
        case RichEditDataType.IMAGE:
          generateImageHtml(sb, element);
          break;
        case RichEditDataType.VIDEO:
          generateVideoHtml(sb, element);
          break;
      }
    });
    return sb.toString();
  }

  String remStringHtml(text) {
    RegExp reg = new RegExp("<[^>]*>");
    Iterable<RegExpMatch> matches = reg.allMatches(text);
    String value = "";

    matches.forEach((m) {
      value = m.input.toString().replaceAll(reg, "");
    });

    return value;
  }

  List generateView(String html) {
    RegExp regDom = new RegExp('<[img|p|div].*?>([^\<]*?)<\/[img|p|div]>');
    RegExp regDomImg = new RegExp('<img.*?src="(.*?)".*?\/?>');
    RegExp regDomImgSrc = new RegExp(" src=\"(.*)\" ");
    RegExp regDomName = new RegExp('<\/[img|p|div]');

    Iterable<RegExpMatch> matches = regDom.allMatches(html);
    Iterable<RegExpMatch> matches2 = regDomImg.allMatches(html);

    if (html == "") {
      return [];
    }

    _data.removeAt(0);

    matches2.forEach((m) {
      String DomContent = m.input.substring(m.start, m.end);
      Iterable<RegExpMatch> rt = regDomImgSrc.allMatches(DomContent);

      rt.forEach((_rt) {
        String src = _rt.input.substring(_rt.start, _rt.end).replaceAll("src=\"","").replaceAll("\"", "");
        _data.add(
          RichEditData(
            RichEditDataType.IMAGE,
            src.trim(),
          ),
        );
      });
    });

    matches.forEach((m) {
      String DomContent = m.input.substring(m.start, m.end);
      Iterable<RegExpMatch> rt = regDomName.allMatches(DomContent);

      print(DomContent);

      rt.forEach((_rt) {
        switch (_rt.input.substring(_rt.start, _rt.end)) {
          case "</div":
          case "</p":
            _data.add(
              RichEditData(
                RichEditDataType.TEXT,
                this.remStringHtml(m.input.substring(m.start, m.end)),
              ),
            );
            break;
          case "</video":
            print(DomContent);
            break;
        }
      });
    });
  }

  void generateTextHtml(StringBuffer sb, RichEditData element) {
    sb.write("<p>");
    sb.write(element.data);
    sb.write("<\/p>");
  }

  void generateImageHtml(StringBuffer sb, RichEditData element) {
    sb.write("<img src=\"");
    sb.write(element.data);
    sb.write("\" />");
  }

  void generateVideoHtml(StringBuffer sb, RichEditData element) {
    sb.write("<p>");
    sb.write('''
          <video src="${element.data}" playsinline="true" webkit-playsinline="true" x-webkit-airplay="allow" airplay="allow" x5-video-player-type="h5" x5-video-player-fullscreen="true" x5-video-orientation="portrait" controls="controls"  style="width: 100%;height: 300px;"></video>
          ''');
    sb.write("<\/p>");
  }

  List<RichEditData> getDataList() {
    return _data;
  }
}

class RichEdit extends StatefulWidget {
  final RichEditController controller;

  RichEdit(
    this.controller, {
    Key key,
  }) : super(key: key);

  @override
  RichEditState createState() => new RichEditState();
}

class RichEditState extends State<RichEdit> {
  ScrollController _controller;
  Map<int, FocusNode> focusNodes = Map();
  Map<int, TextEditingController> textControllers = Map();

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    focusNodes.clear();
    textControllers.clear();
    return Stack(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(
            bottom: 50,
          ),
          child: ListView.builder(
            controller: _controller,
            itemCount: widget.controller._data.length,
            itemBuilder: (context, index) {
              var data = widget.controller._data[index];
              Widget item = Container();
              switch (data.type) {
                case RichEditDataType.TEXT:
                  var fn = FocusNode();
                  var textEditingController = TextEditingController.fromValue(TextEditingValue(text: data.data));
                  textControllers[index] = textEditingController;
                  focusNodes[index] = fn;
                  item = Container(
                    child: TextField(
                      style: widget.controller.textStyle,
                      focusNode: fn,
                      controller: textEditingController,
                      maxLines: 50,
                      minLines: 1,
                      onChanged: (s) {
                        widget.controller._data[index].data = s;
                      },
                      decoration: widget.controller.inputDecoration,
                    ),
                  );
                  break;
                case RichEditDataType.IMAGE:
                  item = Container(
                    child: Stack(
                      children: <Widget>[
                        widget.controller.generateImageView(data),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: Icon(Icons.cancel),
                            onPressed: () {
                              remove(index);
                            },
                          ),
                        )
                      ],
                    ),
                  );
                  break;
                case RichEditDataType.VIDEO:
                  item = Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            remove(index);
                          },
                        ),
                        widget.controller.generateVideoView(data),
                      ],
                    ),
                  );
              }
              return item;
            },
          ),
        ),
        Positioned(
          child: Container(
            height: 50,
            color: Color(0xfff2f2f2),
            child: Row(
              children: <Widget>[
                Offstage(
                  offstage: !widget.controller.isImageIcon,
                  child: IconButton(
                      icon: widget.controller.imageIcon,
                      onPressed: () async {
                        String path = await widget.controller.addImage();
                        if (path != null) {
                          addView(
                            RichEditData(RichEditDataType.IMAGE, path),
                          );
                        }
                      }),
                ),
                Offstage(
                  offstage: !widget.controller.isVideoIcon,
                  child: IconButton(
                      icon: widget.controller.videoIcon,
                      onPressed: () async {
                        String path = await widget.controller.addVideo();
                        if (path != null) {
                          addView(
                            RichEditData(
                              RichEditDataType.VIDEO,
                              path,
                            ),
                          );
                        }
                      }),
                ),
              ],
            ),
          ),
          left: 0,
          right: 0,
          bottom: 0,
        )
      ],
    );
  }

  void remove(int index) {
    var next = widget.controller._data[index + 1];
    if (next != null && next.data == "") {
      widget.controller._data.removeAt(index + 1);
      widget.controller._data.removeAt(index);
    } else if (index > 0) {
      var pre = widget.controller._data[index - 1];
      if (pre.type == RichEditDataType.TEXT) {
        pre.data += "\n${next.data}";
      }
      widget.controller._data.removeAt(index);
    }

    setState(() {});
  }

  void addView(RichEditData richEditData) {
    int insertIndex = widget.controller._data.length;
    String text = "";
    focusNodes.forEach((key, value) {
      if (value.hasFocus) {
        insertIndex = key + 1;
        var textController = textControllers[key];
        text = textController.selection.textAfter(textController.text);
        widget.controller._data[key].data = textController.text.substring(0, textController.text.length - text.length);
      }
    });
    widget.controller._data.insert(insertIndex, richEditData);
    widget.controller._data.insert(insertIndex + 1, RichEditData(RichEditDataType.TEXT, text));
    setState(() {});
  }
}