import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/color.dart';
import 'package:untitled17/splash_screen.dart';
import 'package:flutter/services.dart';
import 'package:untitled17/Scaner/scanner.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await ScreenUtil.ensureScreenSize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Login App',
          theme: ThemeData(
            primaryColor: AppColor.primeColor,
            fontFamily: "Nunito",
          ),
          home: child,
        );
      },
      child: SplashScreen(),
    );
  }
}