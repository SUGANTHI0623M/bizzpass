/// API and app constants. CRM backend base URL.
class ApiConstants {
  ApiConstants._();

  /// Base URL for crm_backend (Python FastAPI).
  /// Use same host as app (localhost) for Flutter web to avoid cross-host issues.
  static const String baseUrl = 'http://localhost:8000';

  static const String authTokenKey = 'bizzpass_crm_auth_token';
  static const String authUserKey = 'bizzpass_crm_auth_user';

  /// Shown when backend is unreachable. Keep in sync with repository error text.
  static const String backendUnreachableHint =
      'If using Docker: run "docker compose up -d crm_backend" from the project root. '
      'Otherwise, run uvicorn main:app --reload --port 8000 from crm_backend. Then tap Retry.';
}
