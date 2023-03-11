import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lg_controller/src/blocs/PageBloc.dart';
import 'package:lg_controller/src/states_events/PageActions.dart';
import 'package:lg_controller/src/ui/OSCDialog.dart';
import 'package:lg_controller/src/ui/ScreenBackground.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'HomePage.dart';

/// Tutorial screen root.
class TutorialPage extends StatefulWidget {
  TutorialPage();

  @override
  _TutorialPageState createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> with NavigatorObserver {
  @override
  void initState() {
    super.initState();
    checkOSCParams();
  }

  @override
  Widget build(BuildContext context) {
    setState(() => context = context);
    return WillPopScope(
      onWillPop: () => SystemNavigator.pop(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: ScreenBackground.getBackgroundDecoration(),
          child: Center(
            child: Container(),
          ),
        ),
      ),
    );
  }

  /// Check if the user launches app for 1st time.
  bool isFirstTime() {
    return false;
  }

  /// Check if OSC params already exists.
  void checkOSCParams() {
    SharedPreferences.getInstance().then((prefs) async {
      final dataString = prefs.getString('ip') ?? '';
      if ((dataString.compareTo('')) == 0) {
        setOSCParams();
      } else {
        if (!isFirstTime()) {
          BlocProvider.of<PageBloc>(context).dispatch(HOME(null));
          Navigator.pushReplacement(
              context,
              PageTransition(
                  type: PageTransitionType.fade,
                  duration: Duration(milliseconds: 250),
                  child: HomePage(null)));
        }
      }
    });
  }

  /// Displays dialog for setting OSC params.
  setOSCParams() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return OSCDialog(setParams);
      },
    );
  }

  /// Sets OSC parameters.
  setParams(String ip, String soc, String lgid) async {
    try {
      int socket = int.parse(soc);
      int id = int.parse(lgid);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('ip', ip);
      prefs.setInt('socket', socket);
      prefs.setInt('id', id);
      if (!isFirstTime()) {
        BlocProvider.of<PageBloc>(context).dispatch(HOME(null));
        Navigator.pushReplacement(
            context,
            PageTransition(
                type: PageTransitionType.fade,
                duration: Duration(milliseconds: 250),
                child: HomePage(null)));
      }
    } catch (e) {
      print(e);
      print('Error : In setting OSC params.');
    }
  }
}
