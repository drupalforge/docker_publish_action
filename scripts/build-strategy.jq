def emulation_required($platforms; $runner_arch):
  (if $runner_arch == "X64" then "amd64"
   elif $runner_arch == "ARM64" then "arm64"
   elif $runner_arch == "ARM" then "arm"
   else error("Unsupported runner architecture: \($runner_arch)")
   end) as $native_arch
  | (if $platforms == "" then "linux/amd64" else $platforms end
     | split(",")
     | any(.[];
         gsub("^\\s+|\\s+$"; "")
         | split("/")
         | if length < 2 then error("Invalid target platform: \($platforms)")
           else .[0] != "linux" or .[1] != $native_arch
           end));

def build_strategy($platforms; $runner_arch; $use_dockerhub):
  emulation_required($platforms; $runner_arch) as $emulated
  | {emulated: $emulated, use_cloud: ($emulated and $use_dockerhub)};
