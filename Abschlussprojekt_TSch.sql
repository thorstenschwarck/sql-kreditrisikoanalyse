-- Hinweis.
-- Ich habe für alle 4 Schritte (Datenüberblick, Datenbereinigung, Aufgabe 1 und Aufgabe 2) aus Gründen der Übersichtlichkeit jeweils eine eigene SQL-DAtei angelegt.
-- Diese sind jeweils hier komplett reingekopiert. Sollte es Probleme geben, kann ich die einzelnen Dateien gerne zur Verfügung stellen.
-- -----------------------------------

-- 1. Datenüberblick
-- Explorative Datenanalyse (EDA) 
-- Überblick, Kennzahlen, Verteilungen (Verstehen, was vorliegt)

-- 1. Vollständigkeit des Datensatzes prüfen
SELECT COUNT(*) AS anzahl_datensaetze
FROM credit_risk;
-- Feststellung:
-- Der Datensatz enthält 32.581 Datensätze, korrekt.
-- Die Anzahl entspricht den Angaben im Projektbriefing.
-- Es liegen keine Hinweise auf fehlende Datensätze vor.

-- =======================================================

-- 2. Sichtung der Daten
SELECT *
FROM credit_risk;
-- Feststellung:
-- Die Datenstruktur entspricht den Angaben im Projektbriefing.
-- Alle relevanten Informationen zur Kreditvergabe scheinen vorhanden.

-- ===========================================================

-- 3. Struktur und Inhalte, Tabellenstruktur analysieren, 12 Spalten
DESCRIBE credit_risk;
-- Feststellung:
-- Der Datensatz besteht aus 12 Spalten.
-- Es liegen numerische und kategoriale Merkmale vor.
-- Eine Kreditlaufzeit ist nicht Bestandteil des Datensatzes sondern fehlt
-- Folgende Datentypen könnten optimiert werden:
-- 1. PRIMARY ID: Die fehlt komplett. Datentyp hierfür: 
--    Spaltenname: loan_id 
--    Datentyp: INT UNSIGNED 
--    Attribute: PRIMARY KEY AUTO_INCREMENT
-- 2. Für Geldbeträge oder präzise Berechnungen NICHT! FLOAT oder DOUBLE verwenden, da hierbei Rundungsfehler auftreten können
--    loan_amnt und person_income KEIN INTEGER (Ganzzahl) sondern DECIMAL(10,2), um auch Cent-Beträge exakt abzubilden
--    loan_int_rate und loan_percent_income besser DECIMAL(5,2) für Zinssätze), um mathematische Genauigkeit bei der Risikokalkulation zu garantieren
-- 3. Speicheroptimierung bei Ganzzahlen
--    person_age: INTEGER belegt 4 Bytes. Da ein Mensch niemals 255 Jahre alt wird, ist TINYINT UNSIGNED (1 Byte und alle Werte positiv) die bessere Wahl
--    loan_status: Da diese Spalte nur die Werte 0 (kein Ausfall) und 1 (Ausfall) enthält, ist ein INT viel zu groß, daher TINYINT oder BOOL
--    cb_person_cred_hist_length: TINYINT, da Kredithistorien nicht 100 Jahre lang sind
-- 4. Effizienz bei Textspalten 
--    cb_person_default_on_file: Wenn hier nur 'Y' oder 'N' gespeichert wird, ist ein VARCHAR(5) ineffizient. Es reicht CHAR(1), die Länge ist doch hier fest
--    loan_grade: Bonitätsbewertujngen reichen von 'A' bis 'G'. CHAR(1) reicht
-- 5. Laufzeit Kredit fehlt. In der Regel Monate bzw. volle Jahre.
--    Vorschlag loan_term: INT
--    Hier nicht zu berechnen. Kreditsumme und Zinssatz sind vorhanden aber es fehlen die monatliche Rate und die Laufzeit. 
--    D.h. 2 der 4 Variablen fehlen gleichzeitig = mathematisch nicht lösbar.
--    Echter Datenmangel und in Aufgabe 1 benennen!!!!


-- ============================

-- Wertebereiche und Verteilungen
-- 4. Wertebereiche der numerischen Spalten (Summen, Durchschnittswerte, Vergleiche)
SELECT
  MIN(person_age)                    AS Alter_min,  -- Alter Kreditnehmer
  MAX(person_age)                    AS Alter_max,
  ROUND(AVG(person_age), 1)          AS Alter_avg,
-- Feststellung
-- Jüngster Kreditnehmer 20 Jahre
-- Ältester Kreditnehmer 144 Jahre - UNREALISTISCH!!! Der Wert erscheint unplausibel und wird im Data-Cleaning näher untersucht.
-- Durchschnittsalter Kreditnehmer 27,7 Jahre

  MIN(person_income)                 AS Einkommen_min, -- Bruttoeinkommen Kreditnehmer 
  MAX(person_income)                 AS Einkommen_max,
  ROUND(AVG(person_income), 0)       AS Einkommen_avg,
  -- Feststellung
  -- Kleinstes Einkommen 4.000 €
  -- Höchstes Einkommen 6.000.000 € -- HINTERFRAGEN. -- Der Wert liegt deutlich über dem Durchschnittseinkommen und wird auf Plausibilität geprüft.
  -- Durchschnittseinkommen 66.075 €
  

  MIN(person_emp_length)             AS Beschäftigungsdauer_min, -- Dauer der aktuellen Beschäftigung Kreditnehmer
  MAX(person_emp_length)             AS Beschäftigungsdauer_max,
  ROUND(AVG(person_emp_length), 1)   AS Beschäftigungsdauer_avg,
  -- Feststellung
  -- kürzeste Beschäftigungsdauer 0 Jahre
  -- längste Beschäftigungsdauer 123 Jahre -- UNREALISTISCH!!! -- Dieser Wert erscheint unplausibel und wird im Data-Cleaning näher untersucht.
  -- durchschnittliche Beschäftigungsdauer 4,8 Jahre
  

  MIN(loan_amnt)                     AS Kredithöhe_min, -- Hohe des beantragten und vergebenen Kredits
  MAX(loan_amnt)                     AS Kredithöhe_max,
  ROUND(AVG(loan_amnt), 0)           AS Kredithöhe_avg,
-- Feststellung
-- Kreditsummen bewegen sich zwischen 500 € und 35.000 €.
-- Die Werte erscheinen auf den ersten Blick plausibel.
-- durchschnittliche Kreditsumme 9.589 €

  MIN(loan_int_rate)                 AS Zinssatz_min, -- Zinssatz des bewilligten Kredits
  MAX(loan_int_rate)                 AS Zinssatz_max,
  ROUND(AVG(loan_int_rate), 2)       AS Zinssatz_avg,
-- Feststellung
-- Zinssätze zwischen 5,42 % und 23,22 %.
-- Höchster Zinssatz 23.22 % -- HINTERFRAGEN. -- Die Spannweite ist relativ groß und sollte später im Zusammenhang mit den Loan Grades
-- untersucht werden.
-- durchschnittlicher Zinssatz 11.01 %


  MIN(loan_percent_income)           AS Kredit_an_Jahreseinkommen_min, -- Anteil der Kreditsumme am Jahreseinkommen
  MAX(loan_percent_income)           AS Kredit_an_Jahreseinkommen_max,
  ROUND(AVG(loan_percent_income), 2) AS Kredit_an_Jahreseinkommen_avg,
-- Feststellung
-- Höchster Anteil der Kreditsumme am Jahreseinkommen: 83 %
-- Einige Kreditnehmer finanzieren damit einen sehr hohen Anteil ihres Jahreseinkommens über Kredite.
-- Diese Fälle werden später genauer untersucht.
  

  MIN(cb_person_cred_hist_length)    AS Kredithistorie_min, -- Länge Kredithistorie 
  MAX(cb_person_cred_hist_length)    AS Kredithistorie_max,
  ROUND(AVG(cb_person_cred_hist_length), 1) AS Kredithistorie_avg
FROM credit_risk;
-- Kurze Kredithistorie → weniger Informationen über das Zahlungsverhalten → höheres Risiko
-- Eine kurze Kredithistorie erschwert die Bewertung des bisherigen Zahlungsverhaltens.
-- Lange Kredithistorie → mehr Informationen vorhanden → Risiko besser einschätzbar
-- Feststellung
-- Kredithistorien zwischen 2 und 30 Jahren.
-- Durchschnittliche Kredithistorie: 5,5 Jahre.

-- ===========================================================================

-- Kategorische Spalten – Verteilungen
-- 5. Loan Grade Verteilung (inkl. Prozentwert) Bonitätsbewertung
SELECT loan_grade AS Bonitätswert,
       COUNT(*) AS anzahl,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM credit_risk), 1) AS prozent
FROM credit_risk
GROUP BY loan_grade
ORDER BY loan_grade;
-- Feststellung
-- Verteilung analysiert.
-- Prüfen, ob einzelne Bonitätsstufen über- oder unterrepräsentiert sind.

-- =================================================
-- 6. Loan Intent Verteilung / Verwendungszweck
SELECT loan_intent,
       COUNT(*) AS anzahl,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM credit_risk), 1) AS prozent
FROM credit_risk
GROUP BY loan_intent
ORDER BY anzahl DESC;
-- Feststellung
-- Verwendungszwecke identifiziert.
-- Häufigste Kreditgründe dokumentieren.

-- ================================================

-- 7. Wohnsituation
SELECT person_home_ownership AS Wohnsituation,
       COUNT(*) AS anzahl,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM credit_risk), 1) AS prozent
FROM credit_risk
GROUP BY person_home_ownership
ORDER BY anzahl DESC;
-- Feststellung
-- Verteilung der Wohnformen analysiert.
-- Prüfen, ob bestimmte Wohnsituationen später mit erhöhten Ausfallraten zusammenhängen.

-- ===================================================

-- 8. Frühere Zahlungsausfälle (Y/N)
SELECT cb_person_default_on_file AS Zahlungsausfälle,
       COUNT(*) AS anzahl,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM credit_risk), 1) AS prozent
FROM credit_risk
GROUP BY cb_person_default_on_file;
-- Feststellung
-- Anteil der Kreditnehmer mit negativer Kredithistorie ermittelt.

-- ===================================================

-- 9. Kreditstatus-Verteilung (0 = kein Ausfall; 1= Ausfall))
SELECT loan_status AS Ausfallrate,
       COUNT(*) AS anzahl,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM credit_risk), 1) AS prozent
FROM credit_risk
GROUP BY loan_status;
-- Anteil ausgefallener Kredite bestimmt.
-- Dient später als Zielgröße für die Risikoanalyse

-- ===================================================
-- 10. Null-Werte (Enthält der Datensatz (alle 12 Spalten) fehlende Werte?)
SELECT
    SUM(person_age IS NULL) AS "Fehlendes Alter",
    SUM(person_income IS NULL) AS "Fehlendes Einkommen",
    SUM(person_home_ownership IS NULL) AS "Fehlende Wohnsituation",
    SUM(person_emp_length IS NULL) AS "Fehlende Beschäftigungsdauer",
    SUM(loan_intent IS NULL) AS "Fehlender Kreditzweck",
    SUM(loan_grade IS NULL) AS "Fehlender Loan Grade",
    SUM(loan_amnt IS NULL) AS "Fehlende Kredithöhe",
    SUM(loan_int_rate IS NULL) AS "Fehlender Zinssatz",
    SUM(loan_status IS NULL) AS "Fehlender Kreditstatus",
    SUM(loan_percent_income IS NULL) AS "Fehlender Einkommensanteil",
    SUM(cb_person_default_on_file IS NULL) AS "Fehlende Zahlungshistorie",
    SUM(cb_person_cred_hist_length IS NULL) AS "Fehlende Kredithistorie"
FROM credit_risk;
-- Feststellung:
-- Für 895 Kreditnehmer liegt keine Beschäftigungsdauer vor.
-- Für 3.116 Kredite fehlt der Zinssatz.
-- Sonst fehlen keine Daten
-- Die Auswirkungen dieser fehlenden Werte werden im Data-Cleaning-Schritt untersucht.

-- Wie verteilen sich die fehlenden Zinssätze auf Loan Grades?
SELECT 
    loan_grade AS Bonitätsbewertung,
    COUNT(*) AS gesamt,
    SUM(CASE WHEN loan_int_rate IS NULL THEN 1 ELSE 0 END) AS fehlender_zinssatz,
    ROUND(SUM(CASE WHEN loan_int_rate IS NULL THEN 1 ELSE 0 END) 
          * 100.0 / COUNT(*), 1) AS "Anteil in %"
FROM credit_risk
GROUP BY loan_grade
ORDER BY loan_grade;

-- Wie ist der loan_status bei Krediten ohne Zinssatz?
SELECT 
    loan_status AS Kreditstatus,
    COUNT(*) AS anzahl
FROM credit_risk
WHERE loan_int_rate IS NULL
GROUP BY loan_status;

-- Wie verteilen sich die fehlenden Beschäftigungsdauern auf loan_status?
SELECT 
    loan_status,
    COUNT(*) AS anzahl
FROM credit_risk
WHERE person_emp_length IS NULL
GROUP BY loan_status;


-- =========================================

-- 11. Leere Strings (vorhandener Wert, aber leer " " gespeichert) 
-- Wohnsituation
SELECT
    COUNT(*) AS leere_wohnsituation
FROM credit_risk
WHERE person_home_ownership = '';

-- Kreditzweck
SELECT COUNT(*) AS leerer_kreditzweck
FROM credit_risk
WHERE loan_intent = '';

-- Bonitätsbewertung
SELECT COUNT(*) AS leerer_loan_grade
FROM credit_risk
WHERE loan_grade = '';

-- Zahlungsausfälle
SELECT COUNT(*) AS leere_zahlungshistorie
FROM credit_risk
WHERE cb_person_default_on_file = '';

-- Feststellung:
-- In den kategorialen Variablen wurden keine leeren Zeichenketten festgestellt.

-- 12. Duplikatprüfung
-- Prüfung auf vollständig identische Datensätze (alle Merkmale gleich)
SELECT
    person_age,
    person_income,
    person_home_ownership,
    person_emp_length,
    loan_intent,
    loan_grade,
    loan_amnt,
    loan_int_rate,
    loan_status,
    loan_percent_income,
    cb_person_default_on_file,
    cb_person_cred_hist_length,
    COUNT(*) AS anzahl
FROM credit_risk
GROUP BY
    person_age, person_income, person_home_ownership,
    person_emp_length, loan_intent, loan_grade,
    loan_amnt, loan_int_rate, loan_status,
    loan_percent_income, cb_person_default_on_file,
    cb_person_cred_hist_length
HAVING COUNT(*) > 1
ORDER BY anzahl DESC;

-- Feststellung:
-- In der Originaltabelle war kein Primärschlüssel
-- vorhanden. Daher können identische Datensätze
-- nicht eindeutig als technische Duplikate
-- identifiziert werden.

-- Die Duplikatprüfung ergab lediglich vereinzelte
-- identische Merkmalskombinationen mit einer
-- maximalen Häufigkeit von zwei Datensätzen.

-- Hinweise auf ein systematisches Duplikatproblem
-- liegen nicht vor.



-- 1. Unrealistisches Alter
SELECT person_age, COUNT(*) AS anzahl
FROM credit_risk
WHERE person_age > 80
GROUP BY person_age
ORDER BY person_age;
-- Feststellung:
-- 1 x 84 Jahre alt
-- 1 x 94 Jahre alt
-- 2 x 123 Jahre alt
-- 3 x 144 Jahre alt
-- Es wurden 7 Kreditnehmer mit einem Alter über 80 Jahren gefunden.
-- Der höchste Wert beträgt 144 Jahre.
-- Diese Altersangaben erscheinen unplausibel und werden im
-- Data-Cleaning-Schritt näher untersucht.

-- 2. Unmögliche Beschäftigungsdauer
SELECT COUNT(*)
FROM credit_risk
WHERE person_emp_length > person_age;

SELECT
    person_age AS "Alter",
    person_emp_length AS "Beschäftigungsdauer",
    person_income AS "Bruttoeinkommen"
FROM credit_risk
WHERE person_emp_length > person_age;
-- Feststellung:
-- Es wurden 2 Datensätze identifiziert, bei denen die
-- Beschäftigungsdauer das Lebensalter deutlich übersteigt.

-- Datensatz 1:
-- Alter: 22 Jahre
-- Beschäftigungsdauer: 123 Jahre

-- Datensatz 2:
-- Alter: 21 Jahre
-- Beschäftigungsdauer: 123 Jahre

-- Diese Werte sind fachlich unmöglich und stellen
-- eindeutige Datenfehler dar.

-- Die Datensätze werden im Data-Cleaning-Schritt
-- gesondert behandelt.

-- 3. Logischer Widerspruch: Kredithistorie älter als Person
SELECT COUNT(*) AS widerspruch_anzahl
FROM credit_risk
WHERE cb_person_cred_hist_length >= person_age;
-- Feststellung:
-- Es wurden keine Datensätze gefunden, bei denen die
-- Kredithistorie länger oder gleich lang wie das Alter
-- des Kreditnehmers ist.
-- Die Angaben zur Kredithistorie erscheinen daher grundsätzlich plausibel.

-- 4. Extremes Einkommen
SELECT COUNT(*) AS Anzahl
FROM credit_risk
WHERE person_income > 1000000;

SELECT
    person_income AS Einkommen,
    person_age AS "Alter",
    loan_amnt AS Kredithöhe,
    loan_grade AS Bonitätsbewertung,
    loan_status AS Kreditstatus
FROM credit_risk
WHERE person_income > 1000000
ORDER BY person_income DESC;
-- Feststellung:
-- Es wurden 9 Kreditnehmer mit einem Jahreseinkommen
-- von über 1.000.000 € identifiziert.
-- Diese Werte liegen deutlich über dem Durchschnittseinkommen
-- von 66.075 € und werden auf Plausibilität geprüft.


-- ======================================
-- Durchschnittswerte für Altersgruppen im Vergleich
SELECT
    CASE
        WHEN person_age BETWEEN 18 AND 30 THEN '18-30'
        WHEN person_age BETWEEN 31 AND 45 THEN '31-45'
        WHEN person_age BETWEEN 46 AND 60 THEN '46-60'
        WHEN person_age BETWEEN 61 AND 80 THEN '61-80'
        ELSE 'über 80'
    END AS altersgruppe,
    COUNT(*)                              AS anzahl,
    ROUND(AVG(person_income), 0)          AS avg_einkommen,
    ROUND(AVG(loan_amnt), 0)              AS avg_kredithöhe,
    ROUND(AVG(loan_percent_income), 2)    AS avg_anteil_kredit_am_einkommen,
    ROUND(AVG(loan_int_rate), 2)          AS avg_zinssatz,
    ROUND(AVG(loan_status), 2)            AS ausfallrate
FROM credit_risk
GROUP BY altersgruppe
ORDER BY altersgruppe;

-- Feststellung:
-- Die Ausfallraten unterscheiden sich zwischen den Altersgruppen nur gering.

