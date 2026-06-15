# AxisInterface (CXA_MotionInterface) — ST Grundmuster

Verified on ctrlX WORKS 4.6.1, CXA_MotionInterface 4.6.2.0 — 2026-06-15.

## Bibliothek

`CXA_MotionInterface` (Placeholder: `CXA_MOTION_INTERFACE`, Company: Bosch Rexroth AG)

Über Engineering REST API hinzufügen:
```json
POST /library-repositories/{repo}
{ "name": "CXA_MotionInterface", "version": "4.6.2.0", "company": "Bosch Rexroth AG" }
```

---

## Voraussetzungen

1. **Motion App in Running mode** — `recipes/motion/motion-opstate-switch.md`
2. **Axis vorhanden** — Achsname in `GVL.AxisName` muss mit der Motion-Konfiguration übereinstimmen
3. **Bibliothek hinzugefügt** — `CXA_MotionInterface` im Library Manager des Projekts

### Bibliothek-Repository ermitteln und hinzufügen

```powershell
$engBase = "http://localhost:9002/plc/engineering/api/v2"
# Verfügbare Repos auflisten
Invoke-RestMethod "$engBase/library-repositories" | ConvertTo-Json -Depth 3
# Typischer Repo-Name: "System"
Invoke-RestMethod "$engBase/library-repositories/System" -Method POST -ContentType "application/json" -Body (@{
    name    = "CXA_MotionInterface"
    version = "4.6.2.0"
    company = "Bosch Rexroth AG"
} | ConvertTo-Json)
```

> Auf virtueller Steuerung ohne Motion-App schlägt `MB_AxisInit` zur Laufzeit fehl — kein PLC-Fehler, solange `gEnable := FALSE` bleibt.

---

## Achsreferenz (GVL)

```iecst
VAR_GLOBAL
    gAxisRef : MB_AXISIF_REF := (AxisName := 'Axis_1', AxisNo := 0);
END_VAR
```

- `AxisName` muss dem Namen in der Motion-App entsprechen
- `AxisNo` = Index (0-basiert)

---

## FB-Deklaration (PLC_PRG)

```iecst
VAR
    fbInit        : MB_AxisInit;
    fbAxisIf      : MB_AxisInterfaceBase;
    fbAdminCtrl   : MB_AXIS_ADMINISTRATION;
    fbPosCtrl     : MB_AXIS_POSITIONING;
    fbDynValues   : MB_AXIS_DYN_VALUES;
    fbSyncMode    : MB_AXIS_SYNCHRONISATION;
    fbAdminStatus : MB_AXIS_ADMIN_STATUS;
    fbDataStatus  : MB_AXIS_DATA;
    fbDiagStatus  : MB_AXIS_DIAGNOSIS;
END_VAR
```

---

## Zyklischer Aufruf (Pflicht-Reihenfolge)

```iecst
// 1. Init (einmalig, Execute := TRUE bis Done)
fbInit(
    Execute   := TRUE,
    AxisName  := gAxisRef.AxisName,
    AxisIndex := UINT#0,
    AdminCtrl := fbAdminCtrl,
    SyncMode  := fbSyncMode,
    AdminStatus := fbAdminStatus,
    DataStatus  := fbDataStatus,
    DiagStatus  := fbDiagStatus
);

// 2. Interface-Base (zyklisch, IMMER zuerst aufrufen)
fbAxisIf(
    AxisRef      := gAxisRef,
    AdminCtrl    := fbAdminCtrl,
    StopModeCtrl := fbSyncMode,   // Pflichtfeld
    PosModeCtrl  := fbPosCtrl,
    SyncModeCtrl := fbSyncMode,
    AdminStatus  := fbAdminStatus,
    DataStatus   := fbDataStatus,
    DiagStatus   := fbDiagStatus
);
```

---

## Einschalten (ModeAH = unter Moment, Stillstand)

```iecst
fbAdminCtrl.mTriggerMoveCmd(MB_AXIS_MODE.ModeAH, FALSE, DWORD#0);
```

Warten bis bereit:
```iecst
bReady := fbAdminStatus._OpModeAck = MB_AXIS_MODE.ModeAH;
```

---

## Absolute Positionierung

```iecst
// Ziel setzen
fbPosCtrl.TargetPosition  := 50.0;   // mm
fbDynValues.Velocity      := 3000.0; // mm/min
fbDynValues.Acceleration  := 2.0;    // m/s²
fbDynValues.Deceleration  := 2.0;    // m/s²

// Bewegung auslösen
fbAdminCtrl.mTriggerMoveCmd(MB_AXIS_MODE.ModePosAbs, FALSE, DWORD#0);
```

Warten bis Ziel erreicht:
```iecst
bDone := fbAdminStatus._OpModeAck = MB_AXIS_MODE.ModeAH; // kehrt nach ModeAH zurück
```

---

## Ausschalten (ModeAB = Moment weg)

```iecst
fbAdminCtrl.mTriggerMoveCmd(MB_AXIS_MODE.ModeAB, FALSE, DWORD#0);
```

---

## Wichtige Modi (MB_AXIS_MODE)

| Wert | Bedeutung |
|------|-----------|
| `ModeAB` | Antrieb aus (kein Moment) |
| `ModeAH` | Eingeschaltet, Stillstand |
| `ModePosAbs` | Absolute Positionierung |
| `ModePosRel` | Relative Positionierung |
| `ModeVel` | Geschwindigkeitsbetrieb |

---

## Istwerte und Diagnose

```iecst
rActPos  := fbDataStatus.ActValues.Position;  // Aktuelle Position [mm]
bError   := fbDiagStatus.Error;
dwErrID  := fbDiagStatus.ErrorID;             // Nur implizite Zuweisung (kein DWORD()-Cast)
```

---

## Fehlerbehebung

```iecst
// Fehler quittieren → kurz ModeAB, dann ModeAH
IF gReset THEN
    fbAdminCtrl.mTriggerMoveCmd(MB_AXIS_MODE.ModeAB, FALSE, DWORD#0);
    gReset := FALSE;
END_IF
```

---

## Wichtige Eigenheiten

- `mTriggerMoveCmd` nur mit **positional arguments** — benannte Parameter (`:=`) kompilieren nicht
- `DWORD(x)` Cast-Syntax ungültig in IEC 61131-3 → direkte Zuweisung oder `DWORD#0`
- `MB_AxisInterfaceBase` muss **jeden Zyklus** aufgerufen werden, auch wenn keine Bewegung
- `MB_AxisInit` läuft einmalig bis `Done = TRUE`, dann `Execute := FALSE`
- Auf virtueller Steuerung ohne Motion-App: `MB_AxisInit` schlägt fehl (kein `Axis_1`)
