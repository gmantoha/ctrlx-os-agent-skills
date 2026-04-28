# Case: MSSQL as ctrlX Snap

## Use When

Use this case when investigating Microsoft SQL Server packaging as a strict ctrlX snap, especially failures caused by hardcoded write paths below `/`.

## Symptoms

- `sqlservr` fails to start under strict confinement.
- Error mentions `/.system` cannot be created.
- Access denied or permission denied from SQLPAL path creation.

## Key Finding

The failure is caused by hardcoded SQLPAL paths. Snap `layout:` bindings can redirect paths such as `/.system` and `/var/opt/mssql` into writable snap data locations while staying in strict confinement.

## Details

See `README.md` and the files under `investigation/`.
