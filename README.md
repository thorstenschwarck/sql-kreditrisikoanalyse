# Kreditrisikoanalyse — SQL Abschlussprojekt

Datenanalyse für einen Finanzdienstleister: Aufdeckung von Missständen in der Kreditvergabe und Entwicklung eines datenbasierten Risikoklassifizierungsmodells.

**Thorsten Schwarck · Juni 2026 · Abschlussprojekt Modul "Datenbanken & SQL", DataSmart Point**

---

## Projektauftrag

Rolle: Datenanalyst bei einem Finanzdienstleistungsunternehmen, das Konsumentenkredite vergibt. Der Bereichsvorstand vermutet Probleme im Kreditvergabeprozess, erhöhte Kreditausfälle und mögliche Schwächen in der Datenqualität.

**Aufgabe:**
1. Datenqualität prüfen und Missstände in der Kreditvergabe aufdecken
2. Kreditnehmer mittels `CASE WHEN` in Risikogruppen (hoch/mittel/niedrig) einteilen — Grenzwerte datenbasiert begründen
3. Handlungsempfehlungen für den Vorstand ableiten

**Datengrundlage:** 32.581 Kredite, 12 Merkmale (Alter, Einkommen, Wohnsituation, Beschäftigungsdauer, Kreditzweck, Bonitätsbewertung Loan Grade A–G, Kreditsumme, Zinssatz, Kreditstatus, Einkommensanteil, frühere Zahlungsausfälle, Kredithistorie). Bearbeitet in MySQL.

## Vorgehensweise

Strukturierter Analyseprozess in sechs Schritten: Explorative Datenanalyse → Data Cleaning → Analyse der Kreditvergabe → Identifikation der Risikofaktoren → Risikoklassifizierung → Handlungsempfehlungen.

### 1. Explorative Datenanalyse (EDA)

Prüfung von Vollständigkeit, Struktur, Wertebereichen und fehlenden Werten. Zentrale Befunde:

| Auffälligkeit | Anzahl | Bewertung |
|---|---|---|
| Alter > 100 Jahre (123 & 144 J.) | 5 | Datenfehler, entfernt |
| Beschäftigungsdauer > Lebensalter | 2 | Datenfehler, entfernt |
| Fehlende Zinssätze | 3.115 | Datenqualitätslücke (~10 % der Werte) |
| Fehlende Beschäftigungsdauer | 895 | Keine belastbare Grundlage für Klassifizierung |
| Kreditlaufzeit | fehlt komplett | Struktureller Mangel — monatliche Belastung nicht berechenbar |

Da die Kreditlaufzeit im Datensatz fehlt, wird `loan_percent_income` (Anteil der Kreditsumme am Jahreseinkommen) als Ersatzindikator für die finanzielle Belastung verwendet.

### 2. Data Cleaning

- Separate Arbeitstabelle angelegt, Original bleibt unverändert
- `loan_id` als Primärschlüssel eingeführt (fehlte im Originaldatensatz)
- Datentypen optimiert (u. a. `DECIMAL` statt `FLOAT`/`DOUBLE` für Geldbeträge zur Vermeidung von Rundungsfehlern, `TINYINT` statt `INT` für Alter/Status, `CHAR(1)` statt `VARCHAR` für Loan Grade)
- 7 Datensätze mit biologisch/logisch unplausiblen Werten entfernt (Alter > 100 Jahre, Beschäftigungsdauer > Lebensalter)
- **99,98 % des Originalbestands bleiben nutzbar** (32.574 von 32.581 Datensätzen)

### 3. Analyse der Kreditvergabe — vier Erkenntnisse

**Erkenntnis 1 — Extreme Einkommensbelastung:** 247 Kredite mit Einkommensanteil > 50 % zeigen Ausfallquoten von 70–100 % über alle Bonitätsstufen hinweg — auch bei eigentlich guter Bonität (Grade A: 69,81 % Ausfallquote).

**Erkenntnis 2 — Gute Bonität reicht nicht aus:** Von 148 Krediten mit Grade A/B und Einkommensanteil > 50 % fielen 104 aus (70,27 % Ausfallquote). Der Loan Grade allein ist keine ausreichende Entscheidungsgrundlage, wenn die Einkommensbelastung hoch ist.

