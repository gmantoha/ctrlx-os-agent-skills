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
*)

PROGRAM UsbMountControl
VAR
    xDoMount      : BOOL;
    xDoUnmount    : BOOL;
    sUuid         : STRING := '3C20-2F7A';
    sDevice       : STRING := 'sdb1';

    xBusy         : BOOL;
    xDone         : BOOL;
    xError        : BOOL;
    uiErrorCode   : UINT;

    fbDlCreate    : DL_Call;
    sPayload      : STRING(255);
    xMountActive  : BOOL;
    xUnmountActive: BOOL;
    xRisingMount  : BOOL;
    xRisingUnmount: BOOL;
    xOldMount     : BOOL;
    xOldUnmount   : BOOL;
END_VAR

xRisingMount   := xDoMount   AND NOT xOldMount;
xRisingUnmount := xDoUnmount AND NOT xOldUnmount;
xOldMount      := xDoMount;
xOldUnmount    := xDoUnmount;

IF xRisingMount AND NOT xBusy THEN
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

IF xMountActive OR xUnmountActive THEN
    fbDlCreate(
        xExecute := TRUE,
        sNodePath :=
            SEL(xMountActive,
                'system/resources/tasks/storage/unmount',
                'system/resources/tasks/storage/mountDevice'),
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
