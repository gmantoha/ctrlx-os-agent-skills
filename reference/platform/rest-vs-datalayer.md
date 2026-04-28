# REST Vs Data Layer

Use Data Layer when the caller runs on the same ctrlX device and the function is exposed there.

Use REST when:

- the caller is remote
- browser or script automation is needed
- an endpoint is published only as REST

Data Layer usually avoids HTTP, TLS, and token overhead for in-device flows.
