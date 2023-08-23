import 'package:flutter/material.dart';
import 'package:gluco/models/user.dart';
import 'package:gluco/services/api.dart';

// TODO: Implementar os demais métodos
class AuthController {
  User? _user;

  late AutovalidateMode _validationMode;
  AutovalidateMode get validationMode => _validationMode;

  ProfileController() {
    _validationMode = AutovalidateMode.disabled;
  }

  void validate() async {}
}
