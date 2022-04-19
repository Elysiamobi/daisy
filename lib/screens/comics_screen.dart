import 'package:daisy/screens/about_screen.dart';
import 'package:daisy/screens/app_screen.dart';
import 'package:daisy/screens/comic_history_screen.dart';
import 'package:daisy/screens/components/badged.dart';
import 'package:flutter/material.dart';
import 'package:daisy/screens/comic_browser_screen.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';

import 'comic_search_screen.dart';
import 'novels_screen.dart';

class ComicsScreen extends StatefulWidget {
  const ComicsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicsScreenState();
}

class _ComicsScreenState extends State<ComicsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _pageIndex = 1;
  late final _controller = PageController(initialPage: _pageIndex);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navIndexModified(int index) {
    setState(() {
      _pageIndex = index;
    });
  }

  void _navButtonPressed(int index) {
    setState(() {
      _pageIndex = index;
      _controller.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _searchBar.build(context),
      body: PageView(
        controller: _controller,
        onPageChanged: _navIndexModified,
        children: _navPages.map((e) => e.screen).toList(),
      ),
    );
  }

  AppBar _buildDefaultAppBar(BuildContext context) {
    List<Widget> actions = [];
    actions.add(MaterialButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => const AboutScreen(),
          ),
        );
      },
      child: Column(children: [
        Expanded(child: Container()),
        VersionBadged(
          child: Icon(Icons.settings, color: Colors.white70.withAlpha(150)),
        ),
        Text(
          "设置",
          style: TextStyle(
            fontSize: 10,
            color: Colors.white70.withAlpha(150),
          ),
        ),
        Expanded(child: Container()),
      ]),
      minWidth: 50,
    ));
    actions.add(MaterialButton(
      onPressed: () {
        appScreenEvent.broadcast(jumpToNovel);
      },
      child: Column(children: [
        Expanded(child: Container()),
        Icon(Icons.loop, color: Colors.white70.withAlpha(150)),
        Text(
          "切换",
          style: TextStyle(
            fontSize: 10,
            color: Colors.white70.withAlpha(150),
          ),
        ),
        Expanded(child: Container()),
      ]),
      minWidth: 50,
    ));
    for (var i = 0; i < _navPages.length; i++) {
      var index = i;
      final color =
          _pageIndex == i ? Colors.white : Colors.white70.withAlpha(150);
      final background =
          _pageIndex == i ? Colors.white.withAlpha(20) : Colors.transparent;
      actions.add(Container(
        color: background,
        child: MaterialButton(
          onPressed: () {
            _navButtonPressed(index);
          },
          child: Column(children: [
            Expanded(child: Container()),
            Icon(_navPages[i].icon, color: color),
            Text(
              _navPages[i].title,
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
            Expanded(child: Container()),
          ]),
          minWidth: 50,
        ),
      ));
    }
    actions.add(MaterialButton(
      onPressed: () {
        _searchBar.beginSearch(context);
      },
      child: Column(children: [
        Expanded(child: Container()),
        const Icon(Icons.search, color: Colors.white),
        const Text(
          "搜索",
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
          ),
        ),
        Expanded(child: Container()),
      ]),
      minWidth: 50,
    ));
    return AppBar(
      title: const Text("漫画"),
      actions: actions,
    );
  }

  late final TextEditingController _textEditController =
      TextEditingController(text: '');

  late final SearchBar _searchBar = SearchBar(
    hintText: '搜索',
    controller: _textEditController,
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComicSearchScreen(value),
          ),
        );
      }
    },
    buildDefaultAppBar: _buildDefaultAppBar,
  );
}

class NavPage {
  final Widget screen;
  final String title;
  final IconData icon;

  const NavPage({
    required this.screen,
    required this.title,
    required this.icon,
  });
}

const _navPages = [
  NavPage(
    screen: ComicHistoryScreen(),
    title: "历史",
    icon: Icons.history,
  ),
  NavPage(screen: ComicBrowserScreen(), title: "浏览", icon: Icons.blur_linear),
];
