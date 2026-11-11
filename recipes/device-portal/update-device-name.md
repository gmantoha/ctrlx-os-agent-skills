# Update a Device Portal Display Name via the Public API

## Status and scope

**Available and verified on QA on 2026-11-11:** Licensing Bridge Service API
v1.2 exposes `PATCH /devices/{id}` to update the portal display name independently
of the serial number. A reversible QA test passed eight cases plus restoration.
This changes cloud metadata, not the CORE hostname or device configuration; use
the public Licensing API, not Data Layer or the cookie-authenticated WebUI BFF.
No direct CORE call is needed for this operation.

**PROD is published in the API documentation, but not verified by this test.**
Client authentication succeeded; a read-only PROD preflight was rejected by the
gateway with HTTP 401 `invalid subscription key`. Treat that as a subscription/
access blocker, not proof that the operation is absent. A valid token alone does
not establish access to a particular API product or environment.

This test does not establish WebUI editing/propagation, folder moves, filtering/
sorting, custom fields, or minimum Agent/OS versions. It does not imply acceptance
of other Device Portal features such as additive app-data restore.

## API contract

Set `DP_GATEWAY` to the official API gateway for the intended environment from
its developer portal. The service prefix is **`/licensing-service/v1.2`**, not
`/iot-device-services/v1`.

```http
PATCH {DP_GATEWAY}/licensing-service/v1.2/devices/{device-id}
Authorization: Bearer <access-token>
Ocp-Apim-Subscription-Key: <subscription-key>
Content-Type: application/json

{"name":"<machine-number>"}
```

Obtain the token using `grant_type=client_credentials`. Use the matching
environment's client credentials and a subscription valid for the Licensing API.
Keep credentials in the private workspace or environment and never print them.

- Success: **204 No Content**, empty body. Do not try to decode success as JSON.
- Read back with
  `GET {DP_GATEWAY}/licensing-service/v1.2/devices?accountId={account-id}&deviceId={device-id}`.
  The response contains an `items` array; require exactly the intended device
  and compare its `name` and `id` with the expected values.
- The device ID remains the serial number; it is not replaced by the new name.
- For a rename, send only `name`, not a complete device object.
- The documented optional `areaId` moves the device to a folder UUID or `root`.
  Omitted or empty-string fields are left unchanged. At least one supported
  non-empty string is required; this operation cannot clear values.
- The documented 404 (missing device) and 409 (duplicate device ID) responses
  were not exercised in this test.

## Safe verification sequence

Renaming is a persistent cloud-metadata change. Ask for explicit approval of the
environment, device, temporary name and restoration before sending PATCH.

1. Authenticate once and reuse the short-lived token. Read the intended device
   through the Licensing API; abort on access errors, a missing device, or
   ambiguous matches. Resolve a rejected subscription before attempting writes;
   do not substitute another account or environment silently.
2. Save its original `name`, `id`, `accountId`, `areaId`, `typeCode`,
   `materialNumber` and `lastModifiedDate` privately. Ensure the original name is
   non-empty so it can be restored under this endpoint's rules.
3. PATCH only the approved temporary name. Expect 204 and an empty body.
4. Read the device again. Verify the name and preserved ID, account, folder and
   type/material identifiers. A 204 alone is not verification.
5. If approved, run the validation checks below and read back after each one.
   Stop on an unexpected response or metadata change and restore before reporting.
6. In a `finally`/cleanup path, PATCH the original name and verify it through GET.
   If a concurrent name change or an unavailable readback prevents safe cleanup,
   stop and report that restoration is not verified; do not overwrite unrelated work.
7. Retain the request payloads, response statuses and metadata comparisons in the
   private workspace without authentication headers. Report the environment and
   limitations separately from the functional outcome.

The recorded QA run used a device in `root`; it proves preservation of that
folder, not the behaviour of folder moves or non-root-folder clearing.

## QA checks observed on 2026-11-11

| Request/case | Observed result |
| --- | --- |
| Name-only PATCH | 204, empty body; new name read back |
| Repeat the same name | 204; same name retained |
| Valid name plus `areaId: ""` | 204; folder remained `root` |
| `{"name":""}` | 400; name unchanged |
| `{}` | 400; name unchanged |
| `{"name":null}` | 400; name unchanged |
| `{"name":123}` | 400; name unchanged |
| Malformed JSON | 400; name unchanged |
| Restore original name | 204; original name read back |

All returned metadata except the display name and `lastModifiedDate` stayed
unchanged throughout. After restoration, only `lastModifiedDate` differed from
the baseline. No device configuration, application or licence operation was used.

## Official sources

Checked on 2026-11-11; prefer the live operation contract over older How-To PDFs.

- [PROD: UpdateDeviceDetails](https://developers.api.ctrlx-deviceportal.boschrexroth.com/api-details#api=licensing-bridge-service-prod-api-2&operation=UpdateDeviceDetails)
- [QA: UpdateDeviceDetails](https://digitalservices-qa.developer.azure-api.net/api-details#api=licensing-service&operation=UpdateDeviceDetails)
- [PROD: getAllDevices_v1_1](https://developers.api.ctrlx-deviceportal.boschrexroth.com/api-details#api=licensing-bridge-service-prod-api-2&operation=getAllDevices_v1_1)

Customer/device identifiers, credentials and raw evidence intentionally remain
outside this shared recipe.
