const admin = db.getSiblingDB(process.env.MONGODB_ADMIN_DATABASE || "admin");
const result = admin.runCommand({
  createUser: process.env.MONGODB_ADMIN_USER,
  pwd: process.env.MONGODB_ADMIN_PASSWORD,
  roles: JSON.parse(process.env.MONGODB_ADMIN_ROLES),
});

if (result.ok !== 1) {
  print(EJSON.stringify(result));
  quit(2);
}
