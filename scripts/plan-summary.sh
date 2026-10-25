#!/usr/bin/env bash
# Usage: plan-summary.sh <plan file>
# Writes a Markdown summary of a saved plan to stdout: one row for each action, then the addresses.
set -euo pipefail

plan_json="$(terraform show -json "$1")"

jq -r '
  def action:
    if .change.actions == ["create"] then "create"
    elif .change.actions == ["update"] then "update"
    elif .change.actions == ["delete"] then "delete"
    elif (.change.actions | index("delete")) and (.change.actions | index("create")) then "replace"
    elif .change.importing != null then "import"
    else empty end;

  [.resource_changes[]? | select(.mode == "managed") | {address, action: action}] as $changes
  | ($changes | group_by(.action) | map({key: .[0].action, value: [.[].address]}) | from_entries) as $by
  | "| Action | Count |",
    "|---|---|",
    (["create", "update", "replace", "delete", "import"][] as $a | "| \($a) | \(($by[$a] // []) | length) |"),
    "",
    (if ($changes | length) == 0 then "No changes. The catalog in Dodo Payments matches the configuration."
     else
       (["replace", "delete", "update", "create", "import"][] as $a
        | select($by[$a] != null)
        | "<details><summary>\($a) (\($by[$a] | length))</summary>\n\n" + ($by[$a] | map("- `\(.)`") | join("\n")) + "\n\n</details>")
     end)
' <<<"$plan_json"

destroys="$(jq '[.resource_changes[]? | select(.mode == "managed" and (.change.actions | index("delete")))] | length' <<<"$plan_json")"
if [ "$destroys" -gt 0 ]; then
  printf '\n> [!WARNING]\n> This plan deletes or replaces %s objects. A deleted product or meter is archived. A deleted discount or webhook is gone.\n' "$destroys"
fi