-- Die Gruppen 18–30 Jahre (22 %) und 46–60 Jahre (22 %)
-- weisen nahezu identische Ausfallquoten auf.
-- Auch die Gruppe 31–45 Jahre liegt mit 20 %
-- auf einem ähnlichen Niveau.

-- Die höhere Ausfallquote der Gruppe 61–80 Jahre (27 %)
-- basiert lediglich auf 63 Kreditnehmern und ist daher
-- nur eingeschränkt belastbar.

-- Für die Gruppe über 80 Jahre liegen nur 7 Datensätze vor,
-- sodass keine aussagekräftige Bewertung möglich ist.

-- Insgesamt zeigt das Alter keine ausreichend klare
-- Trennlinie zwischen risikoarmen und risikoreichen
-- Kreditnehmern und wird daher nicht als eigenständiger
-- Risikofaktor für die spätere Analyse verwendet.



-- =====================================================
-- EDA - ZUSAMMENFASSUNG (für Präsi kürzen)
-- =====================================================
-- 1. Datenbestand
-- Der Datensatz umfasst 32.581 Kreditvergaben.
-- Die Struktur entspricht den Angaben im Projektbriefing.
-- Es liegen 12 Merkmale zu Kreditnehmern und Krediten vor.

-- ====================
-- 2. Datentypen / Datenmodell
-- Die vorhandenen Datentypen sind grundsätzlich nutzbar, d.h. Datentypen sind funktional korrekt, aber teilweise optimierbar.
-- Für ein produktives System wären Optimierungen hinsichtlich
-- Datentypen, Speicherbedarf und Datenqualität sinnvoll.
-- Zudem fehlt eine eindeutige Primärschlüssel-ID.

-- ====================
-- 3.  Datenqualität
-- Es wurden mehrere Auffälligkeiten identifiziert.

-- Auffällige Alterswerte:
-- Einzelne Kreditnehmer sind 84 bzw. 94 Jahre alt.
-- Zudem wurden 2 Kreditnehmer mit 123 Jahren und 3 Kreditnehmer mit 144 Jahren identifiziert.
-- Die Werte 123 und 144 Jahre erscheinen unplausibel und werden im Data Cleaning näher untersucht.

-- Unrealistische Beschäftigungsdauer:
-- 2 Datensätze mit 123 Jahren Beschäftigungsdauer bei Personen im Alter von 21 bzw. 22 Jahren.

-- Fehlende Werte:
-- 895 fehlende Beschäftigungsdauern.
-- 3.115 fehlende Zinssätze.

-- Diese Auffälligkeiten werden im Data Cleaning näher untersucht.

-- ====================
-- 4. Datenverfügbarkeit
-- Die Kreditlaufzeit ist nicht Bestandteil des Datensatzes.
-- Dadurch kann die tatsächliche monatliche Belastung eines Kreditnehmers nicht exakt berechnet werden.
-- Für die weitere Analyse wird deshalb loan_percent_income (Anteil der Kreditsumme am Jahreseinkommen) als Indikator verwendet. 
-- Die Kennzahl beschreibt den Anteil der Kreditsumme am Jahreseinkommen und liefert einen Hinweis auf die finanzielle Belastung des Kreditnehmers.


-- ==================

-- 5. Fachliche Beobachtungen (Interpretationen teilweise aus Recherche Kriterien von Banken zur Kreditvergabe)
-- Die Kreditsummen erscheinen grundsätzlich plausibel.

-- Die Zinssätze weisen eine große Spannweite auf und werden später im Zusammenhang mit den Loan Grades untersucht.

-- Einzelne Kreditnehmer verfügen über außergewöhnlich hohe Einkommen und werden gesondert betrachtet.

-- ====================
-- Festellungen und Fazit:
--
-- Der Datensatz ist grundsätzlich für die weitere Analyse geeignet.
--
-- Es wurden mehrere Datenqualitätsprobleme identifiziert, die vor der eigentlichen Risikoanalyse bereinigt oder bewertet werden müssen.
--
-- Insbesondere die 
-- fehlenden Zinssätze, 
-- fehlenden Beschäftigungsdauern sowie, 
-- die identifizierten Ausreißer/Unplausibilitäten bei Alter und Beschäftigungsdauer 
-- werden im nächsten Schritt untersucht.

-- Nächster Schritt:
-- Data Cleaning. Bereinigung des Datensatzes auf Basis der identifizierten Qualitätsprobleme und Ausreißer.

-- ----------------------------------
-- ----------------------------------

-- 2. Datenbereinigung

-- Data Cleaning: Bereinigung des Datensatzes auf Basis der identifizierten Qualitätsprobleme und Ausreißer

-- To-Dos für Data Cleaning
-- Bereinigte Tabelle anlegen
-- Bereinigung Datentypen
-- Datensätze mit person_age > 100 ausschließen
-- Datensätze mit person_emp_length > person_age ausschließen
-- Datensätze mit person_income > 1.000.000 prüfen
-- Fehlende Zinssätze (loan_int_rate IS NULL) bewerten
-- Fehlende Beschäftigungsdauer bewerten: (person_emp_length IS NULL) – behalten oder ausschließen?

-- ========================================
-- 1. Bereinigte Tabelle anlegen, um damit weiter zuarbeiten.
SHOW FULL TABLES;

DROP TABLE IF EXISTS credit_risk_clean;

-- Schritt 1:
-- Erstellung einer bereinigten Arbeitstabelle.

-- Die Originaltabelle credit_risk bleibt unverändert.
-- Alle weiteren Bereinigungen erfolgen auf der Tabelle credit_risk_clean.

-- Ergänzung eines Primärschlüssels: loan_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY

-- Ziel:
-- Eindeutige Identifikation jedes Datensatzes während des Data-Cleanings und der späteren Analysen.

CREATE TABLE credit_risk_clean AS
SELECT *
FROM credit_risk;

SHOW FULL TABLES;

SELECT COUNT(*)
FROM credit_risk_clean;

SELECT * FROM credit_risk_clean;
SELECT * FROM credit_risk_clean_backup;

ALTER TABLE credit_risk_clean
ADD COLUMN loan_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;
DESCRIBE credit_risk_clean;

SHOW CREATE TABLE credit_risk_clean;

-- Schritt 2
-- Speicheroptimierung: Ganzzahlige Spalten verkleinern
ALTER TABLE credit_risk_clean
    MODIFY COLUMN person_age TINYINT UNSIGNED,
    MODIFY COLUMN loan_status TINYINT(1),
    MODIFY COLUMN cb_person_cred_hist_length TINYINT UNSIGNED;
DESCRIBE credit_risk_clean;
 
-- Präzision bei Geldbeträgen und Zinssätzen (DECIMAL statt INT/DOUBLE für exakte Cent-Beträge, Vermeidung Rundungsfehler), höhere Berechnungsgenauigkeit für die Risikoanalyse
SELECT COUNT(*)
FROM credit_risk_clean
WHERE loan_int_rate IS NULL;
-- Ergebnis:
-- 3.116 fehlende Zinssätze vorhanden.

 ALTER TABLE credit_risk_clean
    MODIFY COLUMN person_income DECIMAL(12,2),
     -- Einkommen exakt auf Cent, kein Rundungsfehler
    MODIFY COLUMN loan_amnt DECIMAL(10,2),
     -- Kreditsumme exakt auf Cent
    MODIFY COLUMN loan_int_rate DECIMAL(5,2),
     -- Zinssatz z.B. 12.50 % → 5 Stellen, 2 Nachkommastellen
    MODIFY COLUMN loan_percent_income DECIMAL(5,4);
	-- Anteil Kredit / Jahreseinkommen
    
    DESCRIBE credit_risk_clean;
    
-- Textspalten optimieren (Feststehende Werte mit fester Länge werden auf CHAR(1) umgestellt, um Speicherbedarf und Verarbeitung zu optimieren)
SELECT DISTINCT loan_grade
FROM credit_risk_clean
ORDER BY loan_grade;

SELECT DISTINCT cb_person_default_on_file
FROM credit_risk_clean
ORDER BY cb_person_default_on_file;

ALTER TABLE credit_risk_clean
    MODIFY COLUMN loan_grade CHAR(1),
    MODIFY COLUMN cb_person_default_on_file CHAR(1);

DESCRIBE credit_risk_clean;

SELECT COUNT(*)
FROM credit_risk_clean
WHERE person_age > 100;

SELECT COUNT(*)
FROM credit_risk_clean
WHERE person_emp_length > person_age;

SELECT COUNT(*)
FROM credit_risk_clean;

-- =====================================================
-- DATA CLEANING - DATENQUALITÄT
-- =====================================================
-- Vor Beginn der Datenbereinigung Sicherung der Arbeitstabelle.
--
-- Ziel:
-- Wiederherstellungsmöglichkeit bei fehlerhaften
-- Lösch- oder Änderungsoperationen.

CREATE TABLE credit_risk_clean_backup AS
SELECT *
FROM credit_risk_clean;
SELECT COUNT(*) 
FROM credit_risk_clean_backup;

-- Datensätze mit person_age > 100 ausschließen (Kreditnehmer mit 84 bzw. 94 Jahren kann es durchaus geben und verbleiben im Datenatz)

-- Kontrolle vor Bereinigung
SELECT
    person_age,
    COUNT(*) AS anzahl
FROM credit_risk_clean
WHERE person_age > 100
GROUP BY person_age
ORDER BY person_age;

-- Ergebnis:
-- 123 Jahre: 2 Datensätze
-- 144 Jahre: 3 Datensätze

