import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:daisy/configs/novel_background_color.dart';
import 'package:daisy/ffi.dart';
import 'package:daisy/screens/components/content_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../configs/novel_font_color.dart';
import '../configs/novel_font_size.dart';
import 'components/content_loading.dart';
import 'components/novel_fan_component.dart';

class NovelReaderScreen extends StatefulWidget {
  final NovelDetail novel;
  final NovelVolume volume;
  final NovelChapter chapter;
  final List<NovelVolume> volumes;

  const NovelReaderScreen({
    required this.novel,
    required this.volume,
    required this.chapter,
    required this.volumes,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NovelReaderScreenState();
}

class _NovelReaderScreenState extends State<NovelReaderScreen> {
  late Future<String> _contentFuture;
  late String texts = "";
  List<String> chapterTexts = [];
  late int fIndex = 0;

  List<String> _reRenderTextIn(String bookText) {
    bookText = bookText.replaceAll("<br />\n", "\n");
    bookText = bookText.replaceAll("<br />\n", "\n");
    bookText = bookText.replaceAll("<br />", "\n");
    bookText = bookText.replaceAll("<br/>", "\n");
    bookText = bookText.replaceAll("&nbsp;", " ");
    bookText = bookText.replaceAll("&amp;", "&");
    bookText = bookText.replaceAll("&hellip;", "…");
    bookText = bookText.replaceAll("&bull;", "·");
    bookText = bookText.replaceAll("&lt;", "<");
    bookText = bookText.replaceAll("&gt;", ">");
    bookText = bookText.replaceAll("&quot;", "\"");
    bookText = bookText.replaceAll("&copy;", "©");
    bookText = bookText.replaceAll("&reg;", "®");
    bookText = bookText.replaceAll("&times;", "×");
    bookText = bookText.replaceAll("&pide;", "÷");
    bookText = bookText.replaceAll("&emsp;", " ");
    bookText = bookText.replaceAll("&ensp;", " ");
    bookText = bookText.replaceAll("&ldquo;", "“");
    bookText = bookText.replaceAll("&rdquo;", "”");
    bookText = bookText.replaceAll("&mdash;", "—");
    bookText = bookText.replaceAll("&middot;", "·");
    bookText = bookText.replaceAll("&lsquo;", "‘");
    bookText = bookText.replaceAll("&rsquo;", "’");

    bookText = bookText.trim();
    // 切割文字????s
    final _mq = MediaQuery.of(context);
    final _width = _mq.size.width
        // 左右间距15
        -
        30;
    final _height = _mq.size.height
        // edge 间距
        // 顶部章节名称间距
        -
        50
        // 底部时间间距
        -
        50;

    List<String> texts = [];
    while (true) {
      final tryRender = bookText.substring(
        0,
        min(1000, bookText.length),
      );
      final span = TextSpan(
        text: tryRender,
        style: TextStyle(
          fontSize: 14 * novelFontSize,
          height: 1.2,
        ),
      );
      final max = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      max.layout(maxWidth: _width);
      int endOffset = max
          .getPositionForOffset(
              Offset(_width, _height - 14 * novelFontSize * 1.2))
          .offset;
      texts.add(
        bookText.substring(
          0,
          endOffset,
        ),
      );
      bookText = bookText.substring(endOffset).trim();
      if (bookText.isEmpty) {
        break;
      }
    }
    return texts;
  }

  resetFont() {
    var z = 0;
    for (var i = 0; i < fIndex; i++) {
      z += chapterTexts[i].length;
    }
    chapterTexts = _reRenderTextIn(texts);
    fIndex = 0;
    var y = 0;
    for (var i = 0; i < chapterTexts.length; i++) {
      if (y >= z) {
        fIndex = i;
        break;
      }
      y += chapterTexts[i].length;
    }
  }

  @override
  void initState() {
    native.novelViewPage(
      novelId: widget.novel.id,
      volumeId: widget.volume.id,
      volumeTitle: widget.volume.title,
      volumeOrder: widget.volume.rank,
      chapterId: widget.chapter.chapterId,
      chapterTitle: widget.chapter.chapterName,
      chapterOrder: widget.chapter.chapterOrder,
      progress: 0,
    );
    _contentFuture = native
        .novelContent(
      volumeId: widget.volume.id,
      chapterId: widget.chapter.chapterId,
    )
        .then((value) {
          texts = value;
      chapterTexts = _reRenderTextIn(value);
      return value;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _contentFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.chapter.chapterName),
            ),
            body: ContentError(
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
              onRefresh: () async {
                setState(() {
                  _contentFuture = native
                      .novelContent(
                    volumeId: widget.volume.id,
                    chapterId: widget.chapter.chapterId,
                  )
                      .then((value) {
                    texts = value;
                    chapterTexts = _reRenderTextIn(value);
                    return value;
                  });
                });
              },
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.chapter.chapterName),
            ),
            body: const ContentLoading(),
          );
        }

