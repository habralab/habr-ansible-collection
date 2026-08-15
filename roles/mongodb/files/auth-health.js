const admin = db.getSiblingDB(process.env.MONGODB_ADMIN_DATABASE || "admin");

if (!admin.auth(process.env.MONGODB_ADMIN_USER, process.env.MONGODB_ADMIN_PASSWORD)) {
  quit(2);
}

const result = admin.runCommand({ ping: 1 });
quit(result.ok === 1 ? 0 : 3);