DELETE FROM credit_risk_clean -- Löschung über den Primärschlüssel
WHERE loan_id IN (
    SELECT loan_id
    FROM (
        SELECT loan_id
        FROM credit_risk_clean
        WHERE person_age > 100
    ) x
);
SELECT COUNT(*) 
FROM credit_risk_clean
WHERE person_age > 100;
-- 5 Datensätze mit Alter > 100 Jahre entfernt.
-- Werte 123 und 144 Jahre wurden als unplausibel eingestuft.

-- ====================================

-- Datensätze mit person_emp_length > person_age ausschließen 
-- (Beschäftigungsdauer ist höher als das Alter des Kreditnehmers = unplausibel)
-- Kontrolle vor Bereinigung
SELECT
    loan_id,
    person_age AS "Alter Kreditnehmer",
    person_emp_length AS "Dauer Beschäftigung"
FROM credit_risk_clean
WHERE person_emp_length > person_age;

-- Ergebnis:
-- loan_id 1   -> Alter 22 Jahre, Beschäftigungsdauer 123 Jahre
-- loan_id 256 -> Alter 21 Jahre, Beschäftigungsdauer 123 Jahre

-- Safe Update Mode temporär deaktivieren,
-- da Datensätze anhand fachlicher Kriterien bereinigt werden.

SET SQL_SAFE_UPDATES = 0;

DELETE FROM credit_risk_clean
WHERE person_emp_length > person_age;

SET SQL_SAFE_UPDATES = 1;

-- Kontrolle nach Bereinigung
SELECT COUNT(*) AS verbleibende_unplausible_beschaeftigungsdauer
FROM credit_risk_clean
WHERE person_emp_length > person_age;
-- Feststellung:
-- 2 Datensätze wurden entfernt.
-- Die Beschäftigungsdauer überstieg das Lebensalter des Kreditnehmers 
-- und wurde als eindeutiger Datenfehler eingestuft.


SELECT COUNT(*)
FROM credit_risk_clean;

SELECT COUNT(*)
FROM credit_risk_clean
WHERE person_age > 100;

SELECT COUNT(*)
FROM credit_risk_clean
WHERE person_emp_length > person_age;

-- =======================================

-- Datensätze mit person_income > 1.000.000 überprüfen

SELECT
    loan_id,
    person_income AS Einkommen,
    person_age AS "Alter",
    loan_amnt AS Kredithöhe,
    loan_grade AS Bonität,
    loan_status AS Kreditstatus
FROM credit_risk_clean
WHERE person_income > 1000000
ORDER BY person_income DESC;
-- Es wurden ursprünglich 9 Einkommen über 1.000.000 € identifiziert.
-- Nach Entfernung der unplausiblen Alterswerte verbleiben 8 Datensätze.
-- Die Werte stellen statistische Ausreißer dar.
-- Da keine fachlichen Widersprüche festgestellt wurden,
-- verbleiben die Datensätze im bereinigten Datenbestand.
--
-- Der mögliche Einfluss auf Durchschnittswerte wird
-- bei späteren Analysen berücksichtigt.


-- ================================
-- Datensätze mit loan_int_rate IS NULL ausschließen (Höhe des Zinssatz)
-- Treten die fehlenden Zinssätze bei bestimmten Bonitätsklassen auf? 
-- Bei welchen Bonitätsklassen fehlen die Zinssätze?

SELECT
    loan_grade AS Bonität,
    COUNT(*) AS anzahl
FROM credit_risk_clean
WHERE loan_int_rate IS NULL
GROUP BY loan_grade
ORDER BY loan_grade;

SELECT
    loan_status AS Kreditstatus, -- 0 = kein Ausfall, 1 = Ausfall
    COUNT(*) AS anzahl
FROM credit_risk_clean
WHERE loan_int_rate IS NULL
GROUP BY loan_status;

SELECT
    ROUND(AVG(loan_status) * 100,2) AS ausfallquote_gesamt
FROM credit_risk_clean;

SELECT
    ROUND(AVG(loan_status) * 100,2) AS ausfallquote_ohne_zinssatz
FROM credit_risk_clean
WHERE loan_int_rate IS NULL;

-- Feststellung:
-- Bei 3.115 Krediten fehlt die Angabe des Zinssatzes.
--
-- Die fehlenden Werte treten in allen Bonitätsklassen
-- (A bis G) auf und betreffen sowohl ausgefallene als
-- auch nicht ausgefallene Kredite.
--
-- Die Ausfallquote der Kredite ohne Zinssatz beträgt
-- 20,67 % und liegt damit nahe an der Ausfallquote des
-- Gesamtdatensatzes von 21,82 %.
--
-- Es konnte kein Hinweis auf eine systematische
-- Verzerrung festgestellt werden.
--
-- Die Datensätze werden daher nicht ausgeschlossen,
-- da lediglich ein einzelnes Merkmal fehlt und die
-- übrigen Kreditinformationen weiterhin verfügbar sind.


-- =============================
-- Entscheidung treffen: person_emp_length IS NULL – behalten oder ausschließen? Fehlende Beschäftigungsdauer

-- Wieviele fehlen?
SELECT COUNT(*)
FROM credit_risk_clean
WHERE person_emp_length IS NULL;
-- 895 Datensätze 


-- Verteilung nach Kreditstatus
SELECT
    loan_status AS Kreditstatus, -- 0 = kein Ausfall, 1= Ausfall
    COUNT(*) AS anzahl
FROM credit_risk_clean
WHERE person_emp_length IS NULL
GROUP BY loan_status;
-- 0 = 613
-- 1 = 282


-- Ausfallquote vergleichen
SELECT
    ROUND(AVG(loan_status) * 100,2) AS ausfallquote_gesamt
FROM credit_risk_clean;

SELECT
    ROUND(AVG(loan_status) * 100,2) AS ausfallquote_ohne_beschaeftigungsdauer
FROM credit_risk_clean
WHERE person_emp_length IS NULL;

-- Verteilung nach Bonität
SELECT
    loan_grade AS Bonitaet,
    COUNT(*) AS anzahl
FROM credit_risk_clean
WHERE person_emp_length IS NULL
GROUP BY loan_grade
ORDER BY loan_grade;

SELECT
    ROUND(AVG(loan_status) * 100,2) AS ausfallquote_ohne_beschaeftigungsdauer
FROM credit_risk_clean
WHERE person_emp_length IS NULL;

-- Feststellung:
-- Bei 895 Kreditnehmern fehlt die Angabe zur
-- Beschäftigungsdauer.

-- Die fehlenden Werte treten in mehreren
-- Bonitätsklassen auf.

-- Die Ausfallquote dieser Gruppe beträgt 31,51 %
-- und liegt damit deutlich über der Ausfallquote
-- des Gesamtdatensatzes von 21,82 %.

-- Die Datensätze werden dennoch beibehalten,
-- da lediglich ein einzelnes Merkmal fehlt und
-- die fehlende Beschäftigungsdauer selbst einen
-- möglichen Risikohinweis darstellt.


-- Abschluß Data Cleaning
-- Entfernt:
-- Alter > 100 Jahre (5 Datensätze)
-- Beschäftigungsdauer > Lebensalter (2 Datensätze)

-- Behalten:
-- Einkommen > 1.000.000 € (plausible Ausreißer)
-- Fehlende Zinssätze (3.115 Datensätze)
-- Fehlende Beschäftigungsdauer (895 Datensätze)


-- =====================================================
-- DATA CLEANING - ABSCHLUSS
-- =====================================================

-- Originaltabelle:
-- credit_risk

-- Arbeitstabelle:
-- credit_risk_clean

-- Backup:
-- credit_risk_clean_backup

-- Entfernte Datensätze:
-- 5 Datensätze mit Alter > 100 Jahre
-- 2 Datensätze mit Beschäftigungsdauer > Lebensalter

-- Beibehaltene Auffälligkeiten:
-- Extreme Einkommen > 1.000.000 € wurden geprüft und beibehalten
-- Fehlende Zinssätze wurden geprüft und beibehalten.
-- Fehlende Beschäftigungsdauer wurde geprüft und beibehalten.

-- Die Tabelle credit_risk_clean bildet die Grundlage
-- für die weitere Risikoanalyse.

-- Verbliebene Datensätze nach dem Cleaning
SELECT
    32581 AS "Gesamt Original",
    COUNT(*) AS "bereinigter Bestand",
    32581 - COUNT(*) AS entfernt,
    ROUND((32581 - COUNT(*)) * 100.0 / 32581, 2) AS "entfernt Prozent"
FROM credit_risk_clean;
-- Verbleibender Analysebestand:
-- 32.574 Datensätze

-- -----------------------------------
-- -----------------------------------

-- 3. Aufgabe 1
-- =====================================================
-- AUFGABE 1
-- Missstände und Auffälligkeiten in der Kreditvergabe
-- =====================================================
-- Ausgangspunkt meiner Analyse war die Vermutung des Vorstands,
-- dass es Probleme im bisherigen Kreditvergabeprozess gibt.
-- Ich habe den Datensatz systematisch auf Datenqualität,
-- Risikobelastung und Vergabeentscheidungen untersucht.
-- Dabei folgende Auffälligkeiten festgestellt:

-- Struktur
-- 1. Datenqualitätsprobleme (bereits in EDA und Cleaning dokumentiert)
-- 2. Kredite mit auffällig hoher Risikobelastung
-- 3. Überprüfung der Bonitätsbewertung (Loan Grades)
-- 4. Weitere Auffälligkeiten: Kreditzweck und Wohnsituation

-- =====================================================
-- 1. Datenqualitätsprobleme
-- =====================================================
-- Was EDA und Data Cleaning ergeben haben:

