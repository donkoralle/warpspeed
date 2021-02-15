# warpspeed

Dieses Repo beinhaltet den R-Code und die damit erzeugten Zeitreihendaten zur Messung und Darstellung der Corona-Impfgeschwindigkeiten in den österreichischen Bundesländern.

## Worum es inhaltlich geht ...

... wird in diesem Blog-Beitrag kurz dargelegt: https://kamihoeferl.at/2021/02/10/oesterreich-impft-alles-warp-speed-oder-was/

## ... und was dabei herauskommt

Ziel des R-Codes ist es, folgende zwei Abbildung tagesaktuell zu erstellen:

![Anteil der Vollimmunisierten je Bundesland](/Output/immunquote/2021-02-14_immunquote.png)

![Zeitliche Distanzen der österreichischen Bundesländer bis zum Erreichen einer Impfquote von 70 %](/Output/2021-02-14_warpspeed.png)

Auf dem Weg dahin werden die im Ordner "Data" abgelegten Zeitreihendaten ermittelt.

Laufend aktualisierte Fassungen dieser Abbildung poste ich unter den Tags #österreichimpft #warpseed auf [Twitter](https://twitter.com/search?q=österreichimpft%20warpspeed).

## Der R-Code

Zur Erstellung der Abbildungen werden drei Blöcke durchlaufen:

* **Block 1: Datenabfrage**  
Die vom BMSGPK angebotenen Daten werden abgerufen, aufbereitet und lokal in einer SQLite Datenbank (Table "timeline") abgelegt.
* **Block 2: Neue Variablen berechnen und ablegen**  
Ausgehend von den abgefragten Daten werden folgende Variablen berechnet:
  + Datum_minus7Datum_minus7: Bezugsdatum minus sieben Tage
  + vollimmun_minus7: Anzahl Vollimmunisierte vor sieben Tagen
  + delta_vollimm: Differenz Anzahl Vollimmunisierte Bezugsdatum zu vor sieben Tagen
  + vollimm_jeTag_last7: tägliche neu hinzugekommene Vollimmunisierte in den letzten sieben Tagen
  + DeltaNonImmBev: noch zu immunisierende Bevölkerung zum Bezugsdatum
  + dauerDeltaNonimmBev: Dauer in Tagen zur Vollimmunisierung von DeltaNonImmBev
  + TagErreichenImmunquote: Bezugsdatum plus dauerDeltaNonimmBev
  + ImpfquoteAct: Anteil der Vollimmunisierten an der Bevölkerung zum Bezugsdatum
  Die berechneten Variablen werden im Table "timeline_extrapol" sowie als CSV-Datei lokal abgelegt.
* **Block 3: Visualisierung**  
Die im Block 2 erstellten Daten werden danach graphisch dargestellt und als PNG-Dateien im Ordner "Output" lokal abgelegt.

## Die damit erzeugten Zeitreihendaten

Ausgangspunkt für die Diagrammerstellung sind die Daten des des [BMSGPKs](https://www.sozialministerium.at) zum [„Zeitverlauf der COVID19-Impfungen in Österreich"](https://www.data.gv.at/katalog/dataset/zeitverlauf-der-covid19-impfungen-in-osterreich-national-und-bundeslander), welche dankenswerterweise unter einer CC BY Lizenzierung zur Verfügung gestellt werden.
Die vom BMSGPK abgefragten Daten werden in einer lokalen SQLite Datenbank (Table "timeline") abgelegt. Die Datenbank findet sich im Ordner ["Data"](https://github.com/donkoralle/warpspeed/tree/main/Data). Die auf diesen Daten aufbauenden Berechnungen werden im Table "timeline_extrapol" abgelegt. Dieser Table wird bei jeder Aktualisierung auch als CSV-Datei im Ordner "Data" abgelegt.

## Die damit erzeugten Abbildungen

... finden sich als PNG-Dateien im Ordner ["Output"](https://github.com/donkoralle/warpspeed/tree/main/Output). Toplevel liegen die Abbildungen zu den zeitlichen Distanzen, im Unterordner ["immunquote"](https://github.com/donkoralle/warpspeed/tree/main/Output/immunquote) werden die Abbildungen zu den Anteilen der Vollimmunisierten abgelegt.
