const admin = db.getSiblingDB(process.env.MONGODB_ADMIN_DATABASE || "admin");

try {
  admin.auth(process.env.MONGODB_ADMIN_USER, process.env.MONGODB_ADMIN_PASSWORD);
} catch (error) {
  // The localhost exception permits replica-set inspection before the first user.
}

let result;
try {
  result = admin.runCommand({ replSetGetStatus: 1 });
} catch (error) {
  if (error.code === 94 || error.codeName === "NotYetInitialized") {
    quit(94);
  }
  print(EJSON.stringify(error));
  quit(2);
}

if (result.ok === 1) {
  quit(0);
}
if (result.code === 94 || result.codeName === "NotYetInitialized") {
  quit(94);
}
print(EJSON.stringify(result));
quit(2);
