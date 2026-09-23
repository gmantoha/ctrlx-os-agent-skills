#!/usr/bin/env python3
"""Erzeugt die Node-RED-Nodes für Flow 2 (S7 -> REST mit InfluxDB-Puffer) als JSON-Liste."""
import json, sys

TAB = "f2claude00000001"   # Tab-ID des Ziel-Flows (Tab-Node selbst wird nicht erzeugt)
INFLUX_CFG = "<influxdb-config-node-id>"   # ID des vorhandenen InfluxDB-Config-Nodes auf dem Gerät (Token liegt in flows_cred.json)
CONFIG_DIR = "/var/snap/ctrlx-node-red/current/solutions/activeConfiguration/node-RED/config"
S7_LIB_MODULE = sys.argv[1] if len(sys.argv) > 1 else "@st-one-io/nodes7"
S7_NODE_DISABLED = (sys.argv[2] == "disabled") if len(sys.argv) > 2 else False

# ---------------------------------------------------------------- Function-Code
FN_LOAD = r'''
// Liest s7-config.json (mehrere S7, je mit objectId) und rest-config.json aus dem Node-RED-App-Daten-Ordner,
// validiert sie, setzt Defaults und verteilt die Konfiguration an alle Nodes.
const dir = (env.get("SNAP_DATA") || "/var/snap/ctrlx-node-red/current") + "/solutions/activeConfiguration/node-RED/config";
const errors = [];
function readJson(name) {
    try { return JSON.parse(fs.readFileSync(dir + "/" + name, "utf8")); }
    catch (e) { errors.push(name + ": " + e.message); return null; }
}
const s7raw = readJson("s7-config.json");
const rest = readJson("rest-config.json");
if (rest) for (const k of ["url", "publicKey", "privateKey"]) if (!rest[k]) errors.push("rest-config.json: '" + k + "' fehlt");
let plcs = null;
if (s7raw) {
    const defaults = Object.assign({ port: 102, rack: 0, slot: 2, cycleTimeMs: 1000, timeoutMs: 2000, reconnectMs: 5000, sendMode: "all", simulate: false, enabled: true }, s7raw.defaults || {});
    const list = Array.isArray(s7raw.plcs) ? s7raw.plcs : (s7raw.host ? [s7raw] : null);   // altes Einzel-S7-Format wird weiter akzeptiert
    if (!list || !list.length) errors.push("s7-config.json: 'plcs' fehlt oder leer");
    else {
        plcs = list.map((p, i) => Object.assign({}, defaults, p, { id: p.id || ("plc" + (i + 1)) }));
        const ids = new Set();
        plcs.forEach((p, i) => {
            const n = "s7-config.json: plcs[" + i + "] (" + p.id + ")";
            if (ids.has(p.id)) errors.push(n + ": 'id' doppelt"); ids.add(p.id);
            if (!p.host) errors.push(n + ": 'host' fehlt");
            if (!p.objectId && !(rest && rest.objectId)) errors.push(n + ": 'objectId' fehlt (und kein Standard 'objectId' in rest-config.json)");
            if (!Array.isArray(p.variables) || !p.variables.length) errors.push(n + ": 'variables' fehlt oder leer");
            else p.variables.forEach((v, j) => { if (!v.name || !v.addr) errors.push(n + ": variables[" + j + "] braucht 'name' und 'addr'"); });
        });
    }
}
if (errors.length) {
    node.status({ fill: "red", shape: "ring", text: "Konfig-Fehler (siehe Debug)" });
    const st = flow.get("status") || {}; st.config = { ok: false, errors, at: new Date().toISOString(), dir }; flow.set("status", st);
    node.error("Konfiguration fehlerhaft: " + errors.join(" | "), msg);
    return null;
}
plcs.forEach(p => { if (!p.objectId) p.objectId = rest.objectId; });
const cfg = {
    plcs,
    rest: Object.assign({ method: "upload-data", uploadIntervalMs: 10000, timeoutMs: 10000, dtFormat: "local",
        resendCheckIntervalMs: 30000, resendChunkSize: 500, bufferBucket: "iot", bufferMeasurement: "rest_buffer", bufferLookback: "30d", objects: {} }, rest),
    loadedAt: new Date().toISOString(), dir
};
flow.set("cfg", cfg);
// Puffer-Zeiger initialisieren (Sequenznummer des letzten nachgesendeten Batches)
if (flow.get("bufferCursor", "file") === undefined) {
    flow.set("bufferCursor", flow.get("bufferSeq", "file") || 0, "file");
    flow.set("bufferPending", false, "file");
} else {
    flow.set("bufferPending", true, "file");   // nach Neustart einmal prüfen, ob Rückstand existiert
}
if (flow.get("restOnline") === undefined) flow.set("restOnline", true);
const st = flow.get("status") || {};
st.config = { ok: true, loadedAt: cfg.loadedAt, dir, restUrl: cfg.rest.url, uploadIntervalMs: cfg.rest.uploadIntervalMs,
    plcs: plcs.map(p => ({ id: p.id, host: p.host, objectId: p.objectId, enabled: p.enabled, simulate: p.simulate, variables: p.variables.map(v => v.name) })) };
flow.set("status", st);
const act = plcs.filter(p => p.enabled);
node.status({ fill: "green", shape: "dot", text: act.length + " S7 (" + act.filter(p => p.simulate).length + " simuliert), " + new Set(act.map(p => p.objectId)).size + " ObjectIDs, Upload " + cfg.rest.uploadIntervalMs / 1000 + " s" });
return { topic: "config", payload: cfg };
'''

FN_S7 = r'''
// Echte S7-Verbindungen über die Bibliothek @st-one-io/nodes7 (dieselbe, die node-red-contrib-s7 verwendet).
// Verwaltet alle S7 aus s7-config.json mit enabled=true und simulate=false; jede S7 sendet mit ihrer objectId.
if (msg.topic !== "config") return null;
const all = context.get("plcs") || {};
for (const s of Object.values(all)) { try { clearInterval(s.timer); s.plc.removeAllListeners(); s.plc.disconnect().catch(() => {}); } catch (e) { /* ignorieren */ } }
context.set("plcs", {});
const stReset = flow.get("status") || {}; stReset.s7 = {}; flow.set("status", stReset);

const active = msg.payload.plcs.filter(p => p.enabled && !p.simulate);
if (!active.length) { node.status({ fill: "grey", shape: "ring", text: "keine echte S7 aktiv" }); return null; }
const states = {};
for (const p of active) states[p.id] = startPlc(p);
context.set("plcs", states);
node.status({ fill: "yellow", shape: "ring", text: "starte " + active.length + " S7" });
return null;

function setStatus(id, s) {
    const st = flow.get("status") || {}; st.s7 = st.s7 || {};
    st.s7[id] = Object.assign(st.s7[id] || {}, s, { simulated: false, at: new Date().toISOString() });
    flow.set("status", st);
}
function updateNodeStatus() {
    const st = Object.values(context.get("plcs") || {});
    const on = st.filter(s => s.plc.isConnected).length;
    node.status({ fill: on === st.length ? "green" : (on ? "yellow" : "red"), shape: "dot", text: on + "/" + st.length + " S7 online" });
}
function startPlc(p) {
    const addr = {}, dpOf = {};
    for (const v of p.variables) { addr[v.name] = v.addr; dpOf[v.name] = v.datapoint || v.name; }
    const plc = new nodes7.S7Endpoint({
        host: p.host, port: Number(p.port), rack: Number(p.rack), slot: Number(p.slot),
        autoReconnect: Number(p.reconnectMs), s7ConnOpts: { timeout: Number(p.timeoutMs) }
    });
    const group = new nodes7.S7ItemGroup(plc);
    group.setTranslationCB(n => addr[n]);
    group.addItems(Object.keys(addr));
    const state = { plc, group, timer: null, reading: false, last: {}, lastErr: "" };
    function cycle() {
        if (state.reading || !plc.isConnected) return;
        state.reading = true;
        group.readAllItems().then(values => {
            state.reading = false;
            const ts = Date.now(), out = {}; let n = 0;
            for (const [name, raw] of Object.entries(values)) {
                let v = raw;
                if (typeof v === "boolean") v = v ? 1 : 0;
                if (typeof v !== "number" || !isFinite(v)) continue;   // Arrays/Strings werden nicht übertragen
                if (p.sendMode === "changed" && state.last[name] === v) continue;
                state.last[name] = v; out[dpOf[name]] = v; n++;
            }
            setStatus(p.id, { online: true, host: p.host, objectId: p.objectId, lastRead: new Date(ts).toISOString(), values });
            if (n) node.send({ topic: "sample", plcId: p.id, objectId: p.objectId, ts, payload: out });
        }).catch(e => {
            state.reading = false;
            node.warn("S7 " + p.id + " Lesefehler: " + (e && e.message || e));
        });
    }
    plc.on("connect", () => {
        setStatus(p.id, { online: true, host: p.host, objectId: p.objectId, connectedAt: new Date().toISOString() });
        clearInterval(state.timer);
        state.timer = setInterval(cycle, Math.max(50, Number(p.cycleTimeMs)));
        cycle(); updateNodeStatus();
    });
    plc.on("disconnect", () => {
        clearInterval(state.timer); state.timer = null; state.reading = false;
        setStatus(p.id, { online: false, disconnectedAt: new Date().toISOString() });
        updateNodeStatus();
    });
    plc.on("error", e => {
        const m = String(e && e.message || e);
        setStatus(p.id, { online: false, lastError: m });
        if (m !== state.lastErr) { state.lastErr = m; node.warn("S7 " + p.id + " (" + p.host + ") Fehler: " + m); }
    });
    return state;
}
'''
FN_S7_STOP = r'''
const all = context.get("plcs") || {};
for (const s of Object.values(all)) { try { clearInterval(s.timer); s.plc.removeAllListeners(); s.plc.disconnect().catch(() => {}); } catch (e) {} }
context.set("plcs", {});
'''

FN_SIM = r'''
// Simulator: erzeugt für jede S7 mit simulate=true Zufallswerte (Random Walk 0..100)
// im selben Nachrichtenformat wie der echte S7-Poller (inkl. objectId).
if (msg.topic !== "config") return null;
const old = context.get("sims") || {};
for (const s of Object.values(old)) clearInterval(s.timer);
context.set("sims", {});
const active = msg.payload.plcs.filter(p => p.enabled && p.simulate);
if (!active.length) { node.status({ fill: "grey", shape: "ring", text: "inaktiv" }); return null; }
const sims = {};
for (const p of active) {
    const state = { timer: null, vals: {}, last: {} };
    for (const v of p.variables) state.vals[v.name] = 50;
    state.timer = setInterval(() => {
        const ts = Date.now(), out = {}; let n = 0;
        for (const v of p.variables) {
            let x = state.vals[v.name] + (Math.random() - 0.5) * 4;
            x = Math.round(Math.min(100, Math.max(0, x)) * 100) / 100;
            state.vals[v.name] = x;
            if (p.sendMode === "changed" && state.last[v.name] === x) continue;
            state.last[v.name] = x; out[v.datapoint || v.name] = x; n++;
        }
        const st = flow.get("status") || {}; st.s7 = st.s7 || {};
        st.s7[p.id] = { online: true, simulated: true, host: p.host, objectId: p.objectId, lastRead: new Date(ts).toISOString(), values: Object.assign({}, state.vals), at: new Date(ts).toISOString() };
        flow.set("status", st);
        if (n) node.send({ topic: "sample", plcId: p.id, objectId: p.objectId, ts, payload: out });
    }, Math.max(50, Number(p.cycleTimeMs)));
    sims[p.id] = state;
}
context.set("sims", sims);
node.status({ fill: "blue", shape: "dot", text: active.length + " S7 simuliert" });
return null;
'''
FN_SIM_STOP = r'''
const old = context.get("sims") || {};
for (const s of Object.values(old)) clearInterval(s.timer);
context.set("sims", {});
'''

FN_COLLECT = r'''
// Sammelt die S7-Werte getrennt nach objectId und löst alle uploadIntervalMs je objectId einen Upload-Batch aus.
function flush() {
    const pend = context.get("pending") || {};
    context.set("pending", {});
    let total = 0;
    for (const [objectId, samples] of Object.entries(pend)) {
        if (!samples.length) continue;
        total += samples.length;
        node.send({ topic: "upload", kind: "live", objectId, samples });
    }
    if (total) node.status({ fill: "green", shape: "ring", text: total + " Werte in " + Object.keys(pend).length + " Batch(es)" });
}
if (msg.topic === "config") {
    const iv = Math.max(1000, Number(msg.payload.rest.uploadIntervalMs));
    const old = context.get("timer"); if (old) clearInterval(old);
    context.set("timer", setInterval(flush, iv));
    node.status({ fill: "green", shape: "ring", text: "Upload alle " + iv / 1000 + " s" });
    return null;
}
if (msg.topic === "sample") {
    const pend = context.get("pending") || {};
    const list = pend[msg.objectId] = pend[msg.objectId] || [];
    for (const [dp, value] of Object.entries(msg.payload)) list.push({ dp, value, ts: msg.ts });
    context.set("pending", pend);
    const total = Object.values(pend).reduce((a, l) => a + l.length, 0);
    node.status({ fill: "green", shape: "dot", text: total + " Werte gesammelt (" + Object.keys(pend).length + " ObjectIDs)" });
    return null;
}
if (msg.topic === "flush") flush();
return null;
'''
FN_COLLECT_STOP = r'''
const old = context.get("timer"); if (old) clearInterval(old); context.set("timer", null);
'''

FN_PREPARE = r'''
// Baut aus msg.samples ([{dp, value, ts}]) den signierten Request für den REST Data-Receiver.
// Ziel-ObjectID kommt aus msg.objectId (S7-Zuordnung); Keys/URL aus rest-config.json,
// optional je ObjectID überschrieben über rest.objects[objectId].
const cfg = flow.get("cfg");
if (!cfg) { node.warn("Keine Konfiguration geladen – Upload verworfen"); return null; }
const r = cfg.rest;
const samples = msg.samples || [];
if (!samples.length) return null;
const objectId = msg.objectId || r.objectId;
if (!objectId) { node.error("Upload ohne objectId verworfen", msg); return null; }
const o = (r.objects && r.objects[objectId]) || {};
const url = o.url || r.url, publicKey = o.publicKey || r.publicKey, privateKey = o.privateKey || r.privateKey;

function formatDt(ms) {
    const d = new Date(ms), p = n => String(n).padStart(2, "0");
    if (r.dtFormat === "utc")
        return d.getUTCFullYear() + "-" + p(d.getUTCMonth() + 1) + "-" + p(d.getUTCDate()) + " " + p(d.getUTCHours()) + ":" + p(d.getUTCMinutes()) + ":" + p(d.getUTCSeconds());
    return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate()) + " " + p(d.getHours()) + ":" + p(d.getMinutes()) + ":" + p(d.getSeconds());
}
const data = {};
for (const s of samples) (data[s.dp] = data[s.dp] || []).push({ dt: formatDt(s.ts), value: s.value });

const q = { id: objectId, method: r.method, public_key: publicKey, private_key: privateKey,
    ts: (Date.now() / 1000).toString(), nonce: crypto.randomUUID(), compressed: "" };
// Hash: Werte aller Parameter in alphabetischer Schlüsselreihenfolge aneinanderhängen, SHA-256
q.hash = crypto.createHash("sha256").update(Object.keys(q).sort().map(k => q[k]).join(""), "utf8").digest("hex");
delete q.private_key; delete q.method;   // dürfen nicht mitgesendet werden
const qs = Object.keys(q).map(k => encodeURIComponent(k) + "=" + encodeURIComponent(q[k])).join("&");
const base = url.endsWith("/") ? url : url + "/";

msg.objectId = objectId;
msg.url = base + r.method + "?" + qs;
msg.method = "POST";
msg.headers = { "Content-Type": "application/json" };
msg.requestTimeout = Number(r.timeoutMs) || 10000;
msg.payload = data;
msg.sampleCount = samples.length;
node.status({ fill: "blue", shape: "dot", text: (msg.kind === "resend" ? "nachsenden " : "senden ") + samples.length + " Werte -> " + objectId.slice(-6) });
return msg;
'''

FN_EVAL = r'''
// Wertet die Antwort des REST-Servers aus.
// Ausgang 1: Puffern (Live-Batch fehlgeschlagen)   Ausgang 2: Nachsenden anstoßen   Ausgang 3: Log
const code = msg.statusCode;
const ok = typeof code === "number" && code >= 200 && code < 300;
let body = msg.payload;
if (typeof body === "string") { try { body = JSON.parse(body); } catch (e) { body = body.slice(0, 300); } }
const info = { kind: msg.kind, objectId: msg.objectId, samples: msg.sampleCount, statusCode: code, at: new Date().toISOString(), response: body };
const st = flow.get("status") || {}; st.rest = st.rest || {};
if (ok) {
    flow.set("restOnline", true);
    st.rest = Object.assign(st.rest, { online: true, lastSuccess: info.at, lastObjectId: msg.objectId, lastResponse: body, sentTotal: (st.rest.sentTotal || 0) + msg.sampleCount });
    if (msg.kind === "resend") {
        st.rest.resentTotal = (st.rest.resentTotal || 0) + msg.sampleCount;
        flow.set("bufferCursor", msg.cursorEnd, "file");
        st.buffer = Object.assign(st.buffer || {}, { cursor: msg.cursorEnd, lastResend: info.at });
    }
    flow.set("status", st);
    node.status({ fill: "green", shape: "dot", text: "OK " + code + " (" + msg.sampleCount + " Werte" + (msg.kind === "resend" ? ", nachgesendet" : "") + ")" });
    // Nach einem Nachsende-Chunk sofort den nächsten holen; nach Live-Erfolg prüfen, ob Rückstand wartet
    const trigger = msg.kind === "resend" ? { topic: "next" } : (flow.get("bufferPending", "file") ? { topic: "check", reason: "live-ok" } : null);
    return [null, trigger, { topic: "log", payload: info }];
}
flow.set("restOnline", false);
st.rest = Object.assign(st.rest, { online: false, lastError: info.at, lastErrorCode: code, lastResponse: body, failedTotal: (st.rest.failedTotal || 0) + 1 });
flow.set("status", st);
node.status({ fill: "red", shape: "ring", text: "Fehler " + code });
if (msg.kind === "resend") {           // Nachsenden abbrechen, Chunk bleibt im Puffer (Cursor nicht bewegt)
    flow.set("resendActive", null);
    return [null, null, { topic: "log", payload: info }];
}
return [{ topic: "buffer", objectId: msg.objectId, samples: msg.samples, reason: String(code) }, null, { topic: "log", payload: info }];
'''

FN_BUFFER = r'''
// Schreibt einen fehlgeschlagenen Live-Batch in die InfluxDB (measurement rest_buffer).
// Jeder Batch gehört zu genau einer objectId (Tag "obj") und bekommt eine fortlaufende Sequenznummer (Tag "seq").
const cfg = flow.get("cfg"); const r = (cfg && cfg.rest) || {};
const samples = msg.samples || [];
if (!samples.length) return null;
const seq = (flow.get("bufferSeq", "file") || 0) + 1;
flow.set("bufferSeq", seq, "file");
flow.set("bufferPending", true, "file");
const seqTag = String(seq).padStart(12, "0");
const points = samples.map(s => ({ measurement: r.bufferMeasurement || "rest_buffer", tags: { dp: s.dp, seq: seqTag, obj: String(msg.objectId) }, fields: { value: Number(s.value) }, timestamp: s.ts }));
const st = flow.get("status") || {};
st.buffer = Object.assign(st.buffer || {}, { pending: true, lastWrite: new Date().toISOString(), lastSeq: seq, lastObjectId: msg.objectId, bufferedTotal: ((st.buffer && st.buffer.bufferedTotal) || 0) + points.length, cursor: flow.get("bufferCursor", "file") });
flow.set("status", st);
node.status({ fill: "yellow", shape: "dot", text: points.length + " Werte gepuffert (seq " + seq + ", " + String(msg.objectId).slice(-6) + ")" });
return { topic: "bufferwrite", seq, payload: points };
'''

FN_RESEND_START = r'''
// Startet bzw. setzt das Nachsenden fort: fragt den nächsten Chunk ungesendeter Batches aus der InfluxDB ab.
const cfg = flow.get("cfg"); if (!cfg) return null;
const r = cfg.rest;
if (!flow.get("bufferPending", "file")) { node.status({ fill: "grey", shape: "ring", text: "kein Rückstand" }); return null; }
const active = flow.get("resendActive");
if (msg.topic !== "next" && active && Date.now() - active < 120000) return null;      // läuft bereits
if (msg.topic === "check") {
    const last = context.get("lastAttempt") || 0;
    if (Date.now() - last < Number(r.resendCheckIntervalMs)) return null;                // Probe-Intervall einhalten
}
context.set("lastAttempt", Date.now());
flow.set("resendActive", Date.now());
const cursor = Number(flow.get("bufferCursor", "file") || 0);
// Chunk-Größe: mindestens 2 komplette Batches, damit ein angeschnittener Batch sicher zurückgestellt werden kann
const maxVars = Math.max(1, ...cfg.plcs.map(p => p.variables.length));
const minCycle = Math.max(50, Math.min(...cfg.plcs.map(p => Number(p.cycleTimeMs) || 1000)));
const perBatch = maxVars * cfg.plcs.length * Math.max(1, Math.ceil(Number(r.uploadIntervalMs) / minCycle)) + 10;
const limit = Math.max(Number(r.resendChunkSize) || 500, 2 * perBatch);
msg.query = 'from(bucket: "' + r.bufferBucket + '") |> range(start: -' + r.bufferLookback + ')'
    + ' |> filter(fn: (r) => r._measurement == "' + r.bufferMeasurement + '" and r._field == "value" and r.seq > "' + String(cursor).padStart(12, "0") + '")'
    + ' |> group() |> sort(columns: ["seq", "_time"]) |> limit(n: ' + limit + ')';
msg.queryLimit = limit;
msg.topic = "resendquery";
delete msg.payload;
node.status({ fill: "blue", shape: "dot", text: "suche Rückstand ab seq " + cursor });
return msg;
'''

FN_RESEND_BATCH = r'''
// Baut aus dem InfluxDB-Ergebnis den Nachsende-Batch: lückenlos aufeinanderfolgende Sequenznummern
// derselben objectId; ein angeschnittener letzter Batch (Chunk voll) wird zurückgestellt.
const rows = Array.isArray(msg.payload) ? msg.payload : [];
const cursor = Number(flow.get("bufferCursor", "file") || 0);
const failed = flow.get("bufferFailedSeqs", "file") || [];
const st = flow.get("status") || {};
if (!rows.length) {
    flow.set("bufferPending", false, "file");
    flow.set("resendActive", null);
    st.buffer = Object.assign(st.buffer || {}, { pending: false, cursor, checkedAt: new Date().toISOString() });
    flow.set("status", st);
    node.status({ fill: "green", shape: "ring", text: "Puffer leer (seq " + cursor + ")" });
    return null;
}
const bySeq = {};
for (const row of rows) { const s = Number(row.seq); (bySeq[s] = bySeq[s] || []).push(row); }
let seqs = Object.keys(bySeq).map(Number).sort((a, b) => a - b);
if (rows.length >= msg.queryLimit && seqs.length > 1) seqs.pop();   // letzter Batch evtl. unvollständig
let expected = cursor + 1; const take = [];
for (const s of seqs) {
    while (expected < s && failed.includes(expected)) expected++;
    if (s !== expected) break;                                       // Lücke: Batch fehlt (noch) in der DB
    take.push(s); expected = s + 1;
}
if (!take.length) {
    // Lücke direkt hinter dem Cursor: kurz warten (Schreibvorgang evtl. noch offen), danach überspringen
    const gap = context.get("gap");
    if (!gap || gap.seq !== expected) context.set("gap", { seq: expected, since: Date.now() });
    else if (Date.now() - gap.since > 60000) {
        failed.push(expected); flow.set("bufferFailedSeqs", failed, "file"); context.set("gap", null);
        node.warn("Puffer-Batch seq " + expected + " fehlt dauerhaft in der InfluxDB und wird übersprungen");
    }
    flow.set("resendActive", null);
    node.status({ fill: "yellow", shape: "ring", text: "warte auf seq " + expected });
    return null;
}
context.set("gap", null);
// Nur den Lauf aufeinanderfolgender Batches mit derselben objectId senden (ein Request = eine objectId)
const cfg = flow.get("cfg");
const objOf = s => (bySeq[s][0].obj || (cfg && cfg.rest.objectId) || "");
const objectId = objOf(take[0]);
const run = []; for (const s of take) { if (objOf(s) !== objectId) break; run.push(s); }
const samples = [];
for (const s of run) for (const row of bySeq[s]) samples.push({ dp: row.dp, value: Number(row._value), ts: Date.parse(row._time) });
const cursorEnd = run[run.length - 1];
flow.set("bufferFailedSeqs", failed.filter(f => f > cursorEnd), "file");
node.status({ fill: "blue", shape: "dot", text: samples.length + " Werte, seq " + run[0] + "-" + cursorEnd + " -> " + String(objectId).slice(-6) });
return { topic: "upload", kind: "resend", objectId, samples, cursorEnd };
'''

FN_INFLUX_ERR = r'''
// Fehler der InfluxDB-Nodes (Schreiben/Lesen) protokollieren und Zustände zurücksetzen.
const err = (msg.error && msg.error.message) || String(msg.error);
const st = flow.get("status") || {}; st.influx = { lastError: err, at: new Date().toISOString(), topic: msg.topic };
if (msg.topic === "bufferwrite" && msg.seq) {
    // Batch konnte nicht gepuffert werden -> Daten verloren; Sequenz als fehlend markieren, damit das Nachsenden nicht wartet
    const failed = flow.get("bufferFailedSeqs", "file") || []; failed.push(msg.seq); flow.set("bufferFailedSeqs", failed, "file");
    st.influx.lostSamples = ((st.influx && st.influx.lostSamples) || 0) + (Array.isArray(msg.payload) ? msg.payload.length : 0);
}
if (msg.topic === "resendquery") flow.set("resendActive", null);
flow.set("status", st);
node.status({ fill: "red", shape: "ring", text: "InfluxDB: " + err.slice(0, 40) });
node.error("InfluxDB-Fehler (" + msg.topic + "): " + err, msg);
return { topic: "log", payload: { influxError: err, topic: msg.topic, seq: msg.seq, at: st.influx.at } };
'''

FN_STATUS = r'''
const st = flow.get("status") || {};
st.runtime = { restOnline: flow.get("restOnline"), bufferPending: flow.get("bufferPending", "file"), bufferCursor: flow.get("bufferCursor", "file"),
    bufferSeq: flow.get("bufferSeq", "file"), bufferFailedSeqs: flow.get("bufferFailedSeqs", "file"), resendActive: flow.get("resendActive"), at: new Date().toISOString() };
flow.set("status", st);
return { topic: "status", payload: st };
'''


FN_EVENTS = r"""
// Ereignisprotokoll: letzte 60 Ereignisse im Flow-Context "events" (für Status/Diagnose ohne Debug-Sidebar).
const ev = flow.get("events") || [];
const p = msg.payload;
ev.push({ at: new Date().toISOString(), topic: msg.topic, kind: msg.kind, statusCode: msg.statusCode, sampleCount: msg.sampleCount, seq: msg.seq,
    info: (p && typeof p === "object") ? JSON.stringify(p).slice(0, 300) : String(p).slice(0, 300) });
while (ev.length > 60) ev.shift();
flow.set("events", ev);
return msg;
"""

FN_REGISTER = r"""
// Wartung: Registrierung des Function-Moduls @st-one-io/nodes7 prüfen (topic "check") oder reparieren (topic "repair").
// Der S7-Poller lädt die Bibliothek aus dem Node-RED-userDir. Dafür muss gelten:
//   1) userDir/node_modules/@st-one-io/nodes7  ->  Symlink auf ../node-red-contrib-s7/node_modules/@st-one-io/nodes7
//   2) userDir/package.json enthält dependencies["@st-one-io/nodes7"]
// Nach einer Reparatur den Flow einmal neu deployen, damit der S7-Poller die Bibliothek neu lädt.
// Falls Node-RED wegen fehlender Registrierung gar keinen Flow startet: S7-Poller-Node deaktivieren, deployen,
// "Registrierung reparieren" auslösen, S7-Poller wieder aktivieren, deployen.
const repair = msg.topic === "repair";
const U = (env.get("SNAP_DATA") || "/var/snap/ctrlx-node-red/current") + "/solutions/activeConfiguration/node-RED";
const MODULE = "@st-one-io/nodes7";
const LINK_DIR = U + "/node_modules/@st-one-io";
const LINK = LINK_DIR + "/nodes7";
const LINK_TARGET = "../node-red-contrib-s7/node_modules/" + MODULE;          // relativ, damit Snap-Revisionen egal sind
const REAL = U + "/node_modules/node-red-contrib-s7/node_modules/" + MODULE;  // Original innerhalb von node-red-contrib-s7
const PKG = U + "/package.json";
const PKG_SPEC = "file:node_modules/node-red-contrib-s7/node_modules/" + MODULE;
const r = { mode: repair ? "repair" : "check", at: new Date().toISOString(), userDir: U, problems: [], actions: [] };

// 0) Original vorhanden?
try { r.libraryVersion = JSON.parse(fs.readFileSync(REAL + "/package.json", "utf8")).version; }
catch (e) { r.problems.push("Bibliothek nicht gefunden unter " + REAL + " (node-red-contrib-s7 installiert?)"); }

// 1) Symlink prüfen / anlegen
let linkOk = false;
try {
    const st = fs.lstatSync(LINK);
    if (st.isSymbolicLink()) {
        const target = fs.readlinkSync(LINK);
        try { fs.statSync(LINK); linkOk = true; r.symlink = "ok -> " + target; }
        catch (e) { r.problems.push("Symlink zeigt ins Leere (" + target + ")"); }
    } else r.problems.push(LINK + " existiert, ist aber kein Symlink");
} catch (e) { r.problems.push("Symlink fehlt: " + LINK); }
if (!linkOk && repair && r.libraryVersion) {
    try {
        fs.mkdirSync(LINK_DIR, { recursive: true });
        try { fs.rmSync(LINK, { recursive: true, force: true }); } catch (e) { /* nichts da */ }
        fs.symlinkSync(LINK_TARGET, LINK);
        fs.statSync(LINK);
        linkOk = true; r.symlink = "neu angelegt -> " + LINK_TARGET; r.actions.push("Symlink angelegt");
    } catch (e) { r.problems.push("Symlink anlegen fehlgeschlagen: " + e.message); }
}

// 2) package.json prüfen / ergänzen
let pkgOk = false;
try {
    const pkg = JSON.parse(fs.readFileSync(PKG, "utf8"));
    pkg.dependencies = pkg.dependencies || {};
    if (pkg.dependencies[MODULE]) { pkgOk = true; r.packageJson = "ok: " + pkg.dependencies[MODULE]; }
    else if (repair) {
        const bak = PKG + ".bak-" + new Date().toISOString().slice(0, 19).replace(/[:T]/g, "-");
        fs.copyFileSync(PKG, bak);
        pkg.dependencies[MODULE] = PKG_SPEC;
        fs.writeFileSync(PKG, JSON.stringify(pkg, null, 4) + "\n");
        pkgOk = true; r.packageJson = "ergänzt: " + PKG_SPEC; r.actions.push("package.json ergänzt (Backup " + bak + ")");
    } else r.problems.push("package.json: Eintrag dependencies[\"" + MODULE + "\"] fehlt");
} catch (e) { r.problems.push("package.json nicht lesbar/schreibbar: " + e.message); }

r.ok = linkOk && pkgOk && !!r.libraryVersion;
if (r.actions.length) r.hint = "Flow neu deployen, damit der S7-Poller die Bibliothek lädt.";
const st = flow.get("status") || {}; st.registration = r; flow.set("status", st);
node.status(r.ok ? { fill: "green", shape: "dot", text: "nodes7 " + r.libraryVersion + " registriert" + (r.actions.length ? " (repariert)" : "") }
                 : { fill: "red", shape: "ring", text: r.problems[0] });
if (!r.ok) node.warn("nodes7-Registrierung: " + r.problems.join(" | "));
return { topic: "log", payload: r };
"""

COMMENT_INFO = """S7 -> REST (REST Data-Receiver) mit InfluxDB-Puffer

Konfiguration (werden manuell in die App-Daten kopiert, Solutions > appdata > node-RED > config):
  config/s7-config.json    Liste der S7 (plcs[]): Verbindung, objectId, Variablen, Polling-Takt, simulate, enabled
  config/rest-config.json  REST-Server (URL, Keys, optional je objectId), Upload-Intervall, Puffer-Parameter
Änderungen an den Dateien werden automatisch erkannt (watch) und neu geladen.

Ablauf:
  S7-Poller/Simulator (jede S7 mit ihrer objectId) -> Sammeln je objectId (Upload-Intervall) -> REST-Request vorbereiten
  -> http request -> Antwort auswerten   (ein Request = eine objectId)
  Fehler  -> Batch in InfluxDB puffern (measurement rest_buffer, Tags seq = Batch-Sequenznummer, obj = objectId)
  Erfolg  -> falls Rückstand: Nachsenden starten -> InfluxDB lesen -> Nachsende-Batch -> REST ... (Schleife bis Puffer leer)
Zustände (flow-Context, Store "file"): bufferSeq, bufferCursor, bufferPending, bufferFailedSeqs
Übersicht: Inject "Status anzeigen" -> Debug "Status"

S7-Poller braucht das Function-Modul @st-one-io/nodes7 (siehe README im config-Ordner).
Wartung: Inject "Registrierung prüfen (Start)" meldet den Zustand, "Registrierung reparieren" legt Symlink
und package.json-Eintrag neu an (danach Flow neu deployen)."""

def fn(id_, name, x, y, wires, func, libs=(), outputs=1, finalize="", disabled=False):
    n = {"id": id_, "type": "function", "z": TAB, "name": name, "func": func.strip("\n"), "outputs": outputs, "timeout": 0, "noerr": 0,
         "initialize": "", "finalize": finalize.strip("\n"), "libs": [{"var": v, "module": m} for v, m in libs], "x": x, "y": y, "wires": wires}
    if disabled: n["d"] = True
    return n

def inject(id_, name, x, y, wires, topic="", repeat="", once=False, once_delay=0.1):
    return {"id": id_, "type": "inject", "z": TAB, "name": name, "props": [{"p": "topic", "vt": "str"}], "repeat": str(repeat), "crontab": "", "once": once,
            "onceDelay": once_delay, "topic": topic, "x": x, "y": y, "wires": wires}

def debug(id_, name, x, y, active=True, complete="payload"):
    return {"id": id_, "type": "debug", "z": TAB, "name": name, "active": active, "tosidebar": True, "console": False, "tostatus": False,
            "complete": complete, "targetType": "msg" if complete != "true" else "full", "statusVal": "", "statusType": "auto", "x": x, "y": y, "wires": []}

nodes = [
    {"id": "f2cmtinfo0000001", "type": "comment", "z": TAB, "name": "S7 -> REST mit InfluxDB-Puffer (Beschreibung)", "info": COMMENT_INFO, "x": 250, "y": 40, "wires": []},
    # --- Konfiguration
    inject("f2injstart000001", "Start / Konfig laden", 150, 100, [["f2cfgload0000001"]], topic="load", once=True, once_delay=1),
    inject("f2injreload00001", "Konfig neu laden", 150, 140, [["f2cfgload0000001"]], topic="load"),
    {"id": "f2watchcfg000001", "type": "watch", "z": TAB, "name": "config-Ordner überwachen", "files": CONFIG_DIR, "recursive": "", "x": 150, "y": 180, "wires": [["f2trigdeb0000001"]]},
    {"id": "f2trigdeb0000001", "type": "trigger", "z": TAB, "name": "2 s entprellen", "op1": "", "op2": "", "op1type": "nul", "op2type": "payl", "duration": "2", "extend": True,
     "overrideDelay": False, "units": "s", "reset": "", "bytopic": "all", "topic": "topic", "outputs": 1, "x": 370, "y": 180, "wires": [["f2cfgload0000001"]]},
    fn("f2cfgload0000001", "Konfig laden", 560, 120, [["f2s7poll00000001", "f2s7sim000000001", "f2collect0000001"]], FN_LOAD, libs=[("fs", "fs")]),
    # --- Datenquelle
    fn("f2s7poll00000001", "S7-Poller (nodes7, mehrere S7)", 820, 80, [["f2collect0000001"]], FN_S7, libs=[("nodes7", S7_LIB_MODULE)], finalize=FN_S7_STOP, disabled=S7_NODE_DISABLED),
    fn("f2s7sim000000001", "S7-Simulator", 820, 140, [["f2collect0000001"]], FN_SIM, finalize=FN_SIM_STOP),
    # --- Sammeln und Senden
    fn("f2collect0000001", "Sammeln & Upload-Takt", 820, 240, [["f2prepare0000001"]], FN_COLLECT, finalize=FN_COLLECT_STOP),
    inject("f2injflush000001", "Jetzt hochladen", 560, 280, [["f2collect0000001"]], topic="flush"),
    fn("f2prepare0000001", "REST-Request vorbereiten", 1090, 240, [["f2httpreq0000001"]], FN_PREPARE, libs=[("crypto", "crypto")]),
    {"id": "f2httpreq0000001", "type": "http request", "z": TAB, "name": "REST-Server", "method": "use", "ret": "txt", "paytoqs": "ignore", "url": "", "tls": "", "persist": False,
     "proxy": "", "insecureHTTPParser": False, "authType": "", "senderr": False, "headers": [], "x": 1310, "y": 240, "wires": [["f2eval0000000001"]]},
    fn("f2eval0000000001", "Antwort auswerten", 1520, 240, [["f2buffer00000001"], ["f2resendst000001"], ["f2events00000001"]], FN_EVAL, outputs=3),
    fn("f2events00000001", "Ereignis protokollieren", 1760, 160, [["f2dbglog00000001"]], FN_EVENTS),
    debug("f2dbglog00000001", "Log", 1980, 160),
    # --- Puffern
    fn("f2buffer00000001", "In InfluxDB puffern", 1520, 340, [["f2influxout00001"]], FN_BUFFER),
    {"id": "f2influxout00001", "type": "influxdb batch", "z": TAB, "influxdb": INFLUX_CFG, "name": "InfluxDB schreiben", "precision": "", "retentionPolicy": "", "precisionV18FluxV20": "ms",
     "retentionPolicyV18Flux": "", "org": "iot", "bucket": "iot", "x": 1770, "y": 340, "wires": []},
    # --- Nachsenden
    inject("f2injcheck000001", "Nachsende-Check (10 s)", 560, 440, [["f2resendst000001"]], topic="check", repeat=10),
    inject("f2injresend00001", "Nachsenden jetzt", 560, 480, [["f2resendst000001"]], topic="manual"),
    fn("f2resendst000001", "Nachsenden starten", 820, 440, [["f2influxin000001"]], FN_RESEND_START),
    {"id": "f2influxin000001", "type": "influxdb in", "z": TAB, "influxdb": INFLUX_CFG, "name": "InfluxDB lesen", "query": "", "rawOutput": False, "precision": "", "retentionPolicy": "",
     "org": "iot", "x": 1080, "y": 440, "wires": [["f2resendbt000001"]]},
    fn("f2resendbt000001", "Nachsende-Batch bilden", 1320, 440, [["f2prepare0000001"]], FN_RESEND_BATCH),
    # --- Fehler und Status
    {"id": "f2catchinf000001", "type": "catch", "z": TAB, "name": "InfluxDB-Fehler", "scope": ["f2influxout00001", "f2influxin000001"], "uncaught": False, "x": 570, "y": 560, "wires": [["f2influxerr00001"]]},
    fn("f2influxerr00001", "InfluxDB-Fehler behandeln", 840, 560, [["f2events00000001"]], FN_INFLUX_ERR),
    inject("f2injstatus00001", "Status anzeigen", 560, 640, [["f2status00000001"]], topic="status"),
    # --- Wartung: Modul-Registrierung
    inject("f2injregchk00001", "Registrierung prüfen (Start)", 570, 720, [["f2register000001"]], topic="check", once=True, once_delay=2),
    inject("f2injregfix00001", "Registrierung reparieren", 570, 760, [["f2register000001"]], topic="repair"),
    fn("f2register000001", "nodes7-Registrierung prüfen/reparieren", 880, 740, [["f2events00000001"]], FN_REGISTER, libs=[("fs", "fs")]),
    fn("f2status00000001", "Status sammeln", 820, 640, [["f2dbgstatus00001"]], FN_STATUS),
    debug("f2dbgstatus00001", "Status", 1080, 640),
]
json.dump(nodes, open("flow2_nodes.json", "w"), indent=1, ensure_ascii=False)
print("nodes:", len(nodes))
