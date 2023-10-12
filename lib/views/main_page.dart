import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:pica_comic/tools/background_service.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/category_page.dart';
import 'package:pica_comic/views/explore_page.dart';
import 'package:pica_comic/views/ht_views/home_page.dart';
import 'package:pica_comic/views/jm_views/jm_categories_page.dart';
import 'package:pica_comic/views/jm_views/jm_home_page.dart';
import 'package:pica_comic/views/jm_views/jm_latest_page.dart';
import 'package:pica_comic/views/pic_views/categories_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/leaderboard_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/widgets/custom_navigation_bar.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/will_pop_scope.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import '../network/htmanga_network/htmanga_main_network.dart';
import '../network/update.dart';
import '../foundation/ui_mode.dart';
import 'eh_views/eh_home_page.dart';
import 'pic_views/home_page.dart';
import 'me_page.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class Destination {
  const Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  static const int navigateId = 1;

  static BuildContext? navigatorContext;

  static bool overlayOpen = false;

  static void to(Widget Function() widget) async{
    if(navigatorContext == null){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    Get.to(widget,
        id: navigateId, transition: Transition.fade, preventDuplicates: false);
  }

  static canPop() => Navigator.of(navigatorContext ?? Get.context!).canPop();

  static void back() {
    Get.back(id: navigateId);
  }

  static void Function()? toExplorePage;

  static void toExplorePageAt(int page) async{
    if(appdata.settings[24][page] != "1"){
      showMessage(Get.context!, "探索页面被禁用".tl);
      return;
    }
    if(toExplorePage == null){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    toExplorePage?.call();
    Future.microtask(() async{
      int index = 0;
      for(int i=0; i<page; i++){
        if(appdata.settings[24][i] == "1"){
          index++;
        }
      }
      if(ExplorePage.jumpTo == null){
        await Future.delayed(const Duration(milliseconds: 100));
      }
      ExplorePage.jumpTo?.call(index);
    });
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _i = int.parse(appdata.settings[23]);

  int get i => _i;

  set i(int value) {
    _i = value;
    Navigator.popUntil(Get.nestedKey(1)!.currentContext!, (route) => route.isFirst);
  }

  final pages = [
    const MePage(),
    const ExplorePageWithGetControl(),
    const CategoryPageWithGetControl(),
    const LeaderBoardPage(),
  ];

  void login(){
    network.updateProfile().then((res){
      if(res.error){
        showMessage(Get.context!, "登录哔咔时发生错误:".tl + res.errorMessageWithoutNull);
      }
    });
    jmNetwork.loginFromAppdata().then((res){
      if(res.error){
        showMessage(Get.context!, "登录禁漫时发生错误:".tl + res.errorMessageWithoutNull);
      }
    });
    HtmangaNetwork().loginFromAppdata().then((res){
      if(res.error){
        showMessage(Get.context!, "登录绅士漫画时发生错误:".tl + res.errorMessageWithoutNull);
      }
    });
  }

  void checkUpdates(){
    if (appdata.settings[2] == "1") {
      checkUpdate().then((b) {
        if (b != null) {
          if (b) {
            getUpdatesInfo().then((s) {
              if (s != null) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("有可用更新".tl),
                        content: Text(s),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Get.back();
                                appdata.settings[2] = "0";
                                appdata.writeData();
                              },
                              child: const Text("关闭更新检查")),
                          TextButton(
                              onPressed: () => Get.back(),
                              child: Text("取消".tl)),
                          if (!GetPlatform.isWeb)
                            TextButton(
                                onPressed: () {
                                  getDownloadUrl().then((s) {
                                    launchUrlString(s,
                                        mode: LaunchMode.externalApplication);
                                  });
                                },
                                child: Text("下载".tl))
                        ],
                      );
                    });
              }
            });
          }
        }
      });
    }
  }

  void checkDownload(){
    if (downloadManager.downloading.isNotEmpty) {
      Future.delayed(const Duration(microseconds: 500), () {
        showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text("下载管理器".tl),
                content: Text("有未完成的下载, 是否继续?".tl),
                actions: [
                  TextButton(onPressed: () => Get.back(), child: Text("否".tl)),
                  TextButton(
                      onPressed: () {
                        downloadManager.start();
                        Get.back();
                      },
                      child: Text("是".tl))
                ],
              );
            });
      });
    }
  }

  void initLogic(){
    Get.put(HomePageLogic());
    Get.put(CategoriesPageLogic());
    Get.put(GamesPageLogic());
    Get.put(EhHomePageLogic());
    Get.put(EhPopularPageLogic());
    Get.put(JmHomePageLogic());
    Get.put(JmLatestPageLogic());
    Get.put(JmCategoriesPageLogic());
    Get.put(ExplorePageLogic());
    Get.put(CategoryPageLogic());
    Get.put(HtHomePageLogic());
  }

  void syncData() async{
    var configs = appdata.settings[45].split(';');
    if(configs.length != 4 || configs.elementAtOrNull(0) == ""){
      return;
    }
    showLoadingDialog(context, () {
      Get.back();
    }, false, true, "同步数据中".tl);
    var res = await Webdav.downloadData();
    if(!res){
      Get.back();
      showMessage(Get.context, "Failed to download data",
          action: TextButton(onPressed: () => syncData(), child: Text("重试".tl)));
    }else{
      Get.back();
    }
  }

  @override
  void initState() {
    initLogic();

    login();

    notifications.requestPermission();

    if(appdata.ehAccount != "") {
      EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/favorites.php",
        favoritePage: true);
    }

    if (appdata.firstUse[3] == "0") {
      appdata.firstUse[3] = "1";
      appdata.writeData();
    }
    //清除未正常退出时的下载通知
    try {
      notifications.endProgress();
    } catch (e) {
      //不清楚清除一个不存在的通知会不会引发错误
    }
    //检查是否打卡
    if (appdata.user.isPunched == false && appdata.settings[6] == "1") {
      if (GetPlatform.isMobile) {
        runBackgroundService();
      } else {
        appdata.user.isPunched = true;
        network.punchIn().then((b) {
          if (b) {
            showMessage(Get.context, "打卡成功".tr, useGet: false);
            appdata.user.exp += 10;
          }
        });
      }
    }

    checkUpdates();

    checkDownload();

    MainPage.toExplorePage = () => setState(() => i = 1);

    Future.delayed(const Duration(milliseconds: 300), () => syncData());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //获取热搜
    if (hotSearch.isEmpty || jmNetwork.hotTags.isEmpty) {
      if (jmNetwork.hotTags.isEmpty) {
        jmNetwork.getHotTags();
      }
      if (hotSearch.isEmpty) {
        network.getKeyWords().then((s) {
          if (s.success) {
            hotSearch = s.data;
            try {
              Get.find<PreSearchController>().update();
            } catch (e) {
              //处于搜索页面时更新页面, 否则忽视
            }
          }
        });
      }
    }

    var titles = ["我".tl, "探索".tl, "分类".tl, "排行榜".tl];

    return Scaffold(
      body: CustomWillPopScope(
        action: () {
          if (MainPage.canPop()) {
            MainPage.back();
          } else {
            SystemNavigator.pop();
          }
        },
        popGesture: GetPlatform.isIOS && !UiMode.m1(context),
        child: Row(
          children: [
            NavigateBar(
                index: () => i,
                indexSetter: (index) => setState(() {
                      i = index;
                    })),
            Expanded(
              child: Column(
                children: [
                  if (!UiMode.m1(context))
                    SizedBox(
                      height: MediaQuery.of(context).padding.top,
                    ),
                  Expanded(
                    child: ClipRect(
                      child: Navigator(
                        key: Get.nestedKey(1),
                        onGenerateRoute: (settings) =>
                            MaterialPageRoute(builder: (context) {
                          MainPage.navigatorContext = context;
                          return Column(
                            children: [
                              if (UiMode.m1(context))
                                AppBar(
                                  title: Text(titles[i]),
                                  notificationPredicate: (notifications) =>
                                      notifications.context?.widget is MePage,
                                  actions: [
                                    Tooltip(
                                      message: "搜索".tl,
                                      child: IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: () {
                                          MainPage.to(() => PreSearchPage());
                                        },
                                      ),
                                    ),
                                    Tooltip(
                                      message: "设置".tl,
                                      child: IconButton(
                                        icon: const Icon(Icons.settings),
                                        onPressed: () {
                                          Get.to(() => const SettingsPage());
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              Expanded(
                                child: AnimatedMainPage(
                                  pages[i],
                                  key: Key(i.toString()),
                                ),
                              ),
                              if (UiMode.m1(context))
                                CustomNavigationBar(
                                  onDestinationSelected: (int index) {
                                    setState(() {
                                      i = index;
                                    });
                                  },
                                  selectedIndex: i,
                                  destinations: <NavigationItemData>[
                                    NavigationItemData(
                                      icon: const Icon(Icons.person_outlined),
                                      selectedIcon: const Icon(Icons.person),
                                      label: '我'.tl,
                                    ),
                                    NavigationItemData(
                                      icon: const Icon(Icons.explore_outlined),
                                      selectedIcon: const Icon(Icons.explore),
                                      label: '探索'.tl,
                                    ),
                                    NavigationItemData(
                                      icon: const Icon(
                                          Icons.account_tree_outlined),
                                      selectedIcon:
                                          const Icon(Icons.account_tree),
                                      label: '分类'.tl,
                                    ),
                                    NavigationItemData(
                                      icon: const Icon(
                                          Icons.leaderboard_outlined),
                                      selectedIcon:
                                          const Icon(Icons.leaderboard),
                                      label: '排行榜'.tl,
                                    ),
                                  ],
                                )
                            ],
                          );
                        }),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigatorItem extends StatelessWidget {
  const NavigatorItem(
      this.icon, this.selectedIcon, this.title, this.selected, this.onTap,
      {Key? key})
      : super(key: key);
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final void Function() onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    double? size;
    final theme = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                color: selected ? theme.secondaryContainer : null),
            height: 56,
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                ),
                Icon(
                  selected ? selectedIcon : icon,
                  color: theme.onSurfaceVariant,
                  size: size,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(title)
              ],
            ),
          ),
        ));
  }
}

class AnimatedMainPage extends StatefulWidget {
  const AnimatedMainPage(this.widget, {super.key});

  final Widget widget;

  @override
  State<AnimatedMainPage> createState() => _AnimatedMainPageState();
}

class _AnimatedMainPageState extends State<AnimatedMainPage> {
  var offset = const Offset(0, 0.05);

  static bool initial = true;

  @override
  void initState() {
    if(!initial) {
      Future.microtask(() => setState(() {
          offset = const Offset(0, 0);
        }));
    }else{
      offset = const Offset(0, 0);
    }
    initial = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: offset,
      curve: Curves.ease,
      duration: const Duration(milliseconds: 300),
      child: widget.widget,
    );
  }
}

class NavigateBar extends StatefulWidget {
  const NavigateBar(
      {required this.index, required this.indexSetter, super.key});

  final void Function(int) indexSetter;

  final int Function() index;

  @override
  State<NavigateBar> createState() => _NavigateBarState();
}

class _NavigateBarState extends State<NavigateBar> {
  set i(int i) {
    widget.indexSetter(i);
  }

  int get i => widget.index();

  @override
  Widget build(BuildContext context) {
    if (UiMode.m3(context)) {
      return SafeArea(
          child: Container(
        width: 340,
        height: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.fromLTRB(28, 0, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                          backgroundImage: AssetImage("images/app_icon.png")),
                      SizedBox(
                        width: 16,
                      ),
                      Text(
                        "Pica Comic",
                        style: TextStyle(fontFamily: "font2", fontSize: 18),
                      )
                    ],
                  ),
                ),
              ),
            ),
            NavigatorItem(Icons.person_outlined, Icons.person, "我".tl, i == 0,
                () => setState(() => i = 0)),
            NavigatorItem(Icons.explore_outlined, Icons.explore, "探索".tl,
                i == 1, () => setState(() => i = 1)),
            NavigatorItem(Icons.account_tree_outlined, Icons.account_tree,
                "分类".tl, i == 2, () => setState(() => i = 2)),
            NavigatorItem(Icons.leaderboard_outlined, Icons.leaderboard,
                "排行榜".tl, i == 3, () => setState(() => i = 3)),
            const Divider(),
            const Spacer(),
            NavigatorItem(Icons.search, Icons.games, "搜索".tl, false,
                () => MainPage.to(() => PreSearchPage())),
            NavigatorItem(
              Icons.settings,
              Icons.games,
              "设置".tl,
              false,
              () => showAdaptiveWidget(
                  context,
                  SettingsPage(
                    popUp: MediaQuery.of(context).size.width > 600,
                  )),
            ),
          ],
        ),
      ));
    } else if (UiMode.m2(context)) {
      return NavigationRail(
        leading: const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: CircleAvatar(
            backgroundImage: AssetImage("images/app_icon.png"),
          ),
        ),
        selectedIndex: i,
        trailing: Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => MainPage.to(() => PreSearchPage()),
                  ),
                ),
                Flexible(
                  child: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => showAdaptiveWidget(
                        context,
                        SettingsPage(
                            popUp: MediaQuery.of(context).size.width > 600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        groupAlignment: -1,
        onDestinationSelected: (int index) {
          setState(() {
            i = index;
          });
        },
        labelType: NavigationRailLabelType.all,
        destinations: <NavigationRailDestination>[
          NavigationRailDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: Text('我'.tl),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: Text('探索'.tl),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.account_tree_outlined),
            selectedIcon: const Icon(Icons.account_tree),
            label: Text('分类'.tl),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard),
            label: Text('排行榜'.tl),
          ),
        ],
      );
    }
    return const SizedBox();
  }
}
