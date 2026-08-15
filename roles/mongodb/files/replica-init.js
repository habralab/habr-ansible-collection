const admin = db.getSiblingDB(process.env.MONGODB_ADMIN_DATABASE || "admin");

try {
  admin.auth(process.env.MONGODB_ADMIN_USER, process.env.MONGODB_ADMIN_PASSWORD);
} catch (error) {
  // The localhost exception permits replica-set initiation before the first user.
}

const result = admin.runCommand({
  replSetInitiate: {
    _id: process.env.MONGODB_REPLICA_SET_NAME,
    members: [{ _id: 0, host: process.env.MONGODB_REPLICA_SET_MEMBER }],
  },
});
if (result.ok !== 1) {
  print(EJSON.stringify(result));
  quit(2);
}
