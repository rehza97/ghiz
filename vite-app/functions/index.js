/**
 * Cloud Functions - createAdminUser callable
 * Creates Firebase Auth user + custom claims + admin_users document in Firestore (book DB)
 * Only callable by super_admin or admin.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

if (!getApps().length) {
  initializeApp();
}

const app = getApps()[0];
const auth = getAuth(app);
const validRoles = ["super_admin", "admin", "librarian"];

/**
 * Create admin user (callable by super_admin only).
 * @param {object} data - { email, password, role, displayName?, assignedLibraries? }
 */
export const createAdminUser = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "يجب تسجيل الدخول لإنشاء مستخدمين"
      );
    }

    const callerRole = request.auth.token.role;
    const isAdmin = request.auth.token.isAdmin === true;
    if (callerRole !== "super_admin" && !(isAdmin && callerRole === "admin")) {
      throw new HttpsError(
        "permission-denied",
        "ليس لديك صلاحية إنشاء مستخدمين. مطلوب مدير عام أو مدير."
      );
    }

    const { email, password, role, displayName, assignedLibraries } =
      request.data || {};

    if (!email || typeof email !== "string" || !email.trim()) {
      throw new HttpsError("invalid-argument", "البريد الإلكتروني مطلوب");
    }
    if (!password || typeof password !== "string" || password.length < 6) {
      throw new HttpsError(
        "invalid-argument",
        "كلمة المرور مطلوبة (6 أحرف على الأقل)"
      );
    }
    if (!validRoles.includes(role)) {
      throw new HttpsError(
        "invalid-argument",
        `الدور يجب أن يكون واحداً من: ${validRoles.join(", ")}`
      );
    }

    const name = (displayName && String(displayName).trim()) || "";
    const libraries = Array.isArray(assignedLibraries)
      ? assignedLibraries.filter((id) => typeof id === "string")
      : [];

    let userRecord;
    try {
      userRecord = await auth.createUser({
        email: email.trim(),
        password,
        displayName: name || undefined,
        emailVerified: true,
      });
    } catch (err) {
      if (err.code === "auth/email-already-exists") {
        userRecord = await auth.getUserByEmail(email.trim());
        await auth.updateUser(userRecord.uid, { password });
      } else {
        throw new HttpsError(
          "internal",
          err.message || "فشل في إنشاء المستخدم"
        );
      }
    }

    await auth.setCustomUserClaims(userRecord.uid, {
      role,
      isAdmin: true,
    });

    const adminUserData = {
      id: userRecord.uid,
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: name || userRecord.displayName || "",
      role,
      permissions: {
        canManageLibraries: true,
        canManageBooks: true,
        canManageUsers: role === "super_admin",
        canViewAnalytics: true,
        canManageSystem: role === "super_admin",
      },
      assignedLibraries: libraries,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    try {
      const bookDb = getFirestore(app, "book");
      await bookDb.collection("admin_users").doc(userRecord.uid).set(adminUserData, { merge: true });
    } catch (firestoreErr) {
      console.warn("Firestore admin_users write failed:", firestoreErr.message);
      try {
        const defaultDb = getFirestore(app);
        await defaultDb.collection("admin_users").doc(userRecord.uid).set(adminUserData, { merge: true });
      } catch (e2) {
        console.warn("Default DB admin_users write failed:", e2.message);
      }
    }

    return {
      uid: userRecord.uid,
      email: userRecord.email,
      role,
      message: "تم إنشاء المستخدم بنجاح",
    };
  }
);
