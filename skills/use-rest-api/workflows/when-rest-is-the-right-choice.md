# When REST Is The Right Choice

REST is usually the right choice when:

- the caller is remote
- a browser or integration service initiates the request
- an external CI or diagnostic script drives the workflow
- there is no local Data Layer consumer path available

REST is usually the wrong first choice when a PLC or app on the same device can use Data Layer directly.