-- Unplausible Altersangaben:
-- 5 Datensätze mit Alter > 100 Jahre (123 und 144 Jahre)
-- Eindeutige Datenfehler. Ich habe diese entfernt,
-- da sie keine realen Kreditnehmer abbilden können.

-- Unmögliche Beschäftigungsdauer:
-- 2 Datensätze mit Beschäftigungsdauer > Lebensalter
-- (22-Jähriger mit 123 Jahren Berufserfahrung)
-- Ebenfalls eindeutige Datenfehler und entfernt.

-- Fehlende Zinssätze:
-- 3.115 Kredite ohne Zinssatzangabe (ca. 10 % des Portfolios)
-- Die Ausfallquote dieser Gruppe: 20,67 % verglichen mit 21,82 % im Gesamtdatensatz.
-- Ein systematisches Ausfallmuster ist damit nicht erkennbar.
-- Ich habe die Datensätze behalten, bewerte das Fehlen
-- des Zinssatzes aber als erhebliches Datenqualitätsproblem:
-- Für rund 1 von 10 Krediten fehlt eine zentrale
-- Vertragsinformation. Das erschwert Risiko-,
-- Ertrags- und Portfolioanalysen erheblich und deutet
-- auf strukturelle Lücken in der Datenerfassung hin.

-- Fehlende Beschäftigungsdauer:
-- 895 Kreditnehmer ohne Angabe zur Beschäftigungsdauer
-- Die Ausfallquote dieser Gruppe: 31,51 % (vs. 21,82 % gesamt)
-- Das ist auffällig – fast 10 Prozentpunkte über dem Schnitt.
-- Ob das fehlende Merkmal selbst ein Risikofaktor ist
-- oder nur gemeinsam mit anderen Risikomerkmalen auftritt,
-- konnte ich nicht eindeutig belegen.
-- Ich habe diese Datensätze behalten, jedoch nicht als eigenständiger
-- Risikofaktor in Aufgabe 2 verwendet.

-- Extreme Einkommen:
-- 8 Kreditnehmer mit Jahreseinkommen > 1.000.000 €
-- Das ist fachlich nicht widersprüchlich (Hochverdiener existieren).
-- Als Ausreißer behalten, aber in Analysen im Blick behalten.

-- Fehlende Kreditlaufzeit:
-- Im gesamten Datensatz nicht vorhanden → echte Datenlücke
-- Das ist aus meiner Sicht ein echter blinder Fleck:
-- Ohne Laufzeit kann die monatliche Rückzahlungsbelastung
-- nicht berechnet werden. Ich habe loan_percent_income
-- als Ersatzindikator für die Einkommensbelastung verwendet.

-- Bereinigter Datenbestand: 32.574 Datensätze
-- (32.581 original – 5 Altersfehler – 2 Beschäftigungsfehler)
-- -------------------------------------------------------

-- Kontrolle bereinigter Datenbestand
SELECT COUNT(*) AS Analysegrundlage
FROM credit_risk_clean;
-- Ergebnis: 32.574 Datensätze

-- ====================================================================================================
-- 2. Kredite mit auffällig hoher Risikobelastung (Kredite, die bereits bei der Vergabe kritisch waren)
-- ====================================================================================================
-- Kredite mit loan_percent_income > 0.5
-- (Kreditsumme übersteigt 50 % des Jahreseinkommens)
-- Wieviele Kredite und wie hoch sind die Ausfallquoten?

SELECT 
    COALESCE(loan_grade, 'GESAMT') AS Bonitätsbewertung,
    COUNT(*) AS Anzahl,
    ROUND(AVG(loan_status) * 100, 2) AS "Ausfallquote in %",
    ROUND(AVG(loan_percent_income), 2) AS "Kredit Einkommensanteil"
FROM credit_risk_clean
WHERE loan_percent_income > 0.5
GROUP BY loan_grade WITH ROLLUP;


-- Feststellung:
-- 247 Kredite wurden mit einer Belastung von über 50 %
-- des Jahreseinkommens vergeben – quer über alle Bonitätsklassen.

-- Ein Kredit-Einkommens-Verhältnis von über 50 % ist aus meiner Sicht eindeutig zu hinterfragen. 
-- Wer mehr als die Hälfte seines Jahreseinkommens als Kredit aufnimmt, hat kaum
-- noch Spielraum für Lebenshaltungskosten, Miete und sonstige
-- Verpflichtungen. Die Ausfallquoten sprechen für sich:

-- Grade A: 53 Kredite → 69,81 % Ausfallquote
-- Grade B: 95 Kredite → 70,53 % Ausfallquote
-- Grade C: 49 Kredite → 85,71 % Ausfallquote
-- Grade D: 31 Kredite → 96,77 % Ausfallquote
-- Grade E: 12 Kredite → 100,00 % Ausfallquote
-- Grade F:  7 Kredite → 85,71 % Ausfallquote
-- Gesamt: 247 Kredite

-- Gesamtausfallquote im Datensatz zum Vergleich: 21,82 %

-- Was ich hier als besonders kritisch einstufe: 
-- Selbst Grade-A-Kreditnehmer – also die vermeintlich sichersten –
-- fallen zu fast 70 % aus, sobald die 50%-Grenze
-- überschritten wird. Das ist kein Ausreißer, sondern
-- deutet eher auf eine systematische Schwäche
-- im bisherigen Vergabeprozess hin.
-- Der Loan Grade allein schützt nicht, wenn die
-- Einkommensbelastung zu hoch ist.

-- Aus meiner Sicht sind das genau die Kredite,
-- die bereits zum Zeitpunkt der Vergabe kritisch
-- hätten hinterfragt werden müssen.

-- Die späteren Ausfallquoten von 70 % bis 100 %
-- zeigen, dass die hohe finanzielle Belastung bereits
-- zum Zeitpunkt der Kreditvergabe ein deutliches
-- Warnsignal darstellte.


-- ===============================================
-- Detailansicht: Einzelne Kredite mit höchster Belastung

SELECT
loan_ID AS "Loan ID", 
   loan_grade AS Bonitätsbewertung,
   person_income AS Jahreseinkommen,
    ROUND(person_income / 12, 0) AS Monatseinkommen,
    loan_amnt AS Kreditsumme,
    ROUND(loan_amnt / (person_income / 12), 1) AS "Kreditsumme in Monatsgehältern", -- wieviele Monatsgehälter, um den Kredit zurückzuzahlen
    loan_percent_income AS Einkommensanteil,
	cb_person_default_on_file AS "Ausfälle",
    loan_status AS Kreditstatus
FROM credit_risk_clean
WHERE loan_percent_income > 0.5
ORDER BY loan_percent_income DESC;

-- Feststellung:
-- Die Abfrage zeigt alle 247 Kredite mit einem Einkommensanteil
-- von über 50 % – geordnet nach der höchsten Belastung.

-- Konkretes Beispiel aus dem Datensatz:
-- Jahreseinkommen: 20.000 € → Monatseinkommen: 1.667 €
-- Kreditsumme: 16.600 € → Einkommensanteil: 83 %
-- Für Lebenshaltungskosten bleibt faktisch nichts übrig.

-- =========================================================
-- Extremfälle: Kreditsumme übersteigt 70 % des Jahreseinkommens
-- Diese Kredite hätten aus meiner Sicht bei der
-- Antragsprüfung klar abgelehnt werden müssen.

SELECT
    loan_id AS "Loan ID",
    loan_grade AS Bonitätsbewertung,
    person_income AS Jahreseinkommen,
    ROUND(person_income / 12, 0) AS Monatseinkommen,
    loan_amnt AS Kreditsumme,
    ROUND(loan_percent_income * 100, 1) AS "Einkommensanteil in %",
    loan_status AS Kreditstatus
FROM credit_risk_clean
WHERE loan_percent_income > 0.70
ORDER BY loan_percent_income DESC;

-- Feststellung:
-- Diese Kredite übersteigen 70 % des Jahreseinkommens.
-- Bei einem monatlichen Einkommen von z.B. 1.667 €
-- bleibt nach Lebenshaltungskosten faktisch kein
-- Spielraum für eine Rückzahlung.
-- Eine Vergabe hätte an dieser Stelle klar
-- abgelehnt werden müssen.

-- Im gesamten bereinigten Portfolio gibt es genau 9 Kredite
-- mit einem Einkommensanteil von über 70 %.
-- 7 davon sind ausgefallen – das entspricht einer
-- Ausfallquote von 77,8 %.

-- Besonders kritisch:
-- Loan ID 28068: Grade A, 840 € Monatseinkommen,
--                Kredit 7.200 € → ausgefallen
-- Loan ID 23561: Grade A, 1.000 € Monatseinkommen,
--                Kredit 9.325 € → ausgefallen

-- Fast alle dieser Kredite tragen Grade A oder B –
-- also die beste Bonitätsbewertung.
-- Trotzdem sind 7 von 9 ausgefallen.

-- Das sind Kredite die bei der Antragsprüfung
-- klar hätten abgelehnt werden müssen.
-- Der Loan Grade allein reicht als Entscheidungsgrundlage
-- nicht aus, wenn die Einkommensbelastung so extrem ist.

-- ========================================

-- Falsch vergebene Kredite: Grade A/B mit hoher Einkommensbelastung
-- Der Loan Grade signalisierte "sicherer Kreditnehmer" –
-- die tatsächliche Ausfallquote zeigt das Gegenteil.

SELECT
     COALESCE(loan_grade, 'GESAMT') AS Bonitätsbewertung,
    COUNT(*) AS Anzahl,
    SUM(loan_status) AS Ausfälle,
    ROUND(AVG(loan_status) * 100, 2) AS "Ausfallquote in %",
    ROUND(AVG(loan_percent_income) * 100, 1) AS "Ø Einkommensanteil in %"
