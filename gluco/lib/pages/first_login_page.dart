// ignore_for_file: must_be_immutable, use_key_in_widget_constructors, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:gluco/controllers/profile_controller.dart';
import 'package:gluco/services/api.dart';
import 'package:gluco/styles/custom_colors.dart';
import 'package:gluco/styles/date_formatter.dart';
import 'package:gluco/extensions/buildcontext/loc.dart';

class FirstLoginPage extends StatefulWidget {
  const FirstLoginPage();

  @override
  State<FirstLoginPage> createState() => _FirstLoginPageState();
}

class _FirstLoginPageState extends State<FirstLoginPage> {
  ProfileController controller = ProfileController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double landscapeCorrection =
        MediaQuery.of(context).orientation == Orientation.landscape ? 0.6 : 1.0;
    return Scaffold(
      backgroundColor: CustomColors.notwhite,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).size.width * 0.1),
          child: Form(
            key: controller.formKey,
            autovalidateMode: controller.validationMode,
            onChanged: controller.validate,
            child: Column(
              children: [
                Padding(padding: EdgeInsets.all(20.0 * landscapeCorrection)),
                Stack(
                  alignment: AlignmentDirectional.bottomEnd,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width *
                          0.4 *
                          landscapeCorrection,
                      padding: EdgeInsets.all(10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: CustomColors.blueGreen.withOpacity(1.0),
                          shape: BoxShape.circle,
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: controller.profilePicVN,
                          builder: (_, hasProfilePic, child) {
                            return hasProfilePic
                                ? CircleAvatar(
                                    backgroundImage:
                                        controller.profilePic!.image,
                                    radius: MediaQuery.of(context).size.width *
                                        0.15 *
                                        landscapeCorrection,
                                  )
                                : Icon(
                                    Icons.person,
                                    size: MediaQuery.of(context).size.width *
                                        0.3 *
                                        landscapeCorrection,
                                    color: Colors.white,
                                  );
                          },
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      backgroundColor: Colors.grey[200],
                      onPressed: controller.updateProfilePic,
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 35.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 25.0,
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16.0,
                        color: CustomColors.blueGreen.withOpacity(1.0),
                      ),
                      children: [
                        TextSpan(
                          text:
                              '${context.loc.hello} ${API.instance.currentUser?.name.split(' ')[0]}!\n',
                          style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextSpan(
                          text: context.loc.firstlogin_prompt_personal_info,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(context.loc.birthday,
                          style: TextStyle(
                              color: CustomColors.greenBlue.withOpacity(1.0))),
                    ),
                    TextFormField(
                      controller: controller.birthdate,
                      inputFormatters: [DateFormatter()],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        hintText: 'dd/mm/aaaa',
                        hintStyle: TextStyle(color: Colors.black26),
                        filled: true,
                        fillColor: CustomColors.greenBlue.withOpacity(0.25),
                        isDense: true,
                        contentPadding: EdgeInsets.all(12.0),
                      ),
                      validator: controller.validatorBirthdate,
                      keyboardType: TextInputType.datetime,
                      autocorrect: false,
                      enableSuggestions: false,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 20.0, bottom: 8.0),
                            child: Text(context.loc.weight,
                                style: TextStyle(
                                    color: CustomColors.greenBlue
                                        .withOpacity(1.0))),
                          ),
                          TextFormField(
                            controller: controller.weight,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                              ),
                              hintText: '70,5',
                              hintStyle: TextStyle(color: Colors.black26),
                              suffixText: 'kg',
                              filled: true,
                              fillColor:
                                  CustomColors.greenBlue.withOpacity(0.25),
                              isDense: true,
                              contentPadding: EdgeInsets.all(12.0),
                            ),
                            validator: controller.validatorWeight,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                    Padding(padding: EdgeInsets.all(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 20.0, bottom: 8.0),
                            child: Text(context.loc.height,
                                style: TextStyle(
                                    color: CustomColors.greenBlue
                                        .withOpacity(1.0))),
                          ),
                          TextFormField(
                            controller: controller.height,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                              ),
                              hintText: '1,67',
                              hintStyle: TextStyle(color: Colors.black26),
                              suffixText: 'm',
                              filled: true,
                              fillColor:
                                  CustomColors.greenBlue.withOpacity(0.25),
                              isDense: true,
                              contentPadding: EdgeInsets.all(12.0),
                            ),
                            validator: controller.validatorHeight,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 20.0, bottom: 8.0),
                      child: Text(context.loc.sex,
                          style: TextStyle(
                              color: CustomColors.greenBlue.withOpacity(1.0))),
                    ),
                    DropdownButtonFormField(
                      value: controller.sex,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        filled: true,
                        fillColor: CustomColors.greenBlue.withOpacity(0.25),
                        isDense: true,
                        contentPadding: EdgeInsets.all(12.0),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down),
                      onChanged: (String? value) {
                        controller.sex = value!;
                      },
                      items: controller.sexList.map((String value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 20.0, bottom: 8.0),
                      child: Text(context.loc.type_of_diabetes,
                          style: TextStyle(
                              color: CustomColors.greenBlue.withOpacity(1.0))),
                    ),
                    DropdownButtonFormField(
                      value: controller.diabetes,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        filled: true,
                        fillColor: CustomColors.greenBlue.withOpacity(0.25),
                        isDense: true,
                        contentPadding: EdgeInsets.all(12.0),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down),
                      onChanged: (String? value) {
                        controller.diabetes = value!;
                      },
                      items: controller.diabetesList.map((String value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Padding(padding: EdgeInsets.all(30)),
                ValueListenableBuilder<bool>(
                  valueListenable: controller.validFormVN,
                  builder: (_, isValid, child) {
                    return Column(
                      children: [
                        AsyncButtonBuilder(
                          loadingWidget: CircularProgressIndicator(
                            color: CustomColors.notwhite,
                            strokeWidth: 3.0,
                          ),
                          onPressed: !isValid
                              ? null
                              : () async {
                                  if (await controller.executeCreate()) {
                                    // TODO: tirar context de async gap
                                    await Navigator.popAndPushNamed(
                                        context, '/home');
                                  } else {
                                    throw 'create profile error';
                                  }
                                },
                          builder: (context, child, callback, _) {
                            return TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: isValid
                                    ? CustomColors.lightGreen
                                    : Colors.grey,
                                padding: EdgeInsets.all(10.0),
                                minimumSize: Size.fromHeight(60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: callback,
                              child: child,
                            );
                          },
                          child: Text(
                            context.loc.conclude,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: !isValid,
                          child: Container(
                            alignment: Alignment.bottomLeft,
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              context.loc.generic_error_unfilled_fields,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
