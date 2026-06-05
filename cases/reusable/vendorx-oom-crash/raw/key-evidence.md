# Key Evidence — vendorx-oom-crash (2026-04-17)

Raw log: `Explore-logs-2026-04-17 13_36_22.txt` (1,569 lines, 103 KB)
Log window: 2026-04-17 13:20:09 – 13:33:03 (device time)

## Dominant Error: rda-proxy-service connection refused

**110 occurrences** (one per ~60s), identical pattern:
```
error send Events: failed to send request:
Post "http://localhost/bulk/v1/events":
dial unix /var/snap/rexroth-deviceadmin/common/rda-proxy-service/rexroth-deviceadmin/proxy.sock:
connect: connection refused
```
First at 13:20:52, last at 13:33:03. rexroth-deviceadmin proxy socket unavailable throughout.

## Root Cause: InfluxDB Read Timeout (Thread crash)

```
Exception in thread Thread-1 (loop):
urllib3.exceptions.ReadTimeoutError:
  HTTPConnectionPool(host='127.0.0.1', port=8086): Read timed out. (read timeout=9.96s)
urllib3.exceptions.ReadTimeoutError:
  HTTPConnectionPool(host='127.0.0.1', port=8086): Read timed out. (read timeout=9.99s)
```
InfluxDB blocked on TSM cache snapshot → ctrlx-vendorx write thread killed by unhandled exception.

## Token Verifier Timeouts (Late Symptom)

First occurrence: `2026-04-17T11:31:52.425658Z` (at log time 13:32:58 — 12 min into the window)
Multiple identical `token_verifier.cpp|validateToken|95|Verifier timeout` entries — system stress indicator, not root cause.

## InfluxDB Auth: Unauthorized

```
ts=2026-04-17T11:30:09.962902Z lvl=info msg=Unauthorized log_id=12DVKPWG000 error="token required"
```

## PLC Identity Handle Missing

```
[idm] Error: get plc handle: 404 Not Found
{"title":"DL_INVALID_ADDRESS","detail":"Can't read type information","instance":"plc/admin/identity-management/userhandles"}
```

## Final Log Line

```
onSubscribe result: DL_TIMEOUT  (licensemanager subscription)
```

## Signal Ratio

| Category | Count | Notes |
|----------|-------|-------|
| connection refused (proxy.sock) | 110 | One pattern, ~60s interval |
| Verifier timeout | 55 | Late symptom, not cause |
| InfluxDB read timeout | ~10 | Root cause stack traces |
| Exceptions/Tracebacks | 5 | Unique crash events |