FROM credit_risk_clean
WHERE loan_grade IN ('A', 'B')
AND loan_percent_income > 0.50
GROUP BY loan_grade WITH ROLLUP;

-- Feststellung:
-- 148 Kredite tragen Grade A oder B –
-- also die beste Bonitätsbewertung der Bank.

-- Grade A: 53 Kredite →  69,81 % Ausfallquote
-- Grade B: 95 Kredite →  70,53 % Ausfallquote
-- Gesamt: 148 Kredite → 70,27 % Ausfallquote
-- Durchschnittlicher Einkommensanteil: 56,9 %

-- Das Bonitätsmodell hat diese Kreditnehmer als
-- zuverlässig eingestuft – aber die Einkommensbelastung
-- nicht ausreichend berücksichtigt.

-- Von 148 Krediten mit guter Bonität und hoher
-- Einkommensbelastung sind 104 ausgefallen.
-- Die Ergebnisse sprechen gegen einen Zufall
-- und deuten auf eine systematische Schwäche
-- im Vergabeprozess hin.

-- Loan Grade und Einkommensbelastung müssen
-- gemeinsam bewertet werden.
-- Einer allein reicht nicht als Entscheidungsgrundlage.

-- Fazit: Für mich ist das einer der deutlichsten Hinweise
-- auf Schwächen im bisherigen Vergabeprozess.
-- Bei Ausfallquoten von bis zu 100 % hätte dieses
-- Einkommensbelastung aus meiner Sicht deutlich stärker
-- berücksichtigt werden müssen. Dieser Missstand bildet die wichtigste Grundlage
-- für die Risikogruppeneinteilung in Aufgabe 2.


-- =====================================================
-- 3. Überprüfung der Bonitätsbewertung (LOAN GRADES)
-- =====================================================
-- Ich möchte prüfen, ob die vergebenen Loan Grades
-- das tatsächliche Ausfallrisiko plausibel abbilden:

-- - Steigen die Ausfallquoten mit sinkender Bonität?
-- - Werden höhere Risiken durch höhere Zinssätze bepreist?
-- - Spielen frühere Zahlungsausfälle bei der Einstufung eine Rolle?

-- -------------------------------------------------------
-- 3.1 Stimmt die Risikoabstufung von A nach G?
-- Bilden die Loan Grades das tatsächliche Risiko der Kreditnehmer plausibel ab
-- Erwartung: A = niedrigste Ausfallquote, G = höchste

SELECT
    COALESCE(loan_grade, 'GESAMT') AS Bonitätsbewertung,
    COUNT(*)                         AS "Anzahl Kredite",
    SUM(loan_status)                 AS "Anzahl Ausfälle",
    ROUND(AVG(loan_status) * 100, 2) AS "Ausfallquote in %",
    ROUND(AVG(loan_int_rate), 2)     AS "Ø Zinssatz"
FROM credit_risk_clean
GROUP BY loan_grade WITH ROLLUP;


-- Feststellung:
-- Die Grundrichtung stimmt – Ausfallquoten und Zinssätze
-- steigen von Grade A bis G kontinuierlich an.
-- Das Bonitätsmodell funktioniert in seiner Grundlogik.

-- Was mir aber auffällt: 
-- Der Sprung zwischen Grade C (20,74 %) und Grade D (59,03 %) ist enorm –
-- fast 40 Prozentpunkte auf einmal.
-- Ab Grade D fällt mehr als jeder zweite
-- vergebene Kredit aus. 
-- Trotz dieser hohen Ausfallwahrscheinlichkeit wurden 
-- in den Klassen D bis G insgesamt 4.894 Kredite vergeben.
-- D: 3625 
-- E: 964 
-- F: 241
-- G: 64

-- Die Analyse liefert keine Hinweise auf ein
-- fehlerhaftes Bonitätsmodell, das Modell erkennt das Risiko.

-- Es scheint eine Frage der Risikobereitschaft:
-- Die Bank hat diese Kredite vergeben, obwohl historisch
-- mehr als die Hälfte davon ausfallen.
-- Das halte ich für kritisch und empfehle eine
-- deutlich restriktivere Vergabepraxis ab Grade D.

-- -------------------------------------------------------
-- 3.2 Wurden frühere Zahlungsausfälle (Vorausfälle) bei der Grade-Vergabe (Bonitätsbewertung) berücksichtigt?

SELECT
    loan_grade                              AS Bonitätsbewertung,
    cb_person_default_on_file               AS Vorausfall,
    COUNT(*)                                AS Anzahl,
    ROUND(AVG(loan_status) * 100, 2)        AS "Ausfallquote in %",
    ROUND(AVG(loan_amnt), 0)                AS "Ø Kreditsumme"
FROM credit_risk_clean
GROUP BY loan_grade, cb_person_default_on_file
ORDER BY loan_grade, cb_person_default_on_file;

-- Feststellung:
-- Frühere Zahlungsausfälle werden bei der
-- Bonitätsbewertung (Bonitätsmodell) offensichtlich berücksichtigt.

-- Im Datensatz finden sich keine Kreditnehmer
-- mit dokumentierten Vorausfällen in den
-- Bonitätsklassen A oder B.

-- Das zeigt, dass das Modell diese Information verarbeitet.
-- Systematische Fehler bei der Grade-Vergabe konnte ich
-- in diesem Bereich nicht feststellen.

-- -------------------------------------------------------
-- 3.3 Werden höhere Risiken durch höhere Zinssätze bepreist?

-- Zinssatz-Spannweite je Grade
-- Grade A → niedrige Zinsen, Grade G → hohe Zinsen
SELECT
    loan_grade                          AS Bonitätsbewertung,
    COUNT(*)                            AS Anzahl,
    ROUND(MIN(loan_int_rate), 2)        AS "Zinssatz MIN",
    ROUND(MAX(loan_int_rate), 2)        AS "Zinssatz MAX",
    ROUND(AVG(loan_int_rate), 2)        AS "Ø Zinssatz"
FROM credit_risk_clean
WHERE loan_int_rate IS NOT NULL
GROUP BY loan_grade
ORDER BY loan_grade;

-- Feststellung:
-- Auch hier stimmt die Grundrichtung – der Durchschnittszinssatz
-- steigt von 7,33 % (Grade A) auf 20,25 % (Grade G).

-- Auffällig sind jedoch Überschneidungen in den Zinsspannen:
-- Grade B, C, D und E haben alle denselben Minimalzinssatz
-- von 6,00 %. Das bedeutet, es gibt Grade-D-Kreditnehmer
-- die genauso wenig Zinsen zahlen wie Grade-B-Kreditnehmer –
-- obwohl ihre Ausfallquote fast viermal so hoch ist. 

-- Die Überschneidungen der Zinsspannen zeigen,
-- dass Kreditnehmer mit unterschiedlichem Risiko
-- teilweise vergleichbare Mindestzinssätze erhalten haben.

-- Ob dies auf Einzelfälle oder auf Besonderheiten
-- im Vergabeprozess zurückzuführen ist, lässt sich
-- anhand der vorliegenden Daten nicht eindeutig beurteilen.

-- =====================================================
-- 4. Weitere Auffälligkeiten
-- =====================================================

-- 4.1 Ausfallquoten nach Kreditzweck. 
-- Für welche Kreditzwecke treten die höchsten Ausfallquoten auf? 

SELECT
    COALESCE(loan_intent, 'GESAMT')     AS Kreditzweck,
    COUNT(*)                            AS "Anzahl Kredite",
    SUM(loan_status)                    AS "Anzahl Ausfälle",
    ROUND(AVG(loan_status) * 100, 2)    AS "Ausfallquote in %"
FROM credit_risk_clean
GROUP BY loan_intent WITH ROLLUP;


-- Feststellung:
-- Die Ausfallquoten variieren deutlich je nach Kreditzweck.
-- Am stärksten betroffen sind:
-- Schuldenkonsolidierung (DEBTCONSOLIDATION): 28,59 %
-- Medizinische Ausgaben (MEDICAL):            26,70 %
-- Modernisierung (HOMEIMPROVEMENT):           26,10 %

-- Besonders auffällig ist die Schuldenkonsolidierung:
-- Wer bestehende Schulden durch neue Kredite ablöst, steht in der Regel 
-- bereits unter finanziellem Druck und fällt deutlich häufiger aus als der 
-- Portfoliodurchschnitt von 21,82 %. 
-- Bestehende Schulden sind damit ein klarer
-- Risikofaktor der, meiner Einschätzung nach, stärker gewichtet werden sollte.

-- Für die spätere Risikoklassifizierung wird jedoch
-- nur DEBTCONSOLIDATION verwendet.

-- Begründung:
-- DEBTCONSOLIDATION weist die höchste Ausfallquote
-- aller Kreditzwecke auf und deutet zusätzlich auf
-- bereits bestehende finanzielle Belastungen hin.

-- MEDICAL und HOMEIMPROVEMENT werden daher als
-- beobachtete Risikosignale dokumentiert, jedoch
-- nicht als eigenständige Risikofaktoren in die
-- Risikoklassifizierung übernommen.

-- -------------------------------------------------------
-- 4.2. Ausfallquoten nach Wohnsituation
-- Haben bestimmte Wohnsituationen ein höheres Ausfallrisiko?

SELECT
    person_home_ownership AS Wohnsituation,
    COUNT(*) AS `Anzahl Kredite`,
    ROUND(AVG(loan_status) * 100, 2) AS `Ausfallquote in %`
FROM credit_risk_clean
GROUP BY person_home_ownership
ORDER BY `Ausfallquote in %` DESC;

