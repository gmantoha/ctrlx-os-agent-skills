# Key Evidence — influx-crash (2026-04-07)

Raw log: `Explore-logs-2026-04-08 08_37_55.txt` (10,012 lines, 1 MB)
Log covers: 5.54% of time range (6 sec of 1m50s), device timestamps ~12:19–12:19Z UTC

## OOM Kill Event

```
kthreadd invoked oom-killer: gfp_mask=0x400dc0(GFP_KERNEL_ACCOUNT|__GFP_ZERO), order=2, oom_score_adj=0
Out of memory: Killed process 1576622 (python3) total-vm:721696kB, anon-rss:399144kB, file-rss:5992kB, shmem-rss:0kB, UID:0 pgtables:996kB oom_score_adj:0
snapd.service: Killing process 1545318 (snapd) with signal SIGABRT.
snapd.service: State 'stop-watchdog' timed out. Killing.
snapd.service: Killing process 1545318 (snapd) with signal SIGKILL.
```

## Token Verifier Flood

First occurrence: `2026-04-07T12:19:26.021792Z` — `token_verifier.cpp|validateToken|95|Verifier timeout`
**2,460 occurrences** in log (all identical, only timestamps differ — downstream OOM symptom).

## ASGI / InfluxDB Timeout

```
ERROR: Exception in ASGI application
TimeoutError: timed out
urllib3.exceptions.ProtocolError: ('Connection aborted.', TimeoutError('timed out'))
```

## Publisher Disconnect (5 events)

```
(Publisher) Disconnected Event
(Publisher) - Flags: DisconnectFlags(is_disconnect_packet_from_server=False)
```

## Final Log Line

```
Server validation: Failed to write WLS_CMD_VALIDATE response: write unixpacket
/var/snap/rexroth-deviceadmin/5848/auth-service/token-validation.sock->@: write: broken pipe
```

## Signal Ratio

| Category | Count | Notes |
|----------|-------|-------|
| Verifier timeout | 2,460 | Repetitive, one pattern |
| ERROR lines | 4,074 | Mostly same verifier errors |
| OOM events | 4 | Root cause evidence |
| KILL events | 6 | snapd + python3 |
| Exceptions | 6 | Unique stack traces |
| Disconnect | 5 | Downstream symptom |
