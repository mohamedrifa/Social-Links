class Validators {
  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Description is required";
    }
    return null;
  }
}