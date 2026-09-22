# ctrlX 3D Viewer: model upload, Data Layer mapping, and UI verification

Use this recipe for a ctrlX 3D Viewer model that consumes Motion axis values.
The recipe is based on ctrlX OS 4.6.1 3D Viewer behavior verified on a virtual
ctrlX target.

## Routing rule

Prefer Data Layer operations for device data:

1. Browse the Motion subtree.
2. Read metadata for the selected node.
3. Read or subscribe to axis values.
4. Use the 3D Viewer REST API only for app-owned project files and project
   configuration, where no public 3D Viewer Data Layer node exists.

The Viewer uses the ctrlX REST facade for Data Layer access:

```text
GET /automation/api/v2/nodes/<node>?type=browse
GET /automation/api/v2/nodes/<node>?type=metadata
GET /automation/api/v2/nodes/<node>
POST /automation/api/v2/events
```

The 4.6.1 client also probes internal legacy routes such as
`/automation/api/v1.0/motion/axs` and `/automation/api/v1.0/motion/kin`.
Use the documented v2 node API for new integrations.

## Project upload and axis mapping

The app-owned project API accepts repeated `file` form fields:

```text
POST /3dviewer/api/v2/projects
Content-Type: multipart/form-data
file=<model.xml>
file=<link-1.stl>
file=<link-2.stl>
...
```

The XML file name becomes the project name. The project configuration is
stored separately:

```text
GET /3dviewer/api/v2/projects/<project>/configuration
PUT /3dviewer/api/v2/projects/<project>/configuration
```

A Data Layer axis mapping has this shape:

```json
{
  "ModelAxisName": "J1",
  "ConnectionType": "datalayerAxes",
  "DatalayerNode": "Axis_1",
  "DatalayerVariable": "",
  "ExpressionScript": "value"
}
```

Use the exact project name returned by:

```text
GET /3dviewer/api/v2/projects
```

Uploading through REST does not set the browser's local/session project
selection. After an API upload, open the Model Library or use:

```text
/3dviewer/<project>/commands
```

Opening only `/3dviewer/MachineView/commands` can show command panels without
the selected project.

## XML model requirements

The 4.6.1 parser accepts `translation` and `rotation` XML axes. For every
rotation axis, provide finite rollover-vector attributes even when rollover is
disabled:

```xml
<axis
  name="J1"
  type="rotation"
  x="0" y="1" z="0"
  rzx="0" rzy="1" rzz="0"
  rotationAxisRolloverEnabled="False"
  minvalue="-90"
  maxvalue="90"
  initial_value="0" />
```

If `rzx`, `rzy`, or `rzz` is missing, the Viewer constructs a vector from
`Number(undefined)`. Three.js then reports `BufferGeometry` `NaN` errors and
the viewport remains blank while the command panels are still visible.

Every `geometry/@geo` file must exist in the uploaded archive. A missing or
unreferenced file can produce an incomplete model even when the upload returns
HTTP 201.

## URDF and assembly imports

Do not assemble individual 3D-print parts with guessed translations when a
canonical URDF or assembly exists. For each URDF link:

- use one link mesh as one XML geometry;
- convert the joint `origin` XYZ/RPY to the preceding XML transform;
- use the URDF joint `axis` as the XML axis vector;
- preserve the URDF joint limits in the XML and Motion configuration;
- apply one root scale of `1000` if the URDF meshes are in meters and the
  Viewer model uses millimeters.

For BCN3D Moveo, the public URDF reference is:

```text
https://github.com/jesseweisberg/moveo_ros
```

The Moveo model uses five revolute joints. Its URDF link meshes and joint
origins are preferable to the original repository's individual print-part STL
files for a connected visualization.

## Verification

Do not stop at REST status codes. Verify all layers:

```text
GET /package-manager/api/v1/packages/rexroth-3dviewer
GET /3dviewer/api/v2/license
GET /3dviewer/api/v2/projects
GET /3dviewer/api/v2/projects/<project>/configuration
GET /automation/api/v2/nodes/motion/state/axs-list
GET /automation/api/v2/nodes/motion/axs/<axis>/state/values/ipo/pos
```

Then use a real browser and verify:

- the project route loads;
- a visible WebGL canvas contains geometry;
- the browser console has no `NaN`/`BufferGeometry` model errors;
- the command panels show the expected model axes;
- the model remains visible after a full reload.

An optional thumbnail request returning 404 does not by itself indicate a
model failure. Validate the project archive and rendered canvas separately.

## Motion health

The model can render while Motion is not operational. Read:

```text
GET /automation/api/v2/nodes/system/state/motion.core
GET /automation/api/v2/nodes/system/state/scheduler
GET /automation/api/v2/nodes/motion/state/opstate
GET /automation/api/v2/nodes/diagnosis/get/actual/list
```

If all axes are `OUTDATED` and boot reports:

```text
Can't reset axis (Result 0xf014000e); Abort BOOTING
```

stop retrying `Booting`. Hand the recovery to the Motion workflow; inspect
axis profiles, saved configuration, virtual-kernel state, and the active
diagnosis. A reset-all CREATE request is typed:

```json
{"type":"object","value":{}}
```

Reset-all is only a recovery attempt. Verify `system/state/motion.core` and
`motion/state/opstate` afterward. Do not restart or reboot a real target
without confirmation.

## Sources

- ctrlX OS 3D Viewer: https://www.boschrexroth.com/en/ca/c/ctrlx-os-3d-viewer/
- ctrlX Data Layer SDK: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/datalayer.html
- ctrlX REST API description: https://boschrexroth.github.io/rest-api-description/
- BCN3D Moveo source STL/CAD: https://github.com/BCN3D/BCN3D-Moveo
- BCN3D Moveo ROS URDF: https://github.com/jesseweisberg/moveo_ros
