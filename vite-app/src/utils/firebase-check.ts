/**
 * Firebase Configuration Verification Utility
 * Checks if all Firebase services are properly initialized
 */

import { app, database, auth, firestore } from "@/lib/firebase";

export interface FirebaseStatus {
  initialized: boolean;
  services: {
    app: boolean;
    auth: boolean;
    firestore: boolean;
    database: boolean;
  };
  config: {
    projectId: string;
    authDomain: string;
    storageBucket: string;
    databaseURL?: string;
  };
}

export function checkFirebaseStatus(): FirebaseStatus {
  const status: FirebaseStatus = {
    initialized: !!app,
    services: {
      app: !!app,
      auth: !!auth,
      firestore: !!firestore,
      database: !!database,
    },
    config: {
      projectId: app?.options?.projectId || "unknown",
      authDomain: app?.options?.authDomain || "unknown",
      storageBucket: app?.options?.storageBucket || "unknown",
      databaseURL: (app?.options as any)?.databaseURL,
    },
  };

  return status;
}

export function logFirebaseStatus(): FirebaseStatus {
  const status = checkFirebaseStatus();

  console.group("🔥 Firebase Status");
  console.log("Initialized:", status.initialized ? "✅" : "❌");
  console.log("\nServices:");
  console.log("  App:", status.services.app ? "✅" : "❌");
  console.log("  Auth:", status.services.auth ? "✅" : "❌");
  console.log("  Firestore:", status.services.firestore ? "✅" : "❌");
  console.log("  Database:", status.services.database ? "✅" : "⚠️ (optional)");
  console.log("\nConfiguration:");
  console.log("  Project ID:", status.config.projectId);
  console.log("  Auth Domain:", status.config.authDomain);
  console.log("  Storage Bucket:", status.config.storageBucket);
  if (status.config.databaseURL) {
    console.log("  Database URL:", status.config.databaseURL);
  }
  console.groupEnd();

  return status;
}

