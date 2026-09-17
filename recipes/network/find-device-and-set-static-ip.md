# ctrlX CORE per Direktkabel finden und statische IPv4 setzen

> Verifiziert 2026-09-17: Rexroth IPC (arch02), ctrlX OS 4.4 (`rexroth-deviceadmin` 4.4.0),
> Linux-Laptop direkt per Ethernet verbunden.

## Problem

Core hängt direkt am Laptop, keine IP bekannt. Die Standardadressen (192.168.1.1 usw.) antworten nicht,
weil der verbundene Port auf **DHCP** steht und am Direktkabel kein DHCP-Server läuft → Port hat nur IPv6 link-local.

## 1. Gerät über IPv6 link-local finden (ohne Login, ohne Root)

```bash
IF=enp0s31f6                                  # Laptop-Interface mit carrier=1
ping -6 -c3 ff02::1%$IF                       # All-Nodes-Multicast → antwortet mit fe80::…
ip -6 neigh show dev $IF                      # MAC dazu
```

- Die link-local-Adresse ist aus der MAC abgeleitet (EUI-64) und **bleibt nach Updates/Neustarts gleich**.
- Prüfen, ob es eine ctrlX ist: `/identity-manager/...` und `/network-manager/...` antworten mit 401.
- Die MAC-OUI `74:fe:48` war hier der IPC-Onboard-NIC.

## 2. REST über link-local

```bash
LL="fe80::76fe:48ff:febc:c4b0"; R="https://[$LL%25$IF]"      # Zone-ID als %25 URL-kodiert, curl -g!
TOK=$(curl -sk -g -X POST "$R/identity-manager/api/v2/auth/token" \
  -H 'Content-Type: application/json' -d '{"name":"boschrexroth","password":"…"}' | jq -r .access_token)
curl -sk -g -H "Authorization: Bearer $TOK" "$R/network-manager/api/v1/interfaces"        # link:true = gesteckter Port
curl -sk -g -H "Authorization: Bearer $TOK" "$R/network-manager/api/v1/interfaces/<if>/addresses"
curl -sk -g -H "Authorization: Bearer $TOK" "$R/network-manager/api/v1/interfaces/<if>/configuration"
```

- Den gesteckten Port über `"link": true` bzw. die MAC der link-local-Adresse zuordnen.
- Browser: `https://[fe80::…%enp0s31f6]/` funktioniert in Firefox oft nicht; curl/Python schon.

## 3. Statische IPv4 setzen (persistente Änderung → Bestätigung einholen)

API: `networkmanager` OpenAPI ([rest-api-description](https://github.com/boschrexroth/rest-api-description),
`rexroth-deviceadmin/networkmanager`).

```bash
# Backup
curl -sk -g -H "Authorization: Bearer $TOK" "$R/network-manager/api/v1/interfaces/enp3s0f1/configuration" > backup.json
# dhcp4 entfernen, ipv4Address setzen, Rest unverändert übernehmen
jq 'del(.dhcp4) | .ipv4Address=["192.168.1.1/24"]' backup.json > new.json
curl -sk -g -X PUT -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' \
  --data @new.json "$R/network-manager/api/v1/interfaces/enp3s0f1/configuration"      # 204, noch NICHT aktiv
# Aktivieren + speichern
curl -sk -g -X PUT -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' \
  -d '{"applied":true,"discarded":false}' "$R/network-manager/api/v1/changes"           # 204
```

- Ohne `PUT /changes {"applied":true}` wird nichts übernommen/gespeichert.
- Statischer Port sieht danach so aus: `{"kind":"ethernet","dhcp6":true,"ipv4Address":["192.168.1.1/24"],…}`.
- Verifizieren: `GET …/addresses` → `{"kind":"static","address":"192.168.1.1/24"}`, dann `ping -I $IF 192.168.1.1`.
- Die statische IP überlebt Neustarts und System-App-Updates.

## Stolperfallen auf dem Laptop

- **Doppelte Host-IP**: Hatte der Laptop `192.168.1.11/24` auf zwei Interfaces (Onboard-NIC + USB-Adapter),
  ging die Route zu 192.168.1.1 über den falschen Adapter → `ping -I <if>` ok, Browser/curl ohne Interface: Timeout.
  Prüfen mit `ip route get 192.168.1.1`. Lösung: Adresse vom zweiten Adapter entfernen oder `/32`-Route setzen.
- **Link down → Route über VPN** (`tun0`): Während die Core neu startet, zeigt `ip route get` evtl. auf das VPN.
- **172.17.x.x** auf Core-Ports kollidiert mit Docker (`docker0` 172.17.0.0/16).
- Agent-Shells haben kein TTY: `sudo` mit Passwortabfrage funktioniert weder direkt noch per `!`-Präfix.
  Root-Befehle den Nutzer in einem eigenen Terminal ausführen lassen.
