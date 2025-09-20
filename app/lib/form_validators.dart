String? checkIsNumber(String? input) {
  if (input == null || num.tryParse(input) == null) {
    return "Input must be a number";
  }
  return null;
}

String? checkIsInteger(String? input) {
  if (input == null || int.tryParse(input) == null) {
    return "Input must be an integer";
  }
  return null;
}
