# Case: InfluxDB Hang During System-Wide OOM Event

## Use When

Use this case when investigating an apparent InfluxDB crash, hang, or unresponsive HTTP API on a ctrlX M4 or similar memory-constrained device, especially when ctrlx-vendorx or other Python-heavy snaps are running.

## Symptoms

- InfluxDB HTTP API becomes unreachable.
- InfluxDB appears to have crashed but recovers on its own.
- Token verifier timeouts and Data Layer disconnects appear around the same time.
- ctrlx-vendorx (or similar app) runs multiple Python processes with high RSS.

## Key Finding

InfluxDB did not crash. A system-wide kernel OOM event caused InfluxDB to temporarily stop responding. InfluxDB was a downstream victim, not the root cause.

The ctrlx-vendorx snap ran 6 concurrent Python processes consuming ~838 MB RAM (~41% of the 2 GB device). One worker (PID 1576622) alone reached 390 MB RSS / 721 MB virtual. With no swap configured, the kernel OOM killer triggered when a routine kernel thread allocation needed only 4 contiguous pages.

A positive feedback loop amplified the event: ctrlx-vendorx buffers InfluxDB write data in memory when InfluxDB is slow. Early memory pressure slowed InfluxDB → the in-memory write queue grew → memory pressure worsened further.

## Platform

- Device: ctrlX M4 (ARM64)
- Kernel: 6.1.80-rt26-ctrlx-43
- Date: 2026-04-07, log window 12:19Z–13:01Z

## Details

See `analysis-email.html` for the full incident report and timeline.
For log evidence see `raw/key-evidence.md` (distilled, ~2 KB).
Full raw log in `raw/Explore-logs-2026-04-08 08_37_55.txt` (1 MB, 10k lines) — read only if the key-evidence is insufficient.
