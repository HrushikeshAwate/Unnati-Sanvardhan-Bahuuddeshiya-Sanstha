const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteUserAuthAccount = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const callerSnap = await admin
      .firestore()
      .collection("users")
      .doc(callerUid)
      .get();

  if (!callerSnap.exists || callerSnap.data()?.role !== "superadmin") {
    throw new HttpsError(
        "permission-denied",
        "Only superadmin can delete users.",
    );
  }

  const targetUid = request.data?.uid;
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError("invalid-argument", "Target uid is required.");
  }

  if (targetUid === callerUid) {
    throw new HttpsError(
        "failed-precondition",
        "Superadmin cannot delete own auth account.",
    );
  }

  const targetSnap = await admin
      .firestore()
      .collection("users")
      .doc(targetUid)
      .get();

  if (targetSnap.exists && targetSnap.data()?.role === "superadmin") {
    throw new HttpsError(
        "permission-denied",
        "Cannot delete another superadmin.",
    );
  }

  try {
    await admin.auth().deleteUser(targetUid);
  } catch (error) {
    if (error?.code === "auth/user-not-found") {
      return { success: true, authDeleted: false, reason: "user-not-found" };
    }
    throw error;
  }

  return { success: true, authDeleted: true };
});
