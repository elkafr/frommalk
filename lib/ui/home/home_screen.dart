import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:frommalk/custom_widgets/ad_item/ad_item.dart';
import 'package:frommalk/custom_widgets/no_data/no_data.dart';
import 'package:frommalk/custom_widgets/safe_area/page_container.dart';
import 'package:frommalk/locale/app_localizations.dart';

import 'package:frommalk/models/ad.dart';
import 'package:frommalk/models/category.dart';
import 'package:frommalk/providers/home_provider.dart';
import 'package:frommalk/providers/navigation_provider.dart';
import 'package:frommalk/ui/ad_details/ad_details_screen.dart';
import 'package:frommalk/ui/home/widgets/category_item.dart';
import 'package:frommalk/ui/home/widgets/map_widget.dart';
import 'package:frommalk/ui/search/search_bottom_sheet.dart';
import 'package:frommalk/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:frommalk/utils/error.dart';
import 'package:frommalk/providers/navigation_provider.dart';
import 'package:frommalk/providers/auth_provider.dart';
import 'package:frommalk/models/marka.dart';
import 'package:frommalk/custom_widgets/drop_down_list_selector/drop_down_list_selector.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  double _height = 0, _width = 0;
  NavigationProvider _navigationProvider;
  Future<List<CategoryModel>> _categoryList;
  bool _initialRun = true;
  HomeProvider _homeProvider;
  AnimationController _animationController;
  AuthProvider _authProvider;
  Future<List<Marka>> _markaList;
  Marka _selectedMarka;

  @override
  void initState() {
    _animationController = AnimationController(
        duration: Duration(milliseconds: 2000), vsync: this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialRun) {

      _homeProvider = Provider.of<HomeProvider>(context);
      _categoryList = _homeProvider.getCategoryList(
          categoryModel: CategoryModel(
              isSelected: true,
              catId: '0',
              catName: AppLocalizations.of(context).translate('all'),
              catImage: 'assets/images/all.png'));
      _markaList = _homeProvider.getMarkaList();
      _initialRun = false;

    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildBodyItem() {
    return ListView(
      children: <Widget>[
        Container(
            height: _height * 0.18,
            color: Color(0xffF8F8F8),
            padding: EdgeInsets.fromLTRB(5, 15, 10, 0),
            child: FutureBuilder<List<CategoryModel>>(
                future: _categoryList,
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                      return Center(
                        child: SpinKitFadingCircle(color: mainAppColor),
                      );
                    case ConnectionState.active:
                      return Text('');
                    case ConnectionState.waiting:
                      return Center(
                        child: SpinKitFadingCircle(color: mainAppColor),
                      );
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Error(
                          //  errorMessage: snapshot.error.toString(),
                          errorMessage: "حدث خطأ ما ",
                        );
                      } else {
                        if (snapshot.data.length > 0) {
                          return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: snapshot.data.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Consumer<HomeProvider>(
                                    builder: (context, homeProvider, child) {
                                  return InkWell(
                                    onTap: () {
                                      homeProvider
                                          .updateChangesOnCategoriesList(index);
                                      _homeProvider.setEnableSearch(false);
                                    },

                                    child: Container(
                                      width: _width * 0.20,
                                      child: CategoryItem(
                                        category: snapshot.data[index],
                                      ),
                                    ),
                                  );
                                });
                              });
                        } else {
                          return NoData(message: 'لاتوجد نتائج');
                        }
                      }
                  }
                  return Center(
                    child: SpinKitFadingCircle(color: mainAppColor),
                  );
                })),
        Container(
          height: 5,
        ),
        ( _homeProvider.lastSelectedCategory!=null && _homeProvider.lastSelectedCategory.catId=="1")
            ? FutureBuilder<List<Marka>>(
                future: _markaList,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.hasData) {
                      var markaList = snapshot.data.map((item) {
                        return new DropdownMenuItem<Marka>(
                          child: new Text(item.markaName),
                          value: item,
                        );
                      }).toList();
                      return DropDownListSelector(
                        dropDownList: markaList,
                        hint: _homeProvider.currentLang=='ar'?'اختار الماركة':'Select marka',
                        onChangeFunc: (newValue) {
                          FocusScope.of(context).requestFocus(FocusNode());
                          setState(() {
                            _selectedMarka = newValue;
                            _homeProvider.setEnableSearch(true);
                            _homeProvider.setSelectedMarka(_selectedMarka);
                          });
                        },
                        value: _selectedMarka,
                      );
                    } else if (snapshot.hasError) {
                      return Text("${snapshot.error}");
                    }
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }

                  return Center(child: CircularProgressIndicator());
                },
              )
            : Text(
                '',
                style: TextStyle(height: 0),
              ),
        Container(
          height: 5,
        ),
        Container(
            height: _height * 0.68,
            width: _width,
            child:
                Consumer<HomeProvider>(builder: (context, homeProvider, child) {
              return FutureBuilder<List<Ad>>(
                  future: homeProvider.enableSearch
                      ? Provider.of<HomeProvider>(context, listen: true)
                          .getAdsSearchList()
                      : Provider.of<HomeProvider>(context, listen: true)
                          .getAdsList(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                        return Center(
                          child: SpinKitFadingCircle(color: mainAppColor),
                        );
                      case ConnectionState.active:
                        return Text('');
                      case ConnectionState.waiting:
                        return Center(
                          child: SpinKitFadingCircle(color: mainAppColor),
                        );
                      case ConnectionState.done:
                        if (snapshot.hasError) {
                          return Error(
                            //  errorMessage: snapshot.error.toString(),
                            errorMessage: "حدث خطأ ما ",
                          );
                        } else {
                          if (snapshot.data.length > 0) {
                            if (_navigationProvider.mapIsActive) {
                              return MapWidget(adList: snapshot.data);
                            } else {
                              return ListView.builder(
                                  itemCount: snapshot.data.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    var count = snapshot.data.length;
                                    var animation =
                                        Tween(begin: 0.0, end: 1.0).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: Interval(
                                            (1 / count) * index, 1.0,
                                            curve: Curves.fastOutSlowIn),
                                      ),
                                    );
                                    _animationController.forward();
                                    return Container(
                                        height: 145,
                                        width: _width,
                                        child: InkWell(
                                            onTap: () {
                                              _homeProvider.setCurrentAds(snapshot
                                                  .data[index].adsId);
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          AdDetailsScreen(
                                                            ad: snapshot
                                                                .data[index],
                                                          )));
                                            },
                                            child: AdItem(
                                              animationController:
                                                  _animationController,
                                              animation: animation,
                                              ad: snapshot.data[index],
                                            )));
                                  });
                            }
                          } else {
                            return NoData(message: 'لاتوجد نتائج');
                          }
                        }
                    }
                    return Center(
                      child: SpinKitFadingCircle(color: mainAppColor),
                    );
                  });
            }))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _navigationProvider = Provider.of<NavigationProvider>(context);
    _authProvider = Provider.of<AuthProvider>(context);

    final appBar = AppBar(
      backgroundColor: mainAppColor,
      centerTitle: true,
      title: _authProvider.currentLang == 'ar'
          ? Text(
              "الرئيسية",
              style: TextStyle(fontSize: 20),
            )
          : Text("Home", style: TextStyle(fontSize: 20)),
      actions: <Widget>[
        GestureDetector(
            onTap: () {
              showModalBottomSheet<dynamic>(
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20))),
                  context: context,
                  builder: (builder) {
                    return Container(
                        width: _width,
                        height: _height * 0.9,
                        child: SearchBottomSheet());
                  });
            },
            child: Image.asset('assets/images/search.png')),
        GestureDetector(
          child: _navigationProvider.mapIsActive
              ? Image.asset(
                  'assets/images/list.png',
                  color: Colors.white,
                )
              : Image.asset(
                  'assets/images/city.png',
                  color: Colors.white,
                ),
          onTap: () {
            if (_navigationProvider.mapIsActive == false) {
              _navigationProvider.setMapIsActive(true);
            } else {
              _navigationProvider.setMapIsActive(false);
            }
          },
        )
      ],
    );
    _height = MediaQuery.of(context).size.height -
        appBar.preferredSize.height -
        MediaQuery.of(context).padding.top;
    _width = MediaQuery.of(context).size.width;
    _navigationProvider = Provider.of<NavigationProvider>(context);

    return PageContainer(
      child: Scaffold(
        appBar: appBar,
        body: _buildBodyItem(),
      ),
    );
  }
}
