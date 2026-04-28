# ctrlX OS – Netzwerk FAQ

> Verifiziert auf: ctrlX OS x86-64, `rexroth-deviceadmin` 4.6.0, `rexroth-firewall` 4.4.0
> Gerät: `192.168.47.219`

---

## 1. Wie weist man einem Hardware-Port ein VLAN untagged zu?

**Kurz:** Das ctrlX OS kennt kein klassisches M/U-Port-Matrix-Konzept wie ein Managed Switch.
Ein **Untagged-Port** entspricht dem physischen Ethernet-Interface selbst — es empfängt Frames
ohne VLAN-Tag. Ein getaggtes VLAN (M = Member/Tagged) wird als **VLAN-Sub-Interface** auf dem
physischen Port angelegt.

### Konzept

| Managed-Switch-Begriff | ctrlX-Entsprechung |
|---|---|
| **U (Untagged)** | Physisches Interface direkt konfigurieren (z. B. `enp2s0`) |
| **M (Member, Tagged)** | VLAN-Sub-Interface anlegen (z. B. `enp2s0.100`, VLAN-ID 100) |

Das VLAN-Tagging (802.1Q) erfolgt am vorgelagerten Switch. Der ctrlX-Port muss dort als
**Trunk-Port** konfiguriert sein, der getaggte Frames weiterleitet.

### Schritte (UI)

1. Im Webbrowser öffnen: `https://192.168.47.219`
2. Navigieren zu: **Einstellungen → Netzwerk → Schnittstellen**
3. Auf **„VLAN hinzufügen"** klicken
4. Felder ausfüllen:
   - **Übergeordnete Schnittstelle:** physischen Port wählen (z. B. `enp2s0`)
   - **VLAN ID:** gewünschte VLAN-ID eingeben (1–4094, z. B. `100`)
5. Mit **Hinzufügen** bestätigen
6. Anschließend die IP-Konfiguration des neuen VLAN-Interface (z. B. `enp2s0.100`) einstellen

> **Hinweis:** Als übergeordnete Schnittstelle sind nur Ethernet-, WLAN- und DAN-Interfaces
> verfügbar, die nicht bereits als übergeordnete Schnittstelle für ein anderes VLAN verwendet
> werden.

---

## 2. Wie weist man ein VLAN mehreren Hardware-Ports zu?

Da ctrlX kein internes Switch-Fabric hat, gibt es **keine zentrale VLAN-Tabelle**.
Stattdessen wird für jede Port-VLAN-Kombination ein eigenes Sub-Interface angelegt.

### Vorgehensweise

Die Schritte aus **Frage 1** werden für jeden Port wiederholt:

| Interface | VLAN-ID | Ergebnis-Interface |
|---|---|---|
| `enp2s0` | 100 | `enp2s0.100` |
| `enp3s0` | 100 | `enp3s0.100` |

Jedes Sub-Interface erhält eine eigene IP-Konfiguration. Sollen beide Ports im gleichen
IP-Subnetz erreichbar sein, können sie über eine **Bridge** zusammengefasst werden
(**Einstellungen → Netzwerk → Schnittstellen → Bridge hinzufügen**, beide VLAN-Interfaces
als Member eintragen).

---

## 3. Wie wird ein Portforwarding eingerichtet?

Portforwarding ist eine Funktion der **Firewall-App** (`rexroth-firewall`) und wird über
**Destination NAT (DNAT)** realisiert.

### Pfad in der UI

**Einstellungen → Firewall → Tab „Routing" → „Routingregel hinzufügen"**

### Felder im Dialog

| Feld | Beschreibung | Beispielwert |
|---|---|---|
| Aktiviert | Regel ein-/ausschalten | Ein |
| Beschreibung | Optionaler Name | `Forward HTTP nach intern` |
| NAT-Type | Art der Adressübersetzung | **Destination NAT** |
| IP-Version | IPv4 oder IPv6 | IPv4 |
| Protokoll | TCP, UDP oder `*` (beliebig) | TCP |
| Quelladresse | Einschränkung der Quelle (leer = beliebig) | `*` |
| Quellport | Einschränkung Quellport (leer = beliebig) | `*` |
| Zieladresse | Externe IP des ctrlX-Geräts (leer = beliebig) | `*` |
| Zielport | Externer Port (eingehend) | `8080` |
| Addresse in die übersetzt wird | Interne Ziel-IP | `192.168.1.100` |
| Port in den übersetzt wird | Interner Zielport | `80` |

### Wichtiger Hinweis

> Alle Änderungen werden **sofort wirksam**, aber erst nach Klick auf
> **„Firewall-Konfiguration persistent speichern"** dauerhaft gespeichert.
> Nach einem Neustart ohne Speichern gehen die Regeln verloren.

---

## 4. Wofür sind die „Directional Interfaces"?

**Pfad in der UI:** Einstellungen → Firewall → Tab **„Directional interfaces"**

### Zweck

Directional Interfaces (auf Deutsch: **Schnittstellenregeln**) ermöglichen es, den
eingehenden und ausgehenden Datenverkehr auf **Interface-Ebene pauschal** zu steuern —
ohne komplexe IP/Port-basierte Filterregeln anlegen zu müssen.

Im Gegensatz zu den Filter-Regeln (Tab „Filter"), die auf Protokoll, IP-Adresse und
Portnummer matchen, gilt eine Schnittstellenregel für **den gesamten Datenverkehr**
eines bestimmten physischen Interfaces.

### Felder im Dialog „Interfaceregel hinzufügen"

| Feld | Beschreibung |
|---|---|
| Aktiviert | Regel aktiv oder inaktiv |
| Beschreibung | Optionaler Bezeichner |
| Interfacename | Physisches Interface, z. B. `enp2s0` |
| Aussperren verhindern | Schutzoption für das Konfigurations-Interface aktivieren |
| Eingehender Datenverkehr | Policy für ankommende Pakete |
| Ausgehender Datenverkehr | Policy für abgehende Pakete |

### Verfügbare Policies

**Eingehend:**

| Policy | Verhalten |
|---|---|
| Alles akzeptieren | Alle eingehenden Pakete werden durchgelassen |
| Alles abweisen, außer etablierte Verbindungen | Neue Verbindungen werden blockiert, Gegenseite wird informiert |
| Alles verwerfen, außer etablierte Verbindungen | Neue Verbindungen werden still verworfen |
| Alles abweisen | Alle Pakete blockiert, Gegenseite wird informiert |
| Alles verwerfen | Alle Pakete still verworfen |

**Ausgehend:**

| Policy | Verhalten |
|---|---|
| Alles akzeptieren | Alle ausgehenden Pakete werden gesendet |
| Alles abweisen, außer etablierte Verbindungen | Neue ausgehende Verbindungen blockiert, Gegenseite informiert |
| Alles abweisen | Alle ausgehenden Pakete blockiert |

### Typischer Anwendungsfall

Schnelle Absicherung eines industriellen Feldbusports: Eingehend auf
„Alles verwerfen, außer etablierte Verbindungen" setzen → nur bereits aufgebaute
Verbindungen bleiben aktiv, neue Verbindungsversuche von außen werden lautlos blockiert.
