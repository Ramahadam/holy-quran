#!/usr/bin/env bash
set -euo pipefail

git ls-files --cached --others --exclude-standard -z -- \
  '*.dart' ':(exclude,glob)**/*.g.dart' \
  | xargs -0 dart format --output=none --set-exit-if-changed
