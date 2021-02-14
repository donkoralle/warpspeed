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

## Der R-Code zur Diagrammerstellung

Eine kurze Vorstellung des R-Codes folgt in Kürze.

## Die damit erzeugten Zeitreihendaten

Ausgangspunkt für die Diagrammerstellung sind die Daten des des [BMSGPKs](https://www.sozialministerium.at) zum [„Zeitverlauf der COVID19-Impfungen in Österreich“](https://www.data.gv.at/katalog/dataset/zeitverlauf-der-covid19-impfungen-in-osterreich-national-und-bundeslander), welche dankenswerterweise unter einer CC BY Lizensierung zur Verfügung gestellt werden. Eine kurze Vorstellung der daraus abgeleiteten Zeitreihendaten folgt in Kürze.