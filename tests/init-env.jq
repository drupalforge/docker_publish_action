include "init-env";

def rejects: try (normalize_init_env | false) catch true;

[
  ([{}] | normalize_init_env == {}),
  ([{"EMPTY": "", "SINGLE": " { \"a\": 1 } ", "EQUALS": "a=b"}]
    | normalize_init_env == {"EMPTY": "", "SINGLE": " { \"a\": 1 } ", "EQUALS": "a=b"}),
  ([{"AUTH": "{\r\n  \"token\": \"a=b\",\n  \"nested\": [1, 2]\n}"}]
    | normalize_init_env == {"AUTH": "{\"token\":\"a=b\",\"nested\":[1,2]}"}),
  ([{"VALUE": "\"line\\ninside\"\n"}]
    | normalize_init_env == {"VALUE": "\"line\\ninside\""}),
  ([{"VALUE": "not\njson"}] | rejects),
  ([{"VALUE": "bad\u0000value"}] | rejects),
  ([{"BAD-NAME": "value"}] | rejects),
  ([{"VALUE": 1}] | rejects),
  ([[]] | rejects),
  ([{}, {}] | rejects),
  ([] | rejects)
] | all
