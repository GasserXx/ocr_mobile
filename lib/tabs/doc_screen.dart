import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/style.dart';

class DocScreen extends StatelessWidget {
  const DocScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Doc Screen',
        style: TextAppStyle.subMainTittel.copyWith(fontSize: 20.sp),
      ),
    );
  }
}