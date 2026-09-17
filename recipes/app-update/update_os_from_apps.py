#!/usr/bin/env python3
"""Update ctrlX OS system apps from local .app files via REST (Linux/macOS, Python 3 stdlib + curl).

Verified 2026-09-17 on a Rexroth IPC (arch02, amd64): ctrlX OS 4.4 -> 4.6.5, incl. uninstall of optional apps
and reboots after core24 / hardware support / kernel.

Usage:
  CTRLX_USER=boschrexroth CTRLX_PASSWORD=... \
  python3 update_os_from_apps.py --host 192.168.1.1 --dir ./System_Apps_4.6.5 [--uninstall rexroth-firewall ...] [--dry-run]

  IPv6 link-local host: --host 'fe80::76fe:48ff:febc:c4b0%enp0s31f6'

Design rules (each one learned the hard way):
  * ONE token for the whole run; re-login only on HTTP 401. Logging in per request exhausts the
    per-user session limit -> HTTP 400 "Too many sessions" (080E0200 / 0C7A0202) until reboot.
  * Before every step wait until GET /tasks has no pending/running task (never double-upload).
  * The Location header of POST /packages is RELATIVE ("/tasks/<id>"); POST /tasks returns the full path.
  * Completion = installed release.version == target version (task state may be null / stale).
  * Connection loss or HTTP 502/503/504 = reboot/service restart -> keep waiting (up to 40 min), then continue.
"""
import argparse, json, os, ssl, subprocess, sys, tarfile, time, urllib.error, urllib.parse, urllib.request

SYSTEM_ORDER = ["snapd", "core24", "rexroth-deviceadmin", "rexroth-automationcore", "hw", "kernel",
                "rexroth-setup", "rexroth-solutions", "rexroth-version-guard"]

CTX = ssl.create_default_context(); CTX.check_hostname = False; CTX.verify_mode = ssl.CERT_NONE
BASE = TOK = None; USER = PW = None


def log(*a): print(time.strftime("%H:%M:%S"), *a, flush=True)


def req(method, path, body=None, tok=None, timeout=20):
    h = {"Content-Type": "application/json"}
    if tok: h["Authorization"] = "Bearer " + tok
    r = urllib.request.Request(BASE + path, data=json.dumps(body).encode() if body is not None else None,
                               headers=h, method=method)
    with urllib.request.urlopen(r, context=CTX, timeout=timeout) as resp:
        t = resp.read().decode()
        return resp.status, dict(resp.headers), (json.loads(t) if t.strip().startswith(("{", "[")) else t)


def login(maxwait=2400):
    t0 = time.time(); down = False
    while True:
        try:
            _, _, d = req("POST", "/identity-manager/api/v2/auth/token", {"name": USER, "password": PW}, timeout=10)
            if down: log("  device reachable again")
            return d["access_token"]
        except urllib.error.HTTPError as e:
            if "Too many sessions" in e.read().decode(errors="replace"):
                log("  ERROR: Too many sessions - close sessions in the web UI or reboot"); sys.exit(4)
            if time.time() - t0 > maxwait: raise
            if not down: log(f"  login HTTP {e.code} - waiting ..."); down = True
            time.sleep(10)
        except Exception:
            if time.time() - t0 > maxwait: raise
            if not down: log("  device unreachable (reboot?) - waiting ..."); down = True
            time.sleep(10)


def token():
    global TOK
    if TOK is None: TOK = login()
    return TOK


def api(method, path, body=None, timeout=20):
    global TOK
    t0 = time.time(); down = False
    while True:
        try:
            r = req(method, path, body, tok=token(), timeout=timeout)
            if down: log("  device reachable again")
            return r
        except urllib.error.HTTPError as e:
            if e.code == 401: TOK = None; continue
            if e.code not in (502, 503, 504) or time.time() - t0 > 2400: raise
            if not down: log(f"  HTTP {e.code} (service restarting?) - waiting ..."); down = True
            time.sleep(10)
        except Exception:
            if time.time() - t0 > 2400: raise
            if not down: log("  device unreachable (reboot?) - waiting ..."); down = True
            if time.time() - t0 > 60: TOK = None  # token is gone after a reboot
            time.sleep(10)


def pkgs():
    _, _, d = api("GET", "/package-manager/api/v1/packages")
    return {p["name"]: p for p in d}


def ver(name):
    p = pkgs().get(name)
    return (p.get("release") or {}).get("version") if p else None


def norm(loc):
    if loc and not loc.startswith("/package-manager"): loc = "/package-manager/api/v1" + loc
    return loc


def wait_idle(pkgid):
    last = None
    while True:
        _, _, ts = api("GET", "/package-manager/api/v1/tasks")
        busy = [t for t in ts if t.get("state") in ("pending", "running")]
        if not busy: break
        s = [(t.get("action"), (t.get("parameters") or {}).get("id"), t.get("state"), t.get("progress")) for t in busy]
        if s != last: log("  waiting for running task:", s); last = s
        time.sleep(10)
    mine = [t for t in ts if (t.get("parameters") or {}).get("id") == pkgid]
    if mine and mine[-1].get("state") == "failed":
        log("  ERROR: last task for", pkgid, "failed:", json.dumps(mine[-1].get("result"))); sys.exit(2)


