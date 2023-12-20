// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:gluco/styles/custom_colors.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'package:gluco/db/db_test.dart';
import 'package:gluco/services/bluetooth_helper.dart';
import 'package:gluco/services/custom_log.dart';
import 'package:gluco/pages/device_page.dart';
import 'package:gluco/pages/first_login_page.dart';
import 'package:gluco/pages/history_page.dart';
import 'package:gluco/pages/home_page.dart';
import 'package:gluco/pages/login_page.dart';
import 'package:gluco/pages/profile_page.dart';
import 'package:gluco/pages/signup_page.dart';
import 'package:gluco/pages/splash_screen.dart';
import 'package:gluco/services/api.dart';
import 'package:gluco/services/btle_test.dart';
// import 'package:gluco/styles/custom_colors.dart';
import 'package:gluco/views/history_view.dart';

String _defaultHome = '/login';
bool offline = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  await logInit();

  if (await API.instance.login()) {
    switch (API.instance.responseMessage) {
      case APIResponseMessages.success:
        _defaultHome = '/home';
        await HistoryView.fetchHistory();
        break;
      case APIResponseMessages.offlineMode:
        _defaultHome = '/home';
        offline = true;
        await HistoryView.fetchHistory();
        break;
      case APIResponseMessages.emptyProfile:
        _defaultHome = '/welcome';
        break;
    }
  }

  BluetoothHelper.instance.autoConnect();

  runApp(
    MaterialApp(
      home: Main(),
    ),
  );
}

class Main extends StatefulWidget {
  @override
  MainState createState() => MainState();
}

class MainState extends State<Main> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: CustomColors.lightGreen),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        primarySwatch: Colors.green,
        // popupMenuTheme:
        //     ThemeData.light().popupMenuTheme.copyWith(color: CustomColors.scaffWhite),
        // backgroundColor: Colors.white,  // color Schema
        // // accentColor: Colors.grey[600],
        // errorColor: Colors.red[900],
        fontFamily: 'OpenSans',
        textTheme: ThemeData.light().textTheme.copyWith(
              titleLarge: TextStyle(
                color: Colors.black,
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              labelLarge: TextStyle(color: Colors.white),
            ),
      ),
      routes: {
        '/': (context) => SplashScreen(route: _defaultHome),
        '/home': (context) => HomePage(offline: offline),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/welcome': (context) => FirstLoginPage(),
        '/devices': (context) => DevicePage(),
        '/history': (context) => HistoryPage(),
        '/profile': (context) => ProfilePage(),
        '/teste': (context) => FlutterBlueApp(),
        // '/teste': (context) => DBTest(),
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
