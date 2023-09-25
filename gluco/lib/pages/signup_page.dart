// ignore_for_file: must_be_immutable, use_key_in_widget_constructors, prefer_const_constructors

import 'package:async_button_builder/async_button_builder.dart';
import 'package:flutter/material.dart';
import 'package:gluco/controllers/auth_controller.dart';
// import 'package:gluco/services/api.dart';
import 'package:gluco/styles/custom_colors.dart';
import 'package:gluco/styles/custom_clippers.dart';
import 'package:gluco/extensions/buildcontext/loc.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage();

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late final AuthController controller;

  final ValueNotifier<bool> _hidePwdVN = ValueNotifier<bool>(true);

  @override
  void initState() {
    controller = AuthController(context);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.notwhite,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
                minWidth: viewportConstraints.maxWidth,
              ),
              child: Column(
                children: [
                  ClipPath(
                    clipper: CubicClipper(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            CustomColors.blueGreen.withOpacity(0.40),
                            CustomColors.lightBlue.withOpacity(0.20),
                            CustomColors.greenBlue.withOpacity(0.20),
                            CustomColors.lightGreen.withOpacity(0.20),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Image(
                          // TODO: Alterar literal para generate
                          image: AssetImage('assets/images/logoblue.png'),
                          width: MediaQuery.of(context).size.width * 0.43,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 10.0, bottom: 40.0),
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Form(
                      key: controller.formKey,
                      autovalidateMode: controller.validationMode,
                      onChanged: controller.validate,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: controller.name,
                            decoration: InputDecoration(
                              label: Text(
                                context.loc.full_name,
                                style: TextStyle(color: CustomColors.lightBlue),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: CustomColors.lightBlue,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  width: 3,
                                  color: CustomColors.lightBlue,
                                ),
                              ),
                            ),
                            validator: controller.validatorName,
                            cursorColor: CustomColors.lightBlue,
                            keyboardType: TextInputType.name,
                            autocorrect: false,
                          ),
                          Padding(padding: EdgeInsets.all(8.0)),
                          TextFormField(
                            controller: controller.email,
                            decoration: InputDecoration(
                              label: Text(
                                context.loc.email,
                                style: TextStyle(color: CustomColors.blueGreen),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: CustomColors.blueGreen,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  width: 3,
                                  color: CustomColors.blueGreen,
                                ),
                              ),
                            ),
                            onChanged: controller.onChangedEmail,
                            validator: controller.validatorEmail,
                            cursorColor: CustomColors.greenBlue,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          Padding(padding: EdgeInsets.all(8.0)),
                          ValueListenableBuilder<bool>(
                            valueListenable: _hidePwdVN,
                            builder: (_, isHidden, child) {
                              return TextFormField(
                                controller: controller.password,
                                decoration: InputDecoration(
                                  label: Text(
                                    context.loc.password,
                                    style: TextStyle(
                                        color: CustomColors.lightGreen),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      width: 2,
                                      color: CustomColors.lightGreen,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      width: 3,
                                      color: CustomColors.lightGreen,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                      onPressed: () {
                                        _hidePwdVN.value = !_hidePwdVN.value;
                                      },
                                      icon: Icon(isHidden
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      color: CustomColors.lightGreen),
                                ),
                                onChanged: controller.onChangedPassword,
                                validator: controller.validatorPassword,
                                cursorColor: CustomColors.lightGreen,
                                obscureText: isHidden,
                                keyboardType: TextInputType.visiblePassword,
                                enableSuggestions: false,
                                autocorrect: false,
                              );
                            },
                          ),
                          Padding(padding: EdgeInsets.all(8.0)),
                          ValueListenableBuilder<bool>(
                            valueListenable: controller.validFormVN,
                            builder: (_, isValid, child) {
                              return Column(
                                children: [
                                  Visibility(
                                    visible: !isValid,
                                    child: Container(
                                      alignment: Alignment.bottomRight,
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        context
                                            .loc.generic_error_unfilled_fields,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  AsyncButtonBuilder(
                                    loadingWidget: CircularProgressIndicator(
                                      color: CustomColors.notwhite,
                                      strokeWidth: 3.0,
                                    ),
                                    disabled: !isValid,
                                    onPressed: !isValid
                                        ? null
                                        : () async {
                                            if (await controller
                                                .executeSignUp()) {
                                              await Navigator.popAndPushNamed(
                                                  context, '/welcome');
                                            } else {
                                              // TODO: Precisa lançar exceção para aparecer ícone certo no botão,
                                              //  escolher uma exceção certa e não uma string
                                              throw 'Erro no signup';
                                            }
                                          },
                                    builder: (context, child, callback, _) {
                                      return TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              CustomColors.notwhite,
                                          backgroundColor: isValid
                                              ? CustomColors.lightGreen
                                              : Colors.grey,
                                          padding: EdgeInsets.all(10.0),
                                          minimumSize: Size.fromHeight(60),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: callback,
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                      context.loc.register_view_button,
                                      style: TextStyle(
                                        // TODO: Corrigir a cor
                                        color: CustomColors.notwhite,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        // TODO: Colocar cor no customcolors
                                        Color.fromARGB(0, 255, 251, 251),
                                        CustomColors.lightGreen,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(15),
                                child: Text(
                                  context.loc.or,
                                  style: TextStyle(
                                    color: CustomColors.lightGreen,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        CustomColors.lightGreen,
                                        // TODO: Colocar cor no customcolors
                                        Color.fromARGB(0, 255, 250, 250),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: CustomColors.lightGreen,
                              textStyle: TextStyle(
                                fontSize: 16.0,
                              ),
                              backgroundColor: CustomColors.notwhite,
                              padding: EdgeInsets.all(10.0),
                              minimumSize:
                                  Size(viewportConstraints.maxWidth, 60),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    color: CustomColors.lightGreen, width: 2.0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.popAndPushNamed(
                                  context, '/login');
                            },
                            child: Text(
                                context.loc.register_view_already_registered),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
