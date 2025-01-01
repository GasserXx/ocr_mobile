import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/color.dart';
import 'package:untitled17/theme/style.dart';

class CustomTextField extends StatelessWidget {
  final String hintName;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? hintText;
  final bool obscureText;

  const CustomTextField({
    Key? key,
    required this.hintName,
    required this.controller,
    required this.validator,
    this.hintText,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hintName,
          style: TextAppStyle.subTittel,
        ),
        SizedBox(height: 4.h),
        Container(
          color: Colors.white,
          child: TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscureText,
            style: TextAppStyle.subTittel,
            decoration: decorationField(habitHintName: hintText),
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      ],
    );
  }
}

OutlineInputBorder borderTextField() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4.r)),
    borderSide: const BorderSide(
      color: AppColor.borderColor,
      width: 1.0,
    ),
  );
}

InputDecoration decorationField({String? habitHintName}) {
  return InputDecoration(
    contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
    border: borderTextField(),
    hintText: habitHintName,
    hintStyle: TextAppStyle.subTittel,
    enabledBorder: borderTextField(),
    focusedBorder: borderTextField(),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.r)),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );
}