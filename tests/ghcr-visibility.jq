include "ghcr-visibility";

[
  {visibility: "", image: "owner/repo", repo: "owner/repo", private: "false", expected: "public"},
  {visibility: "", image: "owner/repo", repo: "Owner/Repo", private: "false", expected: "public"},
  {visibility: "", image: "owner/other", repo: "owner/repo", private: "false", expected: "private"},
  {visibility: "", image: "other/repo", repo: "owner/repo", private: "false", expected: "private"},
  {visibility: "", image: "owner/repo/nested", repo: "owner/repo", private: "false", expected: "private"},
  {visibility: "", image: "owner/repo", repo: "owner/repo", private: "true", expected: "private"},
  {visibility: "", image: "owner/repo", repo: "owner/repo", private: "", expected: "private"},
  {visibility: "private", image: "owner/repo", repo: "owner/repo", private: "false", expected: "private"},
  {visibility: "public", image: "owner/other", repo: "owner/repo", private: "true", expected: "public"}
]
| map(. as $case
      | ghcr_visibility(.visibility; .image; .repo; .private) as $result
      | if $result != $case.expected then
          error("Unexpected visibility for \($case): \($result)")
        else true
        end)
| all
and (try (ghcr_visibility("invalid"; "owner/repo"; "owner/repo"; "false") | false) catch true)
