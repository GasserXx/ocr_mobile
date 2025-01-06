import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/color.dart';
import 'package:untitled17/theme/style.dart';

class CustomTextField extends StatefulWidget {
  final String hintName;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? hintText;
  final bool obscureText;
  final VoidCallback? onTogglePasswordVisibility;

  const CustomTextField({
    Key? key,
    required this.hintName,
    required this.controller,
    required this.validator,
    this.hintText,
    this.obscureText = false,
    this.onTogglePasswordVisibility,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.hintName,
          style: TextAppStyle.subTittel,
        ),
        SizedBox(height: 4.h),
        Container(
          color: Colors.white,
          child: TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            obscureText: widget.obscureText,
            style: TextAppStyle.subTittel,
            decoration: decorationField(
              habitHintName: widget.hintText,
              suffixIcon: widget.onTogglePasswordVisibility != null
                  ? IconButton(
                icon: Icon(
                  widget.obscureText
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColor.subText,
                ),
                onPressed: widget.onTogglePasswordVisibility,
              )
                  : null,
            ),
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

InputDecoration decorationField({String? habitHintName, Widget? suffixIcon}) {
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
    suffixIcon: suffixIcon,
  );
}