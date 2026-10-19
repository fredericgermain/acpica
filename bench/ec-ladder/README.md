# EC-ladder interpreter benchmark

Microbenchmark behind the numbers in the `parse-op-name-pointer` and `trace-level-gate` commits.

`loopN.asl` calls `\_SB.PCI0.LPCB.ECDV.ECR1 (0x34)` 30000 times from a `While` loop; `loop0.asl` has the
same shape with zero iterations. `ECR1` is Dell's EC read accessor: on a Dell XPS 15 9500 it is a flat
117-way `If ((Arg0 == N))` ladder, and every DPTF sensor read on that laptop goes through it. The reported
cost is `loopN - loop0`, so process start-up, table load and teardown cancel out.

## Running

1. Build `acpiexec` once per variant (`make acpiexec` on master, on each branch, and on both merged).
2. Get a Dell DSDT that has `ECR1` under `\_SB.PCI0.LPCB.ECDV`. On the laptop itself:
   `sudo acpidump -b -n DSDT` (writes `dsdt.dat`, the raw AML). Public dumps of the same
   model are in https://github.com/linuxhw/ACPI. The table is not included here.
3. `CPU=2 ./bench.sh dsdt.dat ./acpiexec-master ./acpiexec-p1 ./acpiexec-p2 ./acpiexec-p12`

`acpiexec` builds with `ACPI_EXEC_APP`, which implies `ACPI_FULL_DEBUG`: debug output is compiled in and
function tracing is off at the default level. That is the configuration of a distribution kernel built
with `CONFIG_ACPI_DEBUG=y`, which both patches target. Interrupt-driven EC access is not modelled;
`acpiexec` serves the EmbeddedControl region from memory, so this measures the interpreter only.

## Result (i7-10750H, `taskset -c 2`, five interleaved rounds)

| variant | instructions | vs master | cycles | vs master |
|---|---|---|---|---|
| master | 64.797 G | 0.00% | 30.332 G | 0.00% |
| p1 (parse-op-name-pointer) | 63.943 G | -1.32% | 29.773 G | -1.84% |
| p2 (trace-level-gate) | 51.574 G | -20.41% | 24.863 G | -18.03% |
| p1+p2 | 50.721 G | -21.72% | 24.300 G | -19.89% |

Raw per-run output: `bench-raw.txt` (variant names there: `p1n` = p1, `p12` = p1+p2). Instruction counts
repeat to five significant figures across rounds.

ASLTS (`tests/aslts.sh -m n64`) on master, p1, p2 and p1+p2: 1866 pass and 183 fail on every one, with no
pass/fail difference; the 183 failures are already on master.

In a Linux 7.0 kernel (Ubuntu 7.0.0-31 source, both patches converted with
`generate/linux/make-patches.sh`, each kernel from a fresh boot) the same thermal-zone read costs
268,284 instructions of ACPI work on master and 203,114 with both patches (-24.3 %), cycles -6 %.