**Erkenntnis 3 — Bonitätsmodell funktioniert, mit kritischem Sprung:** Ausfallquoten steigen sauber von Grade A (9,96 %) bis G (98,44 %). Zwischen C (20,74 %) und D (59,03 %) liegt jedoch ein Sprung von 38 Prozentpunkten — ab Grade D fällt mehr als jeder zweite Kredit aus.

**Erkenntnis 4 — Risiko erkannt, trotzdem vergeben:** 4.894 Kredite wurden in den Klassen D–G vergeben, obwohl Ausfallquoten von 59–98 % bereits bekannt waren. Die Schwäche liegt nicht im Scoring-Modell, sondern in der Vergabepraxis.

**Weitere Risikotreiber:**
- Wohnsituation: Mieter fallen mehr als viermal so häufig aus wie Eigentümer (31,57 % vs. 7,47 %)
- Kreditzweck: Schuldenkonsolidierung hat mit 28,59 % die höchste Ausfallquote aller Verwendungszwecke

### 4. Risikoklassifizierung

Grenzwerte direkt aus den beobachteten Ausfallquoten abgeleitet — keine willkürliche Festlegung. Umgesetzt als `CASE WHEN`-Abfrage, gespeichert als View, um die bereinigte Tabelle unverändert zu lassen.

**Hohes Risiko** (mindestens ein starker Faktor):
Einkommensanteil > 50 % ODER Loan Grade D–G

**Mittleres Risiko** (kein starker, aber mindestens ein mittlerer Faktor):
Loan Grade C ODER Wohnsituation "RENT" ODER Kreditzweck Schuldenkonsolidierung ODER frühere Zahlungsausfälle

**Niedriges Risiko:**
Kein identifizierter Risikofaktor

### Ergebnis

| Risikoklasse | Portfolioanteil | Ausfallquote |
|---|---|---|
| Niedriges Risiko | 29,45 % | 5,62 % |
| Mittleres Risiko | 54,92 % | 19,16 % |
| Hohes Risiko | 15,63 % | 61,68 % |

Die drei Gruppen trennen sich klar (5,62 % → 19,16 % → 61,68 % Ausfallquote), was die Trennschärfe der gewählten Faktoren bestätigt. Mit nur 15,63 % in der Hochrisikogruppe bleibt die Bank handlungsfähig, während das Risiko dort zuverlässig erkannt wird (Ausfallquote mehr als 3× über dem Portfolio-Durchschnitt von 21,82 %).

## Handlungsempfehlungen

**Kreditvergabe:**
- Einkommensbelastung stärker berücksichtigen — Grenzwert 50 % als Pflichtprüfung
- Kreditvergabe für Grade D–G restriktiver gestalten
- Wohnsituation und Kreditzweck stärker gewichten

**Datenqualität:**
- Zinssatz und Kreditlaufzeit verpflichtend erfassen
- Plausibilitätsprüfungen für Alter und Beschäftigungsdauer automatisieren

**Risikosteuerung:**
Klassifizierungsmodell als Monitoring-Werkzeug einsetzen, Hochrisikogruppe (61,68 % Ausfallquote) quartalsweise überprüfen.

## Technische Umsetzung

- **Datenbank:** MySQL
- **Datenbereinigung:** separate Arbeitstabelle, Primärschlüssel-Einführung, Datentyp-Optimierung
- **Risikoklassifizierung:** `CASE WHEN`-Logik, gespeichert als `VIEW` (`v_risikoeinteilung`)
- **Techniken:** Aggregationen, `GROUP BY ... WITH ROLLUP`, korrelierte Subqueries für Prozentanteile, Fensterfunktionen für Verteilungsanalysen

## Dateien in diesem Repo

| Datei | Inhalt |
|---|---|
| `Abschlussprojekt_TSch.sql` | Vollständiges, kommentiertes SQL-Skript — EDA, Data Cleaning, Risikoanalyse und Klassifizierung in einer Datei |
| `Kreditrisikoanalyse_TSchwarck.pptx` | Präsentation mit Vorgehensweise, Erkenntnissen und Handlungsempfehlungen |

---

*Abschlussprojekt im Modul "Datenbanken & SQL" bei DataSmart Point.*
