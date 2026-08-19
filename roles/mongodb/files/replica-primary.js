const admin = db.getSiblingDB(process.env.MONGODB_ADMIN_DATABASE || "admin");

try {
  admin.auth(process.env.MONGODB_ADMIN_USER, process.env.MONGODB_ADMIN_PASSWORD);
} catch (error) {
  // The localhost exception remains active until the first user is created.
}

const result = admin.runCommand({ replSetGetStatus: 1 });
quit(result.ok === 1 && result.myState === 1 ? 0 : 1);
