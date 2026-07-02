# Flavoring

Three flavors: `dev`, `qas`, `prd`.

| Flavor | App Name          | Bundle ID                    |
| ------ | ----------------- | ---------------------------- |
| dev    | Mandor DEV | com.yanmii.mandor.dev |
| qas    | Mandor QAS | com.yanmii.mandor.qa   |
| prd    | Mandor.0   | com.yanmii.mandor    |

Access at runtime via `F.appFlavor` and `F.title`. Base URL is injected at build
time via `String.fromEnvironment('API_URL')` — never hardcode it.

Run with a flavor and API URL — never without one:

```bash
flutter run --flavor dev --dart-define=API_URL=http://127.0.0.1:3000/
flutter run --flavor qas --dart-define=API_URL=https://qas-api.example.com/
flutter run --flavor prd --dart-define=API_URL=https://api.example.com/
```

## PowerSync defines

Two additional defines are required when running with PowerSync (offline sync):

| Define | Default | Notes |
|--------|---------|-------|
| `POWERSYNC_URL` | `http://localhost:8081` | PowerSync service endpoint |
| `DEV_EMAIL` | `supervisor@example.com` | Seeded supervisor email for dev bootstrap login |
| `DEV_PASSWORD` | `12345678` | Password for dev bootstrap login |

At startup the dev flavor auto-calls `POST /auth/dev/dummy-login` with these credentials
and uses the returned JWT for all subsequent requests (including the PowerSync token endpoint).
No login screen — it is a transparent bootstrap only available in the `dev` flavor.

Full dev command:
```bash
flutter run --flavor dev \
  --dart-define=API_URL=http://127.0.0.1:8001/ \
  --dart-define=POWERSYNC_URL=http://127.0.0.1:8080/ \
  --dart-define=DEV_EMAIL=supervisor@example.com \
  --dart-define=DEV_PASSWORD=12345678
```

Navigate to `/debug/sync` to verify connection state and test PUT/PATCH operations.
