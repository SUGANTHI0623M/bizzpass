/// API and app constants. CRM backend base URL.
class ApiConstants {
  ApiConstants._();

  /// Base URL for crm_backend (Python FastAPI). Use your machine IP for device/emulator.
  static const String baseUrl = 'http://localhost:8000';

  static const String authTokenKey = 'bizzpass_crm_auth_token';
  static const String authUserKey = 'bizzpass_crm_auth_user';

  /// Shown when backend is unreachable. Keep in sync with repository error text.
  static const String backendUnreachableHint =
      'Start the backend: open a terminal, go to crm_backend, then run '
      '.\\scripts\\run_backend.ps1 (Windows) or uvicorn main:app --reload --port 8000. Then tap Retry.';
}
