import 'package:flutter/material.dart';
import '../models/office_model.dart';

class OfficeProvider with ChangeNotifier {
  OfficeModel? _office;

  OfficeModel? get office => _office;

  void setOffice(OfficeModel office) {
    _office = office;
    notifyListeners();
  }

  void clearOffice() {
    _office = null;
    notifyListeners();
  }
}