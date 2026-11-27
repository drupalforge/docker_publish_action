def normalize_init_env:
  if length != 1 or (.[0] | type) != "object" then
    error("Expected one JSON object")
  else
    .[0] | with_entries(
      if (.key | test("^[A-Za-z_][A-Za-z0-9_]*\\z") | not)
        or (.value | type != "string") then
        error("Invalid environment entry")
      elif (.value | contains("\u0000")) then
        error("NUL is not supported")
      elif (.value | test("[\r\n]")) then
        .value |= (try (fromjson | tojson) catch error("Multiline value must be JSON"))
      else .
      end
    )
  end;
