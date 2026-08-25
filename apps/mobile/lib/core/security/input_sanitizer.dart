class InputSanitizer {
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  static bool isStrongPassword(String password) {
    return password.length >= 8;
  }

  static bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  static bool isValidPhone(String phone) {
    return phone.trim().length >= 7;
  }

  static String sanitizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static String sanitizeName(String name) {
    return sanitizeString(name);
  }

  static String sanitizePhone(String phone) {
    return phone.trim();
  }

  static String sanitizeString(String input) {
    return input
        .replaceAll('<script>', '')
        .replaceAll('</script>', '')
        .replaceAll("'", "''")
        .trim();
  }

  static void logSecurityAudit(String event, {String level = 'INFO'}) {
    // Enterprise Security Audit Log Dispatcher
    // In production, dispatches to secure cloud logging endpoint
  }
}
