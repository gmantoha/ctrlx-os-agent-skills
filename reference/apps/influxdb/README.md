# InfluxDB App

Use this folder for InfluxDB operational notes, retention and storage guidance, and troubleshooting references.

## Notes (verified 2026-09-22, ctrlx-influxdb, InfluxDB 2)

- Configuration file via WebDAV: `appdata/influxdb/config.yaml` (bolt-path, engine-path; can point to
  `/media/sda1/...` or a storage extension). Changes need an app restart.
- Node-RED reaches it at `http://localhost:8086` (Node-RED `influxdb` config node, version 2.0, org/bucket as configured).
  The API token lives only in Node-RED `flows_cred.json` (encrypted); reuse the existing config node instead of creating a new one.
- **Data Explorer shows fewer points than stored:** the default query uses `aggregateWindow(every: v.windowPeriod, fn: mean)`.
  With a high-cardinality tag (for example a batch sequence number) each series gets its own mean per window,
  which looks like "2 values every 10 s" although raw data is 1 s. Use "View Raw Data" or a query without aggregation.
- Every distinct tag combination is a series. Do not put ever-increasing counters into tags for long-running buffers
  unless the cardinality is acceptable; use a field instead.
- Buffer pattern with resend: `recipes/node-red/s7-to-rest-with-influx-buffer.md`.
