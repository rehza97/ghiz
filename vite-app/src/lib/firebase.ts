import { initializeApp, getApps } from "firebase/app";
import { getDatabase, connectDatabaseEmulator } from "firebase/database";
import { getAuth, connectAuthEmulator } from "firebase/auth";
import { getFirestore, connectFirestoreEmulator } from "firebase/firestore";
import { getFunctions, connectFunctionsEmulator } from "firebase/functions";

// Firebase configuration
const firebaseConfig = {
  apiKey:
    import.meta.env.VITE_FIREBASE_API_KEY ||
    "AIzaSyB3FMXqnWvA6UNQ0SHJ_sgK9jK5NsQWfBk",
  authDomain:
    import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ||
    "spyware-7bfe6.firebaseapp.com",
  databaseURL:
    import.meta.env.VITE_FIREBASE_DATABASE_URL ||
    "https://spyware-7bfe6-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "spyware-7bfe6",
  storageBucket:
    import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "spyware-7bfe6.appspot.com",
  messagingSenderId:
    import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "53191143209",
  appId:
    import.meta.env.VITE_FIREBASE_APP_ID ||
    "1:53191143209:web:b4c1ef023455f8ccbed138",
};

// Initialize Firebase
let app: ReturnType<typeof initializeApp>;
if (getApps().length === 0) {
  app = initializeApp(firebaseConfig);
} else {
  app = getApps()[0];
}

// Initialize services
let database: ReturnType<typeof getDatabase> | null = null;
let auth: ReturnType<typeof getAuth> | null = null;
let firestore: ReturnType<typeof getFirestore> | null = null;
let functions: ReturnType<typeof getFunctions> | null = null;

try {
  // Initialize Realtime Database (only if databaseURL is configured)
  if (firebaseConfig.databaseURL) {
    try {
      database = getDatabase(app);
      // Connect to emulator in development if needed
      if (
        import.meta.env.DEV &&
        import.meta.env.VITE_USE_FIREBASE_EMULATOR === "true"
      ) {
        try {
          connectDatabaseEmulator(database, "localhost", 9000);
        } catch (emulatorError) {
          // Emulator already connected or error connecting
          console.warn("Database emulator connection:", emulatorError);
        }
      }
    } catch (dbError) {
      console.error("Database initialization error:", dbError);
    }
  } else {
    console.warn("Realtime Database not configured (databaseURL missing)");
  }

  // Initialize Authentication
  try {
    auth = getAuth(app);
    // Connect to emulator in development if needed
    if (
      import.meta.env.DEV &&
      import.meta.env.VITE_USE_FIREBASE_EMULATOR === "true"
    ) {
      try {
        connectAuthEmulator(auth, "http://localhost:9099", {
          disableWarnings: true,
        });
      } catch (emulatorError) {
        // Emulator already connected or error connecting
        console.warn("Auth emulator connection:", emulatorError);
      }
    }
  } catch (authError) {
    console.error("Auth initialization error:", authError);
  }

  // Initialize Firestore
  try {
    // Use the "book" database as configured in firebase.json
    const databaseName = import.meta.env.VITE_FIRESTORE_DATABASE || "book";
    firestore = getFirestore(app, databaseName);
    // Connect to emulator in development if needed
    if (
      import.meta.env.DEV &&
      import.meta.env.VITE_USE_FIREBASE_EMULATOR === "true"
    ) {
      try {
        connectFirestoreEmulator(firestore, "localhost", 8080);
      } catch (emulatorError) {
        // Emulator already connected or error connecting
        console.warn("Firestore emulator connection:", emulatorError);
      }
    }
  } catch (firestoreError) {
    console.error("Firestore initialization error:", firestoreError);
  }

  try {
    functions = getFunctions(app, "europe-west1");
    if (
      import.meta.env.DEV &&
      import.meta.env.VITE_USE_FIREBASE_EMULATOR === "true"
    ) {
      try {
        connectFunctionsEmulator(functions, "localhost", 5001);
      } catch (emulatorError) {
        console.warn("Functions emulator connection:", emulatorError);
      }
    }
  } catch (functionsError) {
    console.error("Functions initialization error:", functionsError);
  }
} catch (error) {
  console.error("Firebase initialization error:", error);
}

export { app, database, auth, firestore, functions };
export default app;
