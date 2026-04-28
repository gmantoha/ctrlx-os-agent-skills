# Case: Linck apidata Crash During InfluxDB Timeout

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
