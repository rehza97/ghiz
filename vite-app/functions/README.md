# Cloud Functions

Callable function `createAdminUser` lets admins create users from the UI (no CLI).

**Deploy once:**  
From `vite-app`: `cd functions && npm install && cd .. && firebase deploy --only functions`

Or from repo root: `cd vite-app && firebase deploy --only functions`

**Region:** `europe-west1` (must match `getFunctions(app, 'europe-west1')` in the app).
