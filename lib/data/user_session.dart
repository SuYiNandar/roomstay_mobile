class UserSession {
  static String? accessToken;
  static String? refreshToken;
  static String? userId;
  static String? email;
  static String? fullName;
  static String? role;

  static bool get isPropertyManager =>
      role == 'partner' || role == 'property_manager';

  static void clear() {
    accessToken = null;
    refreshToken = null;
    userId = null;
    email = null;
    fullName = null;
    role = null;
  }
}