-- Feststellung:
-- Die Ausfallquote unterscheidet sich deutlich
-- nach der Wohnsituation der Kreditnehmer.
-- Die Wohnsituation gehört damit zu den stärkeren
-- Risikofaktoren im gesamten Datensatz:

-- Mieter (RENT):             31,57 %
-- Hypothek (MORTGAGE):       12,57 %
-- Eigentümer (OWN):           7,47 %

-- Mieter (RENT) weisen mit 31,57 % die höchste
-- Ausfallquote auf und liegen damit deutlich über
-- dem Durchschnitt des Portfolios (21,82 %).

-- Kreditnehmer mit Hypothek (MORTGAGE) liegen mit
-- 12,57 % deutlich unter dem Durchschnitt, aber
-- über dem Niveau der Eigentümer.

-- Eigentümer (OWN) zeigen hingegen nur eine
-- Ausfallquote von 7,47 %.

-- Mieter fallen mehr als viermal so häufig aus wie Eigentümer.
-- Das ist ein enormer Unterschied – und ein Faktor, der im
-- bisherigen Vergabeprozess offenbar zu wenig Gewicht hatte.
-- Die Daten zeigen jedoch nur den Zusammenhang,
-- nicht die genaue Ursache.

-- Die Kategorie OTHER ist im Datensatz nicht näher
-- beschrieben und wurde daher fachlich nicht weiter interpretiert.

-- =====================================================
-- Fazit Aufgabe 1 und Brücke zu Aufgabe 2
-- =====================================================
-- Die Analyse bestätigt die Vermutung des Vorstands.
-- Es gibt klare und nachweisbare Schwächen
-- sowohl auf Ebene der Datenqualität als auch
-- im Kreditvergabeprozess selbst.

-- 1. Datenqualität als Grundproblem
--    Fehlende Zinssätze (10 %), unvollständige Beschäftigungs-
--    angaben und die fehlende Kreditlaufzeit sind keine
--    Kleinigkeiten – sie blenden systematisch wichtige
--    Risikoinformationen aus.

-- 2. Kredite mit unvertretbarer finanzieller Belastung
--    247 Kredite mit Einkommensanteil > 50 % weisen
--    Ausfallquoten von 70–100 % auf.
--    Besonders kritisch: 148 davon tragen Grade A oder B –
--    die Bank hat sie als zuverlässig eingestuft,
--    aber 104 sind trotzdem ausgefallen.
--    Der Loan Grade allein reicht nicht als
--    Entscheidungsgrundlage – die Einkommensbelastung
--    muss zwingend mitbewertet werden.
--    Die extremsten Fälle im Portfolio zeigen das deutlich:
--    9 Kredite übersteigen 70 % des Jahreseinkommens –
--    für Lebenshaltungskosten bleibt faktisch nichts übrig.
--    Diese Kredite hätten bei der Antragsprüfung
--    kritischer geprüft oder abgelehnt werden müssen.

-- 3. Zu hohe Risikobereitschaft bei der Kreditvergabe
--    Das Bonitätsmodell selbst funktioniert grundsätzlich.
--    Aber: 4.894 Kredite in den Klassen D–G wurden vergeben,
--    obwohl diese historisch zwischen 59 % und 98 % ausfallen.
--    Das Problem liegt in der Risikobereitschaft bei der Vergabe.

-- 4. Wohnsituation als starker Risikofaktor
--    Mieter fallen viermal häufiger aus als Eigentümer.
--    Dieser Faktor wird bisher zu wenig berücksichtigt.

-- 5. Kreditzweck als Risikoindikator
--    Schuldenkonsolidierung, medizinische Ausgaben und
--    Modernisierung weisen überdurchschnittliche Ausfallquoten auf.

-- -------------------------------------------------------
-- Handlungsempfehlungen

-- 1. Plausibilitätsprüfungen einführen
--    Alters- und Beschäftigungsangaben automatisch validieren.

-- 2. Datenlücken schließen
--    Zinssatz und Kreditlaufzeit vollständig erfassen,
--    beides sind zentrale Vertragsinformationen.

-- 3. Verbindliche Belastungsgrenzen einführen
--    Klare Grenzwerte für das Verhältnis von
--    Einkommen und Kreditsumme festlegen.
--    Kredite mit einem Einkommensanteil von über 50 % des Jahreseinkommens
--    sollten einer gesonderten Prüfung unterzogen werden.

-- 4. Verschärfte Prüfung für Grade D–G
--    Kreditvergabe in Klassen D–G restriktiver gestalten
--    oder mit zusätzlichen Sicherheiten absichern.

-- 5. Wohnsituation und Kreditzweck stärker gewichten
--    Beide Faktoren sind starke Prädiktoren für Kreditausfälle
--    und sollten in die Risikobewertung einfließen.

-- -------------------------------------
-- -------------------------------------

-- 4. Aufgabe 2
-- =====================================================
-- AUFGABE 2
-- Kreditnehmer in Risikogruppen einteilen
-- =====================================================
-- In Aufgabe 1 habe ich systematisch untersucht,
-- welche Faktoren im Portfolio tatsächlich mit
-- hohen Ausfallquoten einhergehen.
-- In Aufgabe 2 übersetze ich diese Erkenntnisse
-- in ein konkretes Klassifikationsmodell.
-- Jeder Grenzwert ist direkt aus einer Abfrage
-- in Aufgabe 1 abgeleitet – nichts wurde willkürlich gesetzt.

-- -------------------------------------------------------
-- Verwendete Risikofaktoren und ihre Begründung
-- -------------------------------------------------------

-- Starke Risikofaktoren - Einstufung: Hohes Risiko

-- loan_percent_income > 0.50
-- Anteil der Kreditsumme am Jahreseinkommen über 50 %
-- Quelle: Aufgabe 1, Abschnitt 2
-- 247 Kredite betroffen → Ausfallquoten zwischen 70 % und 100 %
-- Was mich dabei am meisten überrascht hat:
-- Selbst Grade-A-Kreditnehmer fallen zu fast 70 % aus,
-- sobald die 50 %-Grenze überschritten wird.
-- Das ist der stärkste einzelne Risikofaktor im Datensatz.

-- loan_grade IN ('D','E','F','G')
-- Bonitätsklassen D bis G
-- Quelle: Aufgabe 1, Abschnitt 3.1
-- D = 59,03 % 
-- E = 64,42 % 
-- F = 70,54 % 
-- G = 98,44 %
-- Ab Grade D fällt mehr als jeder zweite Kredit aus.
-- Die Bank selbst hat diese Kreditnehmer als risikoreich
-- eingestuft – die Ausfallquoten bestätigen das.

-- -------------------------------------------------------
-- Mittlere Risikofaktoren - Einstufung: Mittleres Risiko
-- -------------------------------------------------------

-- loan_grade = 'C'
-- Bonitätsklasse C → Ausfallquote 20,74 %
-- Quelle: Aufgabe 1, Abschnitt 3.1
-- Ich stufe Grade C als mittleres Risiko ein, weil er die
-- direkte Übergangszone bildet: Klassen A und B liegen
-- deutlich darunter, Klasse D springt auf fast 60 %.
-- Grade C ist damit die kritische Grenzklasse.

-- person_home_ownership = 'RENT'
-- Quelle: Aufgabe 1, Abschnitt 4.2
-- Mieter Ausfallquote: 31,57 % 
-- Eigentümer: 7,47 %
-- Das ist ein Unterschied, den ich in dieser Deutlichkeit
-- nicht erwartet hatte. Mieter fallen viermal häufiger aus.
-- Allein kein Ausschlusskriterium, aber ein starkes Signal.

-- loan_intent = 'DEBTCONSOLIDATION'
-- Schuldenkonsolidierung → Ausfallquote 28,59 %
-- Quelle: Aufgabe 1, Abschnitt 4.1
-- Höchste Ausfallquote aller Kreditzwecke.
-- Wer bestehende Schulden durch neue Kredite ablöst,
-- steht häufig bereits unter finanziellem Druck.

-- cb_person_default_on_file = 'Y'
-- Frühere Zahlungsausfälle in der Kredithistorie
-- Quelle: Aufgabe 1, Abschnitt 3.2
-- Grundsätzlich sind Vorausfälle ein negatives Merkmal.
-- Das Bonitätsmodell berücksichtigt Vorausfälle bereits –
-- kein Kreditnehmer mit Vorausfall hat Grade A oder B erhalten.
-- Als eigenständiges Signal daher eher mittel.

-- -------------------------------------------------------
-- Nicht verwendete Faktoren
-- -------------------------------------------------------

-- loan_int_rate (Zinssatz)
-- Obwohl die Zinsgruppen-Analyse eine klare Trennlinie
-- bei 15 % zeigt (Ausfallquote springt von 22 % auf 57 %),
-- habe ich den Zinssatz bewusst ausgeschlossen:
-- Für 3.115 Kredite (ca. 10 %) fehlt die Angabe.
-- Das würde zu einer lückenhaften Risikobewertung führen.

-- person_emp_length IS NULL (Fehlende Beschäftigungsdauer)
-- Kreditnehmer ohne Beschäftigungsangabe weisen zwar
-- eine erhöhte Ausfallquote (31,51%) auf.
-- Es konnte jedoch nicht eindeutig nachgewiesen werden,
-- ob die fehlende Beschäftigungsdauer selbst das Risiko
-- erhöht oder lediglich gemeinsam mit anderen
-- Risikofaktoren auftritt.

-- Daher wird das Merkmal nicht für die
-- Risikogruppierung verwendet.

-- =====================================================
-- Zinssatz: Analyse und Ausschlussbegründung
-- =====================================================
-- Der Zinssatz wurde der Vollständigkeitshalber untersucht, jedoch nicht für die
-- Risikogruppeneinteilung verwendet.