def wait_until(cond, loc, what, maxwait=2700):
    t0 = time.time(); last = None
    while time.time() - t0 < maxwait:
        t = None
        if loc:
            try:
                _, _, t = api("GET", loc)
                t = t if isinstance(t, dict) else None
            except urllib.error.HTTPError:
                t = {"state": "gone"}
        if t:
            s = (t.get("state"), t.get("progress"))
            if s != last: log(f"  task: state={s[0]} progress={s[1]}"); last = s
            if t.get("state") == "failed": log("  ERROR:", json.dumps(t.get("result"))); sys.exit(2)
        if cond() and (not t or t.get("state") in ("done", "gone", None) or t.get("progress") == 100):
            return
        time.sleep(10)
    log("  TIMEOUT:", what); sys.exit(3)


def read_app(path):
    """Return (snap-name, version, archs) from the TAR entries public/snaps/<arch>/release/<name>-<version>.snap."""
    archs = set(); name = version = None
    with tarfile.open(path) as tf:
        for m in tf.getmembers():
            if not m.name.endswith(".snap"): continue
            parts = m.name.split("/"); archs.add(parts[2])
            segs = parts[-1][:-5].split("-")
            i = next(i for i, s in enumerate(segs) if s[:1].isdigit())
            name, version = "-".join(segs[:i]), "-".join(segs[i:])
    return name, version, archs


def order_key(name):
    for i, k in enumerate(SYSTEM_ORDER):
        if name == k or (k in ("hw", "kernel") and name.startswith("rexroth-arch") and name.endswith("-" + k)):
            return i
    return len(SYSTEM_ORDER)


def set_service():
    path = "/automation/api/v2/nodes/scheduler/admin/state"
    _, _, d = api("GET", path); log("device state:", d["value"]["state"])
    if d["value"]["state"] != "SERVICE":
        api("PUT", path, {"type": "object", "value": {"state": "SERVICE"}})
        time.sleep(3); _, _, d = api("GET", path); log("device state now:", d["value"]["state"])


def uninstall(name):
    wait_idle("snap_" + name)
    if name not in pkgs(): log(f"[uninstall] {name}: not installed, skipped"); return
    log(f"[uninstall] {name}")
    st, h, _ = api("POST", "/package-manager/api/v1/tasks", {"action": "uninstall", "parameters": {"id": "snap_" + name}})
    loc = h.get("Location") or h.get("location"); log(f"  HTTP {st}, task {loc}")
    wait_until(lambda: name not in pkgs(), norm(loc), name)
    log(f"  OK: {name} removed")


def install(path, name, target):
    global TOK
    wait_idle("snap_" + name)
    cur = ver(name)
    if cur == target: log(f"[update] {name}: already {target}, skipped"); return
    log(f"[update] {name}: {cur} -> {target}  ({os.path.basename(path)})")
    for _ in range(2):
        pkgs()  # make sure device is up and token valid before a long upload
        out = subprocess.run(["curl", "-sk", "-g", "-i", "--max-time", "1800", "-H", "Expect:", "-H", "Authorization: Bearer " + token(),
                              "-F", "file=@" + path, "-F", "update=true", BASE + "/package-manager/api/v1/packages"],
                             capture_output=True, text=True)
        blocks = [b for b in out.stdout.split("\r\n\r\n") if b.startswith("HTTP/")]
        head = next((b for b in blocks if " 100 " not in b.splitlines()[0]), "")  # skip interim "100 Continue"
        status = head.splitlines()[0] if head else (out.stderr or "no HTTP response")
        if " 401" in status: TOK = None; continue
        break
    loc = next((l.split(":", 1)[1].strip() for l in head.splitlines() if l.lower().startswith("location:")), None)
    log(f"  upload: {status.strip()}  task {loc}")
    if " 20" not in status: log("  response:", out.stdout[-800:]); sys.exit(1)
    wait_until(lambda: ver(name) == target, norm(loc), name)
    log(f"  OK: {name} = {ver(name)}")


def main():
    global BASE, USER, PW
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", required=True, help="IPv4/hostname or IPv6 link-local incl. zone, e.g. fe80::1%%eth0")
    ap.add_argument("--dir", required=True, help="folder with the .app files")
    ap.add_argument("--uninstall", nargs="*", default=[], help="snap names to remove before updating")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    host = a.host
    if host.count(":") > 1 and not host.startswith("["):  # IPv6: bracket + URL-encode zone id (host:port stays)
        host = "[" + host.replace("%", "%25") + "]"
    BASE = "https://" + host
    USER = os.environ.get("CTRLX_USER", "boschrexroth"); PW = os.environ.get("CTRLX_PASSWORD")

    plan = []
    for f in sorted(os.listdir(a.dir)):
        if f.endswith(".app"):
            n, v, archs = read_app(os.path.join(a.dir, f))
            if not n: log(f"skip {f}: no public/snaps/<arch>/release/*.snap inside"); continue
            plan.append((order_key(n), n, v, archs, os.path.join(a.dir, f)))
    plan.sort()
    for _, n, v, archs, p in plan: log(f"plan: {n:28} {v:22} {sorted(archs)}  {os.path.basename(p)}")
    if a.dry_run: return
    if not PW: sys.exit("set CTRLX_PASSWORD")

    set_service()
    for n in a.uninstall: uninstall(n)
    for _, n, v, _, p in plan: install(p, n, v)
    log("== final state ==")
    for n, p in sorted(pkgs().items()): log(f"  {n:30} {(p.get('release') or {}).get('version')}")
    try: req("DELETE", "/identity-manager/api/v2/auth/token", tok=TOK)
    except Exception: pass
    log("DONE - restore the original device state if needed")


if __name__ == "__main__":
    main()
