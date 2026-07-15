ObjC.import("Foundation");

function run(argv) {
  const hookName = argv[0] || "";
  const sourceAppName = argv[1] || "";
  const sourceBundleID = argv[2] || "";
  const inputData = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
  const inputText = ObjC.unwrap(
    $.NSString.alloc.initWithDataEncoding(inputData, $.NSUTF8StringEncoding)
  );

  let input = {};
  try {
    input = JSON.parse(inputText);
  } catch (error) {
    input = {};
  }

  const payload = { hook_event_name: hookName };
  if (input && typeof input.session_id === "string") {
    payload.session_id = input.session_id;
  }
  payload.source = {
    app_name: sourceAppName,
    bundle_id: sourceBundleID,
  };

  return JSON.stringify(payload);
}
