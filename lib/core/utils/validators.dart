class Validators {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 8;
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d-]{8,}$').hasMatch(phone);
  }
}