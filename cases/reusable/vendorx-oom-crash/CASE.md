# Case: VendorX apidata Crash During InfluxDB Timeout

## Use When

Use this case when investigating a ctrlX app/service crash with token verifier timeouts, Data Layer disconnects, InfluxDB timeouts, or suspected OOM symptoms.

## Symptoms

- `apidata.service` exits with failure.
- InfluxDB requests time out.
- Token verifier timeout floods appear around the same time.
- Data Layer providers disconnect during the incident.

## Key Finding

The analyzed crash was not an OOM kill. The root cause was an InfluxDB timeout during a blocking TSM cache snapshot, with token verifier and Data Layer errors as downstream system-stress symptoms.

## Details

See `Analyse-apidata-crash-2026-04-17.md`.
For log evidence see `raw/key-evidence.md` (distilled, ~2 KB).
Full raw log in `raw/Explore-logs-2026-04-17 13_36_22.txt` (103 KB) — read only if the key-evidence is insufficient.
