# App Dev Lifecycle

Preferred loop:

1. Start with `workflows/build-app.md` and the closest official SDK sample.
2. Confirm target release, base, architecture, and required interfaces.
3. Build one target architecture in the App Build Environment when available.
4. Inspect the snap metadata, contents, and package manifest.
5. Deploy to a matching virtual ctrlX target when possible.
6. Inspect interfaces, logs, runtime state, and the UI/API entry point.
7. Adjust code or packaging, clean, rebuild, and retest.

Installing or updating a snap on a real ctrlX device requires explicit
confirmation.
