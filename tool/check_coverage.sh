#!/usr/bin/env bash
set -euo pipefail

lcov_file="${1:-coverage/lcov.info}"

if [[ ! -f "$lcov_file" ]]; then
  echo "Coverage file not found: $lcov_file" >&2
  echo "Run: flutter test --coverage" >&2
  exit 1
fi

awk -F: '
function percent(hit, found) {
  if (found == 0) return 0
  return (hit * 100) / found
}
/^SF:/ {
  source = substr($0, 4)
  hit = 0
  found = 0
}
/^LF:/ { found = substr($0, 4) + 0 }
/^LH:/ { hit = substr($0, 4) + 0 }
/^end_of_record/ {
  all_hit += hit
  all_found += found
  if (source ~ /^lib\/models\//) {
    models_hit += hit
    models_found += found
  } else if (source ~ /^lib\/services\//) {
    services_hit += hit
    services_found += found
  } else if (source ~ /^lib\/providers\//) {
    providers_hit += hit
    providers_found += found
  }
  source = ""
}
END {
  bad = 0
  groups[1] = "models"; group_hit[1] = models_hit; group_found[1] = models_found
  groups[2] = "services"; group_hit[2] = services_hit; group_found[2] = services_found
  groups[3] = "providers"; group_hit[3] = providers_hit; group_found[3] = providers_found

  for (i = 1; i <= 3; i++) {
    value = percent(group_hit[i], group_found[i])
    printf "%-12s %6.2f%%  (%d of %d lines)\n", groups[i], value, group_hit[i], group_found[i]
    if (group_found[i] == 0 || value < 80) bad = 1
  }

  overall = percent(all_hit, all_found)
  printf "%-12s %6.2f%%  (%d of %d lines)\n", "overall", overall, all_hit, all_found
  if (all_found == 0 || overall < 60) bad = 1

  if (bad) {
    print "Coverage gate failed: models, services, and providers must be at least 80%, overall at least 60%." > "/dev/stderr"
    exit 1
  }
  print "Coverage gate passed."
}
' "$lcov_file"
