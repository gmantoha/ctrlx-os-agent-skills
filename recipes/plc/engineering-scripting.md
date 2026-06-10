# ctrlX PLC Engineering: Scripting API

Automate PLC project tasks (build, deploy, debug, variable access) via the
CODESYS Script Engine built into **ctrlX WORKS / ctrlX PLC Engineering**.

## Tool

```
"C:\Program Files\Bosch Rexroth\ctrlX WORKS\CODESYS\CODESYSScript.exe" script.py
```

The script engine is a Python interpreter embedded in ctrlX WORKS. Scripts run
in the same process as the IDE, so all CODESYS automation objects are available.

---

## 1. Open a Project and Build

```python
# Open project
proj = projects.open(r"C:\MyProject\MyProject.project")

# Find Application node
app = proj.find("Application", recursive=True)[0]

# Compile — errors appear in the CODESYS message window
result = app.build()
if result.has_errors:
    raise RuntimeError("Build failed")
```

---

## 2. Deploy to ctrlX (Download + Start)

The device connection (IP, credentials) must be configured in the project's
device object beforehand.

```python
# Login — OnlineChangeOption.Try = use online change if possible, else full download
online = app.device.login(OnlineChangeOption.Try, True)

# Download application to controller
online.download()

# Start PLC program
online.start()
```

To stop and disconnect cleanly:

```python
online.stop()
online.logout()
proj.close()
```

---

## 3. Online Change (code update without full stop)

```python
# Modify a POU's code in the open project
pou = proj.find("FB_MyBlock", recursive=True)[0]
pou.textual_code = "rOut := rIn * 1.5;"

# Build with online change
app.build()
online = app.device.login(OnlineChangeOption.Try, True)
online.download()   # applies as online change if compatible
```

---

## 4. Read and Write Variables at Runtime

```python
# Read a variable (use dot-notation: POU.Variable or GVL.Variable)
val = online.read_value("GVL.rSetpoint")
print(f"rSetpoint = {val}")

# Write a variable
online.write_value("GVL.rSetpoint", 42.5)

# Read a struct member
temp = online.read_value("PRG_Main.stData.rTemperature")
```

---

## 5. Breakpoints and Step Debugging

> Interactive single-step debugging requires the IDE. Via script, breakpoints
> can be set/cleared and execution resumed.

```python
# Set breakpoint at line 15 in FB_MyBlock
online.set_breakpoint("FB_MyBlock", 15)

# Resume execution after hitting a breakpoint
online.resume()

# List active breakpoints
for bp in online.breakpoints:
    print(bp)

# Clear a specific breakpoint
online.clear_breakpoint("FB_MyBlock", 15)
```

---

## 6. Create POUs Programmatically

```python
app = proj.find("Application", recursive=True)[0]

# Create a new Function Block
fb = app.create_pou("FB_NewBlock", PouType.FunctionBlock, "StructuredText")

# Write declaration and implementation
fb.textual_declaration = """\
VAR_INPUT
    rIn : REAL;
END_VAR
VAR_OUTPUT
    rOut : REAL;
END_VAR
"""
fb.textual_code = "rOut := rIn * 2.0;"

proj.save()
```

---

## 7. Headless CI/CD (Batch)

```bat
@echo off
set CSPY="C:\Program Files\Bosch Rexroth\ctrlX WORKS\CODESYS\CODESYSScript.exe"
%CSPY% build_and_deploy.py
if errorlevel 1 (echo BUILD FAILED & exit /b 1)
echo Build and deploy OK
```

---

## Capability Overview

| Task                          | Via Script |
|-------------------------------|------------|
| Build / compile               | ✅          |
| Download to PLC               | ✅          |
| Online Change                 | ✅          |
| Start / Stop                  | ✅          |
| Read / Write variables        | ✅          |
| Set / clear breakpoints       | ✅          |
| Create POUs / FBs             | ✅          |
| Interactive step debugging    | ❌ IDE only |

---

## References

- [CODESYS ScriptEngine Reference](https://help.codesys.com/webapp/_cds_python_generic;product=ScriptEngine;version=4.4.0.0)
- [ctrlX AUTOMATION Community](https://developer.community.boschrexroth.com/)
