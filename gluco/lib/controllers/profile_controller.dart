import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gluco/models/user.dart';
import 'package:gluco/services/api.dart';
import 'package:gluco/extensions/buildcontext/loc.dart';

@Deprecated(
    'Deveria ser substituido por validação através de BLoC, e não setStates')
class ProfileController {
  User? _user;

  Image? _profilePic;
  Image? get profilePic => _profilePic;
  String? _profilePicPath;
  String? get profilePicPath => _profilePicPath;

  final TextEditingController _birthdate = TextEditingController();
  TextEditingController get birthdate => _birthdate;
  final TextEditingController _weight = TextEditingController();
  TextEditingController get weight => _weight;
  final TextEditingController _height = TextEditingController();
  TextEditingController get height => _height;

  String? sex;
  String? diabetes;
  // TODO: alterar os literais para context.loc
  List<String> get sexList => ['Masculino', 'Feminino'];
  List<String> get diabetesList => ['Tipo 1', 'Tipo 2', 'Não tenho diabetes'];

  final ValueNotifier<bool> _validFormVN = ValueNotifier<bool>(false);
  ValueNotifier<bool> get validFormVN => _validFormVN;
  final ValueNotifier<bool> _profilePicVN = ValueNotifier<bool>(false);
  ValueNotifier<bool> get profilePicVN => _profilePicVN;

  late AutovalidateMode _validationMode;
  AutovalidateMode get validationMode => _validationMode;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  final BuildContext context;

  ProfileController(this.context) {
    _validationMode = AutovalidateMode.disabled;
  }

  ProfileController.fromUser(this.context, this._user) {
    // TODO: localizar date format e tirar pt_BR
    _birthdate.text = DateFormat.yMd('pt_BR').format(_user!.profile.birthday);
    _weight.text = _user!.profile.weight.toString();
    _height.text = _user!.profile.height.toString();
    sex = _user!.profile.sex == 'M' ? 'Masculino' : 'Feminino';
    diabetes = _user!.profile.diabetes_type == 'T1'
        ? 'Tipo 1'
        : _user!.profile.diabetes_type == 'T2'
            ? 'Tipo 2'
            : 'Não tenho diabetes';
    _validationMode = AutovalidateMode.always;
    _profilePicPath = _user!.profile.profile_pic;
    _loadProfilePic();
  }

  void dispose() {
    _birthdate.dispose();
    _weight.dispose();
    _height.dispose();
    _validFormVN.dispose();
    _profilePicVN.dispose();
  }

  void validate() async {
    ///// Gambiarra para que o onchanged do form seja chamado depois do onchanged dos fields
    await Future.delayed(const Duration(milliseconds: 1));
    //////
    if (_validationMode == AutovalidateMode.always) {
      _validFormVN.value = _formKey.currentState?.validate() ?? false;
    } else {
      _validFormVN.value = _birthdate.text.isNotEmpty &&
          _weight.text.isNotEmpty &&
          _height.text.isNotEmpty &&
          (sex?.isNotEmpty ?? false) &&
          (diabetes?.isNotEmpty ?? false);
    }
  }

  String? validatorBirthdate(String? text) {
    if (text == null || text.isEmpty) {
      return '*Campo obrigatório';
    }
    DateTime? value;
    try {
      value = DateFormat.yMd('pt_BR').parseStrict(text);
    } catch (e) {
      // print('date parsing error');
    }
    DateTime now = DateTime.now();
    if (value == null ||
        value.isAfter(now) ||
        value.isBefore(now.subtract(const Duration(days: 365 * 120)))) {
      return '*Insira uma data válida';
    }
    return null;
  }

  String? validatorWeight(String? text) {
    if (text == null || text.isEmpty) {
      return '*Campo obrigatório';
    }
    double? value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null || value < 30 || value > 300) {
      return '*Insira um número válido';
    }
    return null;
  }

  String? validatorHeight(String? text) {
    if (text == null || text.isEmpty) {
      return '*Campo obrigatório';
    }
    double? value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null || value < 0.5 || value > 2.5) {
      return '*Insira um número válido';
    }
    return null;
  }

  void updateProfilePic() async {
    XFile? pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage == null) {
      return;
    }
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: pickedImage.path,
      maxWidth: 360,
      maxHeight: 360,
      aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      // TODO: cropStyle foi deprecated, buscar solução para imagem circular
      // cropStyle: CropStyle.circle,
    );
    if (croppedImage == null) {
      return;
    }
    Directory dir = await getApplicationDocumentsDirectory();
    File image = await File(join(dir.path, 'EG_${pickedImage.name}'))
        .writeAsBytes(await croppedImage.readAsBytes());
    _profilePicPath = image.path;
    _loadProfilePic();
    if (_user != null) {
      _user!.profile.profile_pic = _profilePicPath!;
      await API.instance.updateDBUserProfile();
    }
  }

  void _loadProfilePic() {
    _profilePicVN.value = false;
    File file = File(_profilePicPath!);
    if (file.existsSync()) {
      _profilePic = Image.file(file);
      _profilePicVN.value = true;
    }
  }

  Future<bool> executeCreate() async {
    _validationMode = AutovalidateMode.always;
    _validFormVN.value = _formKey.currentState?.validate() ?? false;
    if (_validFormVN.value) {
      bool response = await API.instance.createUserProfile(
          // TODO: localizar date format e tirar pt_BR
          DateFormat.yMd('pt_BR').parseStrict(_birthdate.text),
          double.parse(_weight.text.replaceAll(',', '.')),
          double.parse(_height.text.replaceAll(',', '.')),
          sex == 'Masculino' ? 'M' : 'F',
          diabetes == 'Tipo 1'
              ? 'T1'
              : diabetes == 'Tipo 2'
                  ? 'T2'
                  : 'NP',
          _profilePicPath ?? '');
      if (response) {
        await API.instance.updateDBUserProfile();
        return true;
      }
    }
    return false;
  }

  Future<void> executeUpdate() async {
    _validFormVN.value = _formKey.currentState?.validate() ?? false;
    if (_validFormVN.value) {
      bool response = await API.instance.updateUserProfile(
          DateFormat.yMd('pt_BR').parseStrict(_birthdate.text),
          double.parse(_weight.text.replaceAll(',', '.')),
          double.parse(_height.text.replaceAll(',', '.')),
          sex == 'Masculino' ? 'M' : 'F',
          diabetes == 'Tipo 1'
              ? 'T1'
              : diabetes == 'Tipo 2'
                  ? 'T2'
                  : 'NP',
          _profilePicPath ?? '');
      if (response) {
        _validFormVN.value = false;
      }
    }
  }
}