        return _buildReader(snapshot.requireData);
      },
    );
  }

  bool _inFullScreen = false;

  bool get _fullScreen => _inFullScreen;

  set _fullScreen(bool val) {
    _inFullScreen = val;
    if (Platform.isIOS || Platform.isAndroid) {
      if (val) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [],
        );
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
    }
  }

  Widget _buildReader(String text) {
    return Scaffold(
      body: StatefulBuilder(
        builder: (
          BuildContext context,
          void Function(void Function()) setState,
        ) {
          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _fullScreen = !_fullScreen;
                  });
                },
                child: Container(
                  color: getNovelBackgroundColor(context),
                  child: move(), //_buildHtmlViewer(text),
                ),
              ),
              ..._fullScreen
                  ? []
                  : [
                      Column(
                        children: [
                          AppBar(
                            backgroundColor: Colors.black.withOpacity(.5),
                            title: Text(widget.chapter.chapterName),
                            actions: [
                              IconButton(
                                onPressed: _onChooseEp,
                                icon: const Icon(Icons.menu_open),
                              ),
                              IconButton(
                                onPressed: _bottomMenu,
                                icon: const Icon(Icons.more_horiz),
                              )
                            ],
                          ),
                          Expanded(child: Container()),
                        ],
                      ),
                    ],
            ],
          );
        },
      ),
    );
  }

  Future _onChooseEp() async {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * (.45),
          child: _EpChooser(
            widget.novel,
            widget.volume,
            widget.chapter,
            widget.volumes,
            onChangeEp,
          ),
        );
      },
    );
  }

  void _bottomMenu() async {
    await showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * (.45),
          child: ListView(
            children: [
              Row(
                children: [
                  _bottomIcon(
                    icon: Icons.text_fields,
                    title: novelFontSize.toString(),
                    onPressed: () async {
                      await modifyNovelFontSize(context);
                      resetFont();
                      setState(() => {});
                    },
                  ),
                  _bottomIcon(
                    icon: Icons.format_color_text,
                    title: "颜色",
                    onPressed: () async {
                      await modifyNovelFontColor(context);
                      setState(() => {});
                    },
                  ),
                  _bottomIcon(
                    icon: Icons.format_shapes,
                    title: "颜色",
                    onPressed: () async {
                      await modifyNovelBackgroundColor(context);
                      setState(() => {});
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomIcon({
    required IconData icon,
    required String title,
    required void Function() onPressed,
  }) {
    return Expanded(
      child: Center(
        child: Column(
          children: [
            IconButton(
              iconSize: 55,
              icon: Column(
                children: [
                  Container(height: 3),
                  Icon(
                    icon,
                    size: 25,
                    color: Colors.white,
                  ),
                  Container(height: 3),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  Container(height: 3),
                ],
              ),
              onPressed: onPressed,
            )
          ],
        ),
      ),
    );
  }

  Future onChangeEp(NovelDetail n, NovelVolume v, NovelChapter c) async {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (BuildContext context) => NovelReaderScreen(
        novel: n,
        volume: v,
        chapter: c,
        volumes: widget.volumes,
      ),
    ));
  }

  final _nfController = NovelFanComponentController();

  Widget move() {
    return NovelFanComponent(
      controller: _nfController,
      previous: _movePrevious(),
      current: _moveCurrent(),
      next: _moveNext(),
      onNextSetState: _moveOnNextSetState,
      onPreviousSetState: _moveOnPreviousSetState,
    );
  }

  void _moveOnPreviousSetState() {
    if (fIndex > 0) {
      fIndex--;
    }
    print(fIndex);
    setState(() {});
  }

  void _moveOnNextSetState() {
    if (fIndex < chapterTexts.length - 1) {
      fIndex++;
    }
    print(fIndex);
    setState(() {});
  }

  Widget? _movePrevious() {
    if (fIndex != 0) {
      return page(
        chapterTexts[fIndex - 1],
      );
    }
    return null;
  }

  Widget _moveCurrent() {
    return page(
      chapterTexts[fIndex],
    );
  }

  Widget? _moveNext() {
    if (fIndex >= chapterTexts.length - 1) {
      return null;
    }
    return page(
      chapterTexts[fIndex + 1],
    );
  }

  Widget page(String text) {
    final _mq = MediaQuery.of(context);
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: getNovelBackgroundColor(context),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              offset: Offset(0.0, 15.0), //阴影xy轴偏移量
              blurRadius: 15.0, //阴影模糊程度
              spreadRadius: 1.0 //阴影扩散程度
              ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 50 + 36,
          bottom: 50,
          left: 15,
          right: 15,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14 * novelFontSize,
            height: 1.2,
            color: getNovelFontColor(context),
          ),
        ),
      ),
    );
  }
}

class _EpChooser extends StatefulWidget {
  final NovelDetail novel;
  final NovelVolume volume;
  final NovelChapter chapter;
  final List<NovelVolume> volumes;
  final FutureOr Function(NovelDetail, NovelVolume, NovelChapter) onChangeEp;

  const _EpChooser(
    this.novel,
    this.volume,
    this.chapter,
    this.volumes,
    this.onChangeEp,
  );

  @override
  State<StatefulWidget> createState() => _EpChooserState();
}

class _EpChooserState extends State<_EpChooser> {
  int position = 0;
  List<Widget> widgets = [];

  @override
  void initState() {
    for (var c in widget.volumes) {
      widgets.add(Container(
        margin: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 5),
        child: Text(
          c.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
      final cd = [...c.chapters];
      cd.sort((o1, o2) => o1.chapterOrder - o2.chapterOrder);
      for (var ci in c.chapters) {
        if (widget.chapter.chapterId == ci.chapterId) {
          position = widgets.length > 2 ? widgets.length - 2 : 0;
        }
        widgets.add(Container(
          margin: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
          decoration: BoxDecoration(
            color: widget.chapter.chapterId == ci.chapterId
                ? Colors.grey.withAlpha(100)
                : null,
            border: Border.all(
              color: const Color(0xff484c60),
              style: BorderStyle.solid,
              width: .5,
            ),
          ),
          child: MaterialButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onChangeEp(widget.novel, c, ci);
            },
            textColor: Colors.white,
            child: Text(ci.chapterName),
          ),
        ));
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      initialScrollIndex: position,
      itemCount: widgets.length,
      itemBuilder: (BuildContext context, int index) => widgets[index],
    );
  }
}
