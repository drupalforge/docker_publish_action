include "build-strategy";

[
  {platform: "linux/amd64", runner: "X64", dockerhub: false, emulated: false, cloud: false},
  {platform: "", runner: "X64", dockerhub: true, emulated: false, cloud: false},
  {platform: "linux/arm64", runner: "ARM64", dockerhub: true, emulated: false, cloud: false},
  {platform: "linux/arm64/v8", runner: "ARM64", dockerhub: false, emulated: false, cloud: false},
  {platform: "linux/arm/v7", runner: "ARM", dockerhub: true, emulated: false, cloud: false},
  {platform: "linux/arm64", runner: "X64", dockerhub: false, emulated: true, cloud: false},
  {platform: "linux/arm64", runner: "X64", dockerhub: true, emulated: true, cloud: true},
  {platform: "linux/amd64", runner: "ARM64", dockerhub: true, emulated: true, cloud: true},
  {platform: "", runner: "ARM64", dockerhub: false, emulated: true, cloud: false},
  {platform: "linux/amd64, linux/arm64", runner: "X64", dockerhub: true, emulated: true, cloud: true}
]
| map(. as $case
      | emulation_required(.platform; .runner) as $emulated
      | build_strategy(.platform; .runner; .dockerhub) as $strategy
      | if $emulated != $case.emulated then
          error("Unexpected emulation requirement for \($case): \($emulated)")
        elif $strategy != {emulated: $case.emulated, use_cloud: $case.cloud} then
          error("Unexpected strategy for \($case): \($strategy)")
        else true
        end)
| all
