def ghcr_visibility($visibility; $image_repo; $code_repo; $repo_private):
  if $visibility == "public" or $visibility == "private" then $visibility
  elif $visibility != "" then error("ghcr_visibility must be public or private")
  elif $repo_private == "false" and ($image_repo | ascii_downcase) == ($code_repo | ascii_downcase) then "public"
  else "private"
  end;