SELECT
    CASE
        WHEN loan_int_rate < 10 THEN 'unter 10 %'
        WHEN loan_int_rate < 15 THEN '10–15 %'
        WHEN loan_int_rate < 20 THEN '15–20 %'
        ELSE 'über 20 %'
    END AS Zinsgruppe,
    COUNT(*) AS Anzahl,
    ROUND(AVG(loan_status) * 100, 2) AS "Ausfallquote in %"
FROM credit_risk_clean
WHERE loan_int_rate IS NOT NULL
GROUP BY Zinsgruppe
ORDER BY MIN(loan_int_rate);

-- Begründung Ausschluss:
-- Für 3.115 Kredite (ca. 10 % des Portfolios) fehlt
-- die Zinssatzangabe – das würde zu einer lückenhaften
-- Risikobewertung führen.
-- Zudem bildet loan_grade das Risiko bereits ab.
-- Der Zinssatz ist damit redundant und unvollständig.


-- =====================================================
-- Definition der Risikogruppen
-- =====================================================

-- Hohes Risiko:
-- Kreditnehmer mit mindestens einem starken Risikofaktor.

-- Mittleres Risiko:
-- Kreditnehmer ohne starken Risikofaktor,
-- aber mit mindestens einem mittleren Risikofaktor.

-- Niedriges Risiko:
-- Kreditnehmer ohne identifizierte Risikofaktoren.

-- ===================================
-- Einteilung in Risikogruppen
-- ===================================

-- Erstellung einer View, um die Einteilung in Risikogruppen zu speichern, ohne die
-- Daten in meiner credit_risk_clean-Tabelle zu verändern.

CREATE OR REPLACE VIEW v_risikoeinteilung AS
SELECT 
    *,
    CASE 
        -- 1. Hohes Risiko (Eindeutig starke Faktoren)
        -- Einkommensbelastung > 50% (Ausfallquote bis zu 100%)
        -- Bonitätsstufen D bis G (Ausfallrate bis zu 98,44%)
        WHEN loan_percent_income > 0.50 
             OR loan_grade IN ('D', 'E', 'F', 'G') 
        THEN 'Hohes Risiko'
        
        -- 2. Mittleres Risiko (Eindeutig mittlere Faktoren)
        -- Wohnsituation 'RENT' (Ausfallquote 31,57% vs. 7,47% bei Eigentümern)
        -- Kreditzweck 'DEBTCONSOLIDATION' (Höchstes Zweck-Risiko mit 28,59%)
        -- Vorhandene Zahlungsausfälle ('Y') oder Loan Grade C (20,74%)
        WHEN loan_grade = 'C' 
             OR person_home_ownership = 'RENT' 
             OR loan_intent = 'DEBTCONSOLIDATION' 
             OR cb_person_default_on_file = 'Y' 
        THEN 'Mittleres Risiko'
        
        -- 3. Niedriges Risiko
        -- Alle verbleibenden Kreditnehmer (z.B. Eigentümer mit Grade A/B)
        ELSE 'Niedriges Risiko'
    END AS Risikoklasse
FROM credit_risk_clean;



-- Feststellung:
-- Die Abfrage weist jedem der 32.574 Kreditnehmer
-- eine Risikoklasse zu – direkt abgeleitet aus den
-- Faktoren die ich vorher als Risikofaktoren (s.o.) identifiziert habe.

-- Die Logik dahinter war für mich:
-- Ein starker Risikofaktor allein reicht für ein hohes Risiko.
-- Mittlere Faktoren erhöhen das Risiko spürbar,
-- sind aber kein Ausschlusskriterium.
-- Wer keinen der identifizierten Risikofaktoren aufweist,
-- gilt als niedriges Risiko.

-- Die Einteilung speichere ich als VIEW,
-- um die Originaltabelle unverändert zu lassen.

-- Die folgende Kontrollabfrage zeigt eine Stichprobe mit 20 Datensätzen, ob
-- die Risikoklasse korrekt erzeugt wird.
SELECT * FROM v_risikoeinteilung LIMIT 20;

-- =========================================
-- Verteilung der Risikoklassen
-- =========================================

SELECT
    COALESCE(Risikoklasse, 'GESAMT')     AS Risikoklasse,
    COUNT(*) AS Anzahl,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM v_risikoeinteilung),
        2
    ) AS Anteil_Prozent,
    ROUND(AVG(loan_status) * 100, 2) AS Ausfallquote
FROM v_risikoeinteilung
GROUP BY Risikoklasse WITH ROLLUP;

-- Feststellung:
-- Die Grenzwerte wurden direkt aus den Ausfallquoten
-- der Analyse in Aufgabe 1 abgeleitet – sie sind datenbasiert begründet 
-- und nicht willkürlich gesetzt.

-- Aufgabe 1 Abfragen:
-- 2. Kredite mit loan_percent_income > 0.5
-- Die zeigte 70–100% Ausfallquote bei Krediten über 50% Einkommensanteil.

-- 3.1. Stimmt die Risikoabstufung von A nach G (loan_grade D–G, loan_grade C)? 
-- Die zeigte den Sprung von C (20,74%) auf D (59,03%) — ab da fällt mehr als jeder zweite Kredit aus.
-- C ist die Grenzklasse direkt vor dem Sprung.
-- 3.2 Wurden frühere Zahlungsausfälle (Vorausfälle) bei der Grade-Vergabe (Bonitätsbewertung) berücksichtigt (cb_person_default_on_file)?
-- Vorausfälle konzentrieren sich auf Klassen C–G
-- 4.1 Ausfallquoten nach Kreditzweck (DEBTCONSOLIDATION)
-- Höchste Ausfallquote aller Kreditzwecke mit 28,59%.
-- 4.2. Ausfallquoten nach Wohnsituation (Rent)
-- RENT mit 31,57% vs. OWN mit 7,47%.

-- Die Grenzwerte bilden damit die Realität des Portfolios ab.

-- Hohes Risiko:     15,63 % → Ausfallquote 61,68 %
-- Mittleres Risiko: 54,92 % → Ausfallquote 19,16 %
-- Niedriges Risiko: 29,45 % → Ausfallquote  5,62 %

-- 15,63 % in der höchsten Risikogruppe –
-- die Kreditvergabe wird nicht übermäßig eingeschränkt.
-- Die Bank bleibt handlungsfähig.

-- 29,45 % in der niedrigsten Gruppe mit 5,62 % Ausfallquote –
-- das Risiko wird hier nicht unterschätzt.

-- Die Verteilung ist ausgewogen und berücksichtigt
-- sowohl das Geschäftsinteresse der Bank als auch
-- eine angemessene Risikosteuerung.


-- =====================================================
-- Fazit Aufgabe 2 und Schlußfolgerung
-- =====================================================

-- Ausgangspunkt war die Frage: Welche Kreditnehmer
-- sind riskant – und wie riskant genau?

-- Die Grenzwerte habe ich nicht willkürlich gesetzt.
-- Jeder Faktor ist direkt aus einer Abfrage
-- in Aufgabe 1 abgeleitet und durch konkrete
-- Ausfallquoten aus dem Datensatz belegt.

-- Die stärksten Risikofaktoren sind eindeutig:
-- Einkommensbelastung über 50 % des Jahreseinkommens
-- mit Ausfallquoten zwischen 70 % und 100 %,
-- sowie Bonitätsklassen D bis G
-- mit Ausfallquoten zwischen 59 % und 98 %.

-- Trifft einer dieser Faktoren zu, reicht das allein
-- für die Einstufung als hohes Risiko.

-- Faktoren wie Wohnsituation (RENT: 31,57 %),
-- Kreditzweck (DEBTCONSOLIDATION: 28,59 %),
-- Bonitätsklasse C (20,74 %) und frühere Zahlungsausfälle
-- erhöhen das Risiko spürbar, sind aber allein kein
-- Ausschlusskriterium. Sie fließen daher als mittlere
-- Risikofaktoren in die Einteilung ein.

-- Die Verteilung halte ich für ausgewogen
-- und im Sinne der Bank:
-- Mit 15,63 % in der höchsten Risikogruppe wird die
-- Kreditvergabe nicht unverhältnismäßig eingeschränkt –
-- die Bank bleibt handlungsfähig und kann weiterhin
-- den Großteil der Kreditanfragen bedienen.
-- Mit 5,62 % Ausfallquote in der niedrigsten Gruppe
-- wird das Risiko dort nicht unterschätzt –
-- die Grenzwerte sind nicht zu großzügig gesetzt.

-- Was mich an diesem Ergebnis überzeugt:
-- Die Ausfallquoten der drei Gruppen trennen sich
-- klar voneinander – 5,62 %, 19,16 %, 61,68 %.
-- Das zeigt, dass die gewählten Faktoren tatsächlich
-- zwischen risikoarmen und risikoreichen Kreditnehmern
-- unterscheiden und keine willkürliche Kategorisierung
-- darstellen.

-- Für den Vorstand:
-- Das Modell baut auf den Erkenntnissen aus Aufgabe 1 auf und ermöglicht eine
-- strukturierte Bewertung des Ausfallrisikos von Kreditnehmern, indem es
-- auffällige Kreditnehmer frühzeitig sichtbar macht.

-- Die Risikogruppierung unterstützt insbesondere
-- die Überwachung von Kreditnehmern mit hoher
-- Einkommensbelastung sowie schwachen
-- Bonitätsbewertungen.

-- Genau diese Gruppen haben in der Analyse
-- die höchsten Ausfallquoten gezeigt und
-- stellen die größten Risikotreiber im
-- Kreditportfolio dar.






