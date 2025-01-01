import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/color.dart';

class TextAppStyle {
  static TextStyle mainTittel = TextStyle(
      fontSize: 45.sp,
      fontWeight: FontWeight.w900,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..color = Colors.black,
      fontFamily: "Nunito");
  static TextStyle subMainTittel = TextStyle(
      fontSize: 45.sp,
      fontWeight: FontWeight.w900,
      color: Colors.black,
      fontFamily: "Nunito");
  static TextStyle subTittel = TextStyle(
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      color: AppColor.subText,
      fontFamily: "Nunito");
}
