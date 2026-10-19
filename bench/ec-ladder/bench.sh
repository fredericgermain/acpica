#!/bin/bash
# Usage: bench.sh <dsdt.aml> <acpiexec-A> [<acpiexec-B> ...]
# Runs loopN.asl (30000 calls to the EC read method ECR1) and loop0.asl (same method, zero iterations)
# under each acpiexec binary, five interleaved rounds, with perf stat. Interpreter cost = loopN - loop0.
# Pinned to one CPU (CPU=2 by default). Checks that MAIN returned the expected count.
set -u
DSDT=$1; shift
HERE=$(cd "$(dirname "$0")" && pwd); T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
CPU=${CPU:-2}
iasl -p "$T/loopN" "$HERE/loopN.asl" >/dev/null && iasl -p "$T/loop0" "$HERE/loop0.asl" >/dev/null || { echo "iasl failed"; exit 1; }
one() { # one <acpiexec> <loop0|loopN>
  taskset -c "$CPU" perf stat -x, -e instructions,cycles -- \
    "$1" -dt -to 600 -m "$DSDT" "$T/$2.aml" >"$T/out" 2>"$T/perf"
  ins=$(awk -F, '/instructions/{print $1}' "$T/perf"); cyc=$(awk -F, '/cycles/{print $1}' "$T/perf")
  [ "$2" = loopN ] && want=0000000000007530 || want=0000000000000000
  grep -q "\[Integer\] = $want" "$T/out" && ok=ok || ok=ABORT
  echo "$ins $cyc $ok"
}
for v in "$@"; do one "$v" loopN >/dev/null; done   # warm-up
echo "binary load instructions cycles status"
for r in 1 2 3 4 5; do
  for v in "$@"; do for L in loop0 loopN; do echo "$(basename "$v") $L $(one "$v" $L)"; done; done
done
