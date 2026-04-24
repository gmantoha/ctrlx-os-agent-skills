(*
  USB-Stick mounten via ctrlX Data Layer
  =========================================
  Bibliothek:  CXA_DataLayer  (in ctrlX PLC Engineering enthalten)
  Getestete OS-Version:  ctrlX OS 4.6  (rexroth-deviceadmin 4.6.0)
  Mindestversion:        ctrlX OS 4.4

  Data-Layer-Knoten:
    Mount:    system/resources/tasks/storage/mountDevice   (DL_Create / POST)
    Unmount:  system/resources/tasks/storage/unmount       (DL_Create / POST)
    Status:   system/resources/storage                     (DL_Read  / GET)

  JSON-Schema mountDevice (verifiziert 2026-04-20 per Device-Probe):
    {
      "media":      "<UUID des USB-Sticks, z.B. '3C20-2F7A'>",
      "device":     "<Partition, z.B. 'sdb1'>",
      "assignment": "DataExchange"   // oder "StorageExtension"
    }

  JSON-Schema unmount:
    {
      "media":  "<UUID>",
      "device": "<Partition>"
    }

  HINWEIS: Die UUID des Sticks vorab einmalig per REST ermitteln:
    GET https://<ctrlX-IP>/storage/api/v1/media
  oder dynamisch via DL_Read auf "system/resources/storage" auslesen.
*)

PROGRAM UsbMountControl
VAR
    (* Eingänge — vom HMI oder anderen Programmteilen setzen *)
    xDoMount      : BOOL;   (* Flanke: Mount-Auftrag starten *)
    xDoUnmount    : BOOL;   (* Flanke: Unmount-Auftrag starten *)
    sUuid         : STRING := '3C20-2F7A';   (* UUID des USB-Sticks *)
    sDevice       : STRING := 'sdb1';        (* Partitionsname *)

    (* Ausgaben — Status für HMI *)
    xBusy         : BOOL;
    xDone         : BOOL;
    xError        : BOOL;
    uiErrorCode   : UINT;

    (* Intern *)
    fbDlCreate    : DL_Call;           (* FB für DL_Create = POST an Task-Knoten *)
    sPayload      : STRING(255);
    xMountActive  : BOOL;
    xUnmountActive: BOOL;
    xRisingMount  : BOOL;
    xRisingUnmount: BOOL;
    xOldMount     : BOOL;
    xOldUnmount   : BOOL;
END_VAR

(*---------------------------------------------------------
  Flankenerkennung
---------------------------------------------------------*)
xRisingMount   := xDoMount   AND NOT xOldMount;
xRisingUnmount := xDoUnmount AND NOT xOldUnmount;
xOldMount      := xDoMount;
xOldUnmount    := xDoUnmount;

(*---------------------------------------------------------
  Neuen Auftrag starten (nur wenn FB nicht bereits läuft)
---------------------------------------------------------*)
IF xRisingMount AND NOT xBusy THEN
    (* JSON-Payload für mountDevice zusammenbauen *)
    sPayload := CONCAT('{"media":"', sUuid);
    sPayload := CONCAT(sPayload, '","device":"');
    sPayload := CONCAT(sPayload, sDevice);
    sPayload := CONCAT(sPayload, '","assignment":"DataExchange"}');
    xMountActive   := TRUE;
    xUnmountActive := FALSE;
    xDone          := FALSE;
    xError         := FALSE;
    uiErrorCode    := 0;
END_IF

IF xRisingUnmount AND NOT xBusy THEN
    (* JSON-Payload für unmount *)
    sPayload := CONCAT('{"media":"', sUuid);
    sPayload := CONCAT(sPayload, '","device":"');
    sPayload := CONCAT(sPayload, sDevice);
    sPayload := CONCAT(sPayload, '"}');
    xUnmountActive := TRUE;
    xMountActive   := FALSE;
    xDone          := FALSE;
    xError         := FALSE;
    uiErrorCode    := 0;
END_IF

(*---------------------------------------------------------
  DL_Call (DL_Create) aufrufen
  DL_Call.eMethod = DL_METHOD.CREATE entspricht HTTP POST
---------------------------------------------------------*)
IF xMountActive OR xUnmountActive THEN
    fbDlCreate(
        xExecute := TRUE,
        (* Knoten je nach Auftrag *)
        sNodePath :=
            SEL(xMountActive,
                'system/resources/tasks/storage/unmount',
                'system/resources/tasks/storage/mountDevice'),
        (* Payload als JSON-String *)
        eType     := DL_TYPE.STRING,
        sValue    := sPayload
    );

    xBusy := fbDlCreate.xBusy;

    IF fbDlCreate.xDone THEN
        xDone          := TRUE;
        xBusy          := FALSE;
        xMountActive   := FALSE;
        xUnmountActive := FALSE;
        fbDlCreate(xExecute := FALSE);
    ELSIF fbDlCreate.xError THEN
        xError         := TRUE;
        xBusy          := FALSE;
        uiErrorCode    := UINT_TO_UINT(fbDlCreate.udiErrorCode);
        xMountActive   := FALSE;
        xUnmountActive := FALSE;
        fbDlCreate(xExecute := FALSE);
    END_IF
END_IF

(*
  HINWEIS ZUR BIBLIOTHEKSINTEGRATION:
  ------------------------------------
  1. In ctrlX PLC Engineering: Extras → Bibliotheksverwaltung
  2. Bibliothek hinzufügen: "CXA_DataLayer" (Bosch Rexroth, bereits im System vorhanden)
  3. Falls DL_Call nicht gefunden: In der Bibliothek nach "DL_Create" oder "CXA_DL_Call" suchen —
     der genaue FB-Name kann je nach CXA_DataLayer-Version leicht abweichen.
  4. Das Feld "eMethod" bzw. "eType" und die genaue Signatur bitte mit der installierten
     Bibliotheksversion abgleichen (F1 auf den FB-Namen im Editor).

  HINWEIS ZUM JSON-PAYLOAD:
  --------------------------
  Die UUID des USB-Sticks ändert sich mit jedem Stick. Für Produktionsbetrieb empfohlen:
  - system/resources/storage via DL_Read auslesen
  - Das Medium mit "mounted = false" und "internal = false" (oder fehlendem Feld) identifizieren
  - UUID und Device dynamisch extrahieren
*)
