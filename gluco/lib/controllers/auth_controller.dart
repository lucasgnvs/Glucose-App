import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gluco/services/api.dart';
import 'package:gluco/extensions/buildcontext/loc.dart';

class AuthController {
  final TextEditingController _name = TextEditingController();
  TextEditingController get name => _name;
  final TextEditingController _email = TextEditingController();
  TextEditingController get email => _email;
  final TextEditingController _password = TextEditingController();
  TextEditingController get password => _password;

  late String _errorMessage;

  final ValueNotifier<bool> _validFormVN = ValueNotifier<bool>(false);
  ValueNotifier<bool> get validFormVN => _validFormVN;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  late AutovalidateMode _validationMode;
  AutovalidateMode get validationMode => _validationMode;

  final BuildContext context;

  AuthController(this.context) {
    _validationMode = AutovalidateMode.disabled;
    _errorMessage = '';
  }

  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _validFormVN.dispose();
  }

  void validate() async {
    await Future.delayed(const Duration(milliseconds: 1));
    if (validationMode == AutovalidateMode.onUserInteraction) {
      _validFormVN.value = _formKey.currentState?.validate() ?? false;
    } else {
      _validFormVN.value = _name.text.isNotEmpty &&
          _email.text.isNotEmpty &&
          _password.text.isNotEmpty;
    }
  }

  // TODO: não é a melhor maneira de resolver isso
  void onChangedEmail(String text) {
    if (_errorMessage == APIResponseMessages.alreadyRegistered ||
        _errorMessage == APIResponseMessages.notRegistered ||
        _errorMessage == APIResponseMessages.invalidFields) {
      _errorMessage = '';
    }
  }

  void onChangedPassword(String text) {
    if (_errorMessage == APIResponseMessages.wrongPassword) {
      _errorMessage = '';
    }
  }

  String? validatorName(String? text) {
    if (text == null || text.isEmpty) {
      return context.loc.generic_error_required_field;
    }
    if (!RegExp(r"^[\p{Letter}'\- ]+$", unicode: true).hasMatch(text)) {
      return context.loc.register_error_invalid_name;
    }
    return null;
  }

  String? validatorEmail(String? text) {
    if (text == null || text.isEmpty) {
      return context.loc.generic_error_required_field;
    }
    if (!RegExp(r"^[a-zA-Z0-9\.]+@[a-zA-Z]+(\.[a-zA-Z]+)+$", unicode: true)
        .hasMatch(text)) {
      return context.loc.register_error_invalid_email;
    }
    if (_errorMessage == APIResponseMessages.alreadyRegistered) {
      return context.loc.register_error_email_already_in_use;
    }
    if (_errorMessage == APIResponseMessages.notRegistered) {
      return context.loc.login_error_cannot_find_user;
    }
    if (_errorMessage == APIResponseMessages.invalidFields) {
      return context.loc.login_error_wrong_credentials;
    }
    return null;
  }

  String? validatorPassword(String? text) {
    if (_errorMessage == APIResponseMessages.wrongPassword) {
      return context.loc.login_error_wrong_password;
    }
    if (text == null || text.isEmpty) {
      return context.loc.generic_error_required_field;
    }
    if (text.length < 6) {
      return context.loc.register_error_weak_password;
    }
    return null;
  }

  Future<bool> executeLogin() async {
    bool response = false;
    _validationMode = AutovalidateMode.onUserInteraction;
    _validFormVN.value = _formKey.currentState?.validate() ?? false;
    if (_validFormVN.value) {
      String email = _email.text.trim().toLowerCase();
      String password = _password.text.trim();
      response = await API.instance.login(email, password);
      _password.clear();
      _errorMessage = API.instance.responseMessage;
    }
    return response;
  }

  Future<bool> executeSignUp() async {
    bool response = false;
    _validationMode = AutovalidateMode.onUserInteraction;
    _validFormVN.value = _formKey.currentState?.validate() ?? false;
    if (_validFormVN.value) {
      String name = _name.text.trim().split(RegExp(' +')).map((t) {
        return t[0].toUpperCase() + t.substring(1).toLowerCase();
      }).join(' ');
      String email = _email.text.trim().toLowerCase();
      String password = _password.text.trim();
      response = await API.instance.signUp(name, email, password) &&
          await API.instance.login(email, password);
      _password.clear();
      _errorMessage = API.instance.responseMessage;
    }
    return response;
  }
}
