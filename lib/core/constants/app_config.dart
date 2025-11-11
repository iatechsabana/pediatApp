/// Centralized app-wide constants and configuration values
class AppConfig {
  // App info
  static const appName = 'PediApp';
  static const appVersion = '1.0.0';

  // Firebase
  static const firebaseProjectId = 'pediapp';

  // API configuration
  static const apiTimeout = Duration(seconds: 30);
  static const apiRetries = 3;

  // Loading delays (for simulated operations)
  static const simulatedLoadDelay = Duration(seconds: 2);
  static const simulatedSubmitDelay = Duration(seconds: 2);

  // Validation
  static const minPasswordLength = 6;
  static const maxNameLength = 100;
  static const maxEmailLength = 254;

  // Chat/Assistant
  static const defaultAssistantName = 'Asistente pediátrico';
  static const openaiTemperature = 0.7;
  static const openaiMaxTokens = 500;
  static const chatInitialMessage = 'Pregunta sobre fiebre, tos, vacunas...';
  static const typingIndicatorText = 'Asistente está escribiendo...';

  // UI configuration
  static const enableAnimations = true;
  static const enableShadows = true;

  // Snackbar durations
  static const snackbarDuration = Duration(seconds: 3);
  static const errorSnackbarDuration = Duration(seconds: 4);
}
