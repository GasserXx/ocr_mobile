import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled17/theme/color.dart';
import 'package:untitled17/theme/style.dart';
import 'package:untitled17/Login/custom_button.dart';
import 'package:untitled17/Login/custom_text_field.dart';
import 'package:untitled17/API/api_service.dart'; // Add this import

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  Future<void> _sendResetLink() async {
    if (_validateEmail(_emailController.text) != null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.sendForgotPasswordEmail(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset link sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Center(
                child: Text(
                  'Reset Password',
                  style: TextAppStyle.subMainTittel.copyWith(fontSize: 24.sp),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Enter your email address to receive a password reset link',
                style: TextAppStyle.subTittel.copyWith(
                  color: AppColor.subText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              CustomTextField(
                hintName: 'Email Address',
                hintText: 'Enter your email',
                controller: _emailController,
                validator: _validateEmail,
              ),
              SizedBox(height: 20.h),
              _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: AppColor.primeColor,
                ),
              )
                  : CustomButton(
                text: 'Send Reset Link',
                onPressed: _sendResetLink,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}