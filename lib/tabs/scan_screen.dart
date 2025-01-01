import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/color.dart';
import 'package:untitled17/theme/style.dart';
import 'package:untitled17/Scaner/scan_type_screen.dart';
import 'package:untitled17/Scaner/dotted_border.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text
          Text(
            'Welcome,\nGasser!',
            style: TextAppStyle.subTittel.copyWith(
              fontSize: 34.sp,
              color: AppColor.tittelText,
            ),
          ),
          SizedBox(height: 20.h),
          // Dotted Box
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanTypeScreen(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: DottedBorder(
                  padding: EdgeInsets.all(24.w),
                  borderType: BorderType.RRect,
                  radius: Radius.circular(16.r),
                  dashPattern: const [8, 8],
                  color: AppColor.primeColor,
                  strokeWidth: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 64.sp,
                          color: AppColor.primeColor,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Tap to Scan',
                          style: TextAppStyle.subMainTittel.copyWith(
                            fontSize: 24.sp,
                            color: AppColor.primeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}