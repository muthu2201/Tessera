# Tessera ECP5 CI build report

## Observed result

GitHub Actions run: https://github.com/muthu2201/Tessera/actions/runs/39687038565

The job completed successfully through Icarus Verilog compilation, directed and randomized dispatcher tests, generic Yosys synthesis and structural checks, Yosys ECP5 mapping, and nextpnr-ecp5 placement/routing estimate.

## Reported implementation estimates

For the current four-client dispatcher and the CI-selected ECP5 25k device/package/speed settings:
- nextpnr reported a maximum frequency of approximately **354.48 MHz** in one timing report and **367.11 MHz** in another report.
- It reported passing the configured **50 MHz** target.
- One resource summary reported 165 `TRELLIS_COMB`, 2 `TRELLIS_FF`, and 69 `TRELLIS_IO` cells.

These are tool estimates for this tiny dispatcher, not measurements from a physical board. The two timing figures differ because the flow emits multiple timing summaries. The CI command allows unconstrained I/O, so external input/output delays and real board pin constraints are not modeled. Do not interpret the result as board-level timing closure or as a performance claim for the complete Tessera architecture.

Artifact: `tessera-ecp5-build`, downloadable from the linked Actions run.
