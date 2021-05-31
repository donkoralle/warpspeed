# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#    WarpSpeed-Diagramm basteln
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Hinweise:
# * Code wurde auf einem Win10-System mit R version 4.0.3 (2020-10-10) -- "Bunny-Wunnies Freak Out" erstellt
# * Code wurde für einen Aufruf über die Windows-Eingabeaufforderung & Rscript.exe ausgelegt (v.a. print), um das tägliche Ausführen zu erleichtern 
# 28.04.21: Änderung des Hinweistextes zur Einmeldequote im e-Impfpass: Übernahme der Formulierung von https://www.data.gv.at/katalog/dataset/4312623f-2cdc-4a59-bea5-877310e6e48d
# 31.05.21: Änderung Output-Device auf "cairo" um bei Abbildungen Antialiasing zu verbessern


# ==== Let's roll ====

library(tidyverse)
library(scales)
library(extrafont)
library(RColorBrewer)
library(RSQLite)
library(lubridate)

setwd("~/1___Work/R/corona_impfungen/___git_warpspeed/")

ausgangsjahr <- 2021
# Anzahl der Tage in Diagramm 1 & 2
myTimewindow <- 14
Immunisierungsquote <- 0.7
myDB <- "Data/git_impfen_v2.db"

# Pfade zu den Output-Files setzen
myCSVexportFile <- "Data/timeline_extrapol.csv"
myDia1Path <- "Output/immunquote/"
myDia2Path <- "Output/"


#### BLOCK 1: Tagesdaten Ministerium abrufen & lokal ablegen ___________________

# ==== tagesaktuelle Daten vom BMSGPK laden ====

# https://info.gesundheitsministerium.at/opendata.html
# Aktualisierung: Die Aktualisierung erfolgt täglich gegen 14 Uhr (Stand 05.02.21 - https://www.data.gv.at/katalog/dataset/589132b2-c000-4c60-85b4-c5036cdf3406)
# Update 26.02.21: neuer Datensatz des Gesundheitsministeriums ist:
# https://info.gesundheitsministerium.gv.at/data/timeline-eimpfpass.csv

print("\n### Daten abrufen ... ###\n")

direktImport <- as_tibble(read.csv2("https://info.gesundheitsministerium.gv.at/data/timeline-eimpfpass.csv",
                                    encoding = "UTF-8",
                                    dec = "."))

# Sicherheitshalber: UTF BOM ausbessern (Why-oh-why muss das sein?) & Datum umwandeln
if(any(grepl("X.U.FEFF.", colnames(direktImport)))){

  print("\n### ... UTF-8 BOM erkannt & bereinigt. ###\n")
  
  direktImport <- direktImport %>%
    rename(., Datum = X.U.FEFF.Datum)
}

# Update 26.02.21: Datenstruktur muss nachgebessert werden
conn <- dbConnect(SQLite(), myDB)
# Spaltennamen aus lokaler DB abrufen
cols2select <- dbListFields(conn, "timeline")
direktImport <- direktImport %>%
  select(all_of(cols2select))

# Datum in Date umwandeln
direktImport <- direktImport %>%
  mutate(Datum = as.Date(Datum))
# glimpse(direktImport)


# ==== Db-Verbindung erstellen ====

# max. Datum aus DB abfragen
max.DBdatum <- dbGetQuery(conn, "SELECT MAX(Datum) FROM timeline")[1,1]

paste("\n### Aktuellste Einträge in DB vom:",
      max.DBdatum,
      "###\n")

# ausfiltern der in die DB zu übertragenden Records
new.data <- direktImport %>%
  filter(Datum > max.DBdatum)

# Logische Variable für Update der lokalen DB
TriggerLocalUpdate <- nrow(new.data) == 0

# ==== abgerufende Daten lokal ablegen ====

if(TriggerLocalUpdate){
  
  # ==== Nebenast: keine neue Daten & exit ====

  print("\n### KEINE neuen Daten gefunden. ###\n")
  
} else {
  
  # ==== Hauptast: Daten schreiben ====
  
  print("\n### NEUE Daten gefunden: ###\n")
  
  new.data
  # sollten 10 Records je Tag sein
  
  # on-exit-Konversion des Datums
  new.data <- new.data %>%
    mutate(Datum = as.character(Datum))
  
  # bevor: n vor dem Update ermitteln
  paste("\n### n Records vor DB-Update:",
        dbGetQuery(conn, "SELECT COUNT(*) FROM timeline"),
        "###\n"
  )
  # neue Records in DB schreiben
  dbWriteTable(conn,"timeline", new.data, append = TRUE)
  # danach: n nach Update ermitteln
  paste("\n### n Records nach DB-Update:",
        dbGetQuery(conn, "SELECT COUNT(*) FROM timeline"),
        "###\n"
  )
  
  #### ENDE BLOCK 1 ____________________________________________________________ 
  
  
  #### BLOCK 2: Neue Indikatoren berechnen & lokal ablegen _____________________
  
  # ==== Daten aus lokaler DB holen ====
  
  # max. Datum aus DB abfragen
  max.DBdatum <- dbGetQuery(conn, "SELECT MAX(Datum) FROM timeline")[1,1]
  max.DBdatumMinus14plus6 <- as.Date(max.DBdatum)-(myTimewindow+6)
  
  # SQL-Statement zur Datenabfrage basteln
  # Update 26.02.21: BundeslandID 0 = "keine Zuordnung" ausfiltern
  sql_1 <- paste("SELECT * FROM timeline WHERE Datum BETWEEN date('", 
                 max.DBdatumMinus14plus6, 
                 "') and date('", 
                 max.DBdatum, 
                 "') AND BundeslandID < 10 AND BundeslandID > 0 ORDER BY Datum, BundeslandID",
                 sep = "")

  # DB-Daten abfragen & on-entry-Datumskonversion & Konversion bula
  raw.daten <- dbGetQuery(conn, sql_1) %>%
    as_tibble(.) %>%
    mutate(Datum = as.Date(Datum),
           bula = as_factor(Name))

    
  # ==== Div. Indikatoren ermitteln ====
  
  print("\n### Indikatoren ermitteln ###\n")
  
  sel.daten <- raw.daten %>%
    select(Datum,
           bula,
           Bevölkerung,
           EingetrageneImpfungen,
           Teilgeimpfte,
           Vollimmunisierte) %>%
    arrange(desc(Datum)) %>%
    mutate(Datum_minus7 = lead(Datum, n = 9*7),
           vollimmun_minus7 = lead(Vollimmunisierte, n = 9*7),
           delta_vollimm = Vollimmunisierte - vollimmun_minus7,
           vollimm_jeTag_last7 = delta_vollimm / 7,
           DeltaNonImmBev = round(Bevölkerung * Immunisierungsquote, 0) - Vollimmunisierte,
           dauerDeltaNonimmBev = round(DeltaNonImmBev/vollimm_jeTag_last7, 0),
           TagErreichenImmunquote = Datum + dauerDeltaNonimmBev,
           ImpfquoteAct = Vollimmunisierte / Bevölkerung
    )
  
  # sicherheitshalber: Es könnten Divisionen durch 0 aufgetreten sein (v.a. am Beginn der Zeitreihe) > Inf durch NA ersetzen
  sel.daten <- sel.daten %>% 
    mutate_if(is.numeric, list(~na_if(., Inf))) %>% 
    mutate_if(is.numeric, list(~na_if(., -Inf))) %>%
    # RÜckläufige Entwicklung der Immunisierten abfagen und als NA setzen
    mutate(dauerDeltaNonimmBev = replace(dauerDeltaNonimmBev, dauerDeltaNonimmBev < 0, NA)) %>%
    mutate(TagErreichenImmunquote = replace(TagErreichenImmunquote, TagErreichenImmunquote < "2021-01-01", NA))
  
  
  # ==== Indikatoren in lokaler DB & als CSV ablegen  ====
  
  max.DBextrapolDatum <- dbGetQuery(conn, "SELECT MAX(Datum) FROM timeline_extrapol")[1,1]  

  # abzulegende extrapolierten Daten ermitteln & für Export vorbereiten
  new.data.extrapol <- sel.daten %>%
    filter(Datum > max.DBextrapolDatum) %>%
    mutate_if(lubridate::is.Date, ~ as.character(.))
  glimpse(new.data.extrapol)
  
  # Checken, ob Daten abgelegt werden müssen
  if(nrow(new.data.extrapol) == 0){
    print("\n ### Keine neuen Indikatoren lokal abzulegen ###\n")
  }else{
    print("\n### NEUE Indikatoren lokal abzulegen ###\n")
    
    # Daten ablegen in DB
    dbWriteTable(conn,"timeline_extrapol", new.data.extrapol, append = TRUE)
    
    # Table timeline_extrapol noch als CSV-File exportieren
    myCSVexportFrame <- dbGetQuery(conn, "SELECT * FROM timeline_extrapol ORDER BY Datum DESC")
    write.csv2(myCSVexportFrame, myCSVexportFile, fileEncoding = "UTF-8")
  }
  
  #### ENDE BLOCK 2 ____________________________________________________________ 
  
  
  #### BLOCK 3: Diagramme (1 & 2) erzeugen & ablegen ___________________________
  
  # ==== Vis-Daten erzeugen ====
  
  print("\n### Digramme erstellen ... ###\n")
  
  # Filtern, um NA zu beseitigen über Datum da ja nur 14 Tage dargestellt werden sollen
  maxVisDatum <- max(sel.daten$Datum)-myTimewindow
  vis.daten1 <- sel.daten %>%
    filter(Datum > maxVisDatum)
  
  
  # ==== Visualisieren Diagramm 1: Impfquoten aktuell ====
  
  myTitle <- paste("Anteil der Vollimmunisierten an der Gesamtbevölkerung")
  mySubTitle <- NULL
  myCaption <- paste("Stand: ",
                     max.DBdatum,
                     "\nDatenquelle: BMSGPK, Österreichisches COVID-19 Open Data Informationsportal (https://www.data.gv.at/covid-19)",
                     "\nDie Einmeldequote in den e-Impfpass beträgt aktuell noch nicht 100%.",
                     sep = "")
  yLabel <- "Anteil Vollimmunisierte [%]\n"
  # Y-Achse auf 2.5%
  myYincrement <- 0.025
  myMaxY <- ceiling(max(vis.daten1$ImpfquoteAct) / myYincrement) * myYincrement

  ggplot(vis.daten1, aes(x = Datum, y = ImpfquoteAct)) +
    geom_line(aes(color = bula), size = 1.1) +
    labs(x = "\nDatum", 
         y = yLabel,
         title = myTitle,
         subtitle = mySubTitle,
         caption = myCaption) +
    theme_gray() +
    theme(text = element_text(size=12, family="Calibri"),
          legend.text = element_text(size=10),
          legend.title = element_text(size=10, face = "bold"),
          legend.key.size = unit(1, 'lines'),
          plot.title = element_text(size=14, hjust = 0.5, face= "bold",
                                    margin=margin(7,0,10,0)),
          plot.subtitle = element_text(hjust = 0.5,
                                       margin=margin(5,0,10,0)),
          plot.caption = element_text(size=7, hjust = 0, face= "italic",
                                      margin=margin(14,0,0,0)),
          axis.title = element_text(face = "bold"),
          axis.text.x = element_text(angle = 90, vjust = 0.5),
          axis.ticks.length=unit(.15, "cm"),
          panel.border = element_rect(color = "black", fill = NA),
          panel.grid.minor.y = element_line(linetype = "solid")
    ) +
    scale_color_brewer(palette = "Spectral", name = "Bundesländer") +
    scale_x_date(date_breaks = "2 days", date_labels = "%d.%m") +
    scale_y_continuous(labels = scales::percent_format(accuracy = 0.1,
                                                       decimal.mark = ","),
                       limits = c(0, myMaxY)) +
    coord_cartesian(xlim = c(min(vis.daten1$Datum), max(vis.daten1$Datum)))

  # Diagramm 1 speichern
  myFilename <- paste(myDia1Path, 
                      max.DBdatum, 
                      "_immunquote.png",
                      sep = "")
  ggsave(myFilename, 
         width = 8, height = 5, 
         dpi = 200, units = "in",
         type = "cairo")  
  
  print("\n### Diagramm 1 gespeichert ###\n")  
  
  
  # ==== Visualisieren Diagramm 2: Glaskugel ====
  
  myTitle <- paste("Wann würden die Bundesländer eine Impfquote von",
                   Immunisierungsquote*100,
                   "% erreichen?")
  mySubTitle <- "(ausgehend von den Vollimmunisierungen der jeweils letzten sieben Tage)"
  myCaption <- paste("Stand: ",
                     max.DBdatum,
                     "\nDatenquelle: BMSGPK, Österreichisches COVID-19 Open Data Informationsportal (https://www.data.gv.at/covid-19)",
                     "\nDie Einmeldequote in den e-Impfpass beträgt aktuell noch nicht 100%.",
                     sep = "")
  yLabel <- paste("Impfquote (",
                  Immunisierungsquote*100,
                  " %) erreicht im Jahr ...\n",
                  sep=""
                  )
  
  # X-Dimension Visualisierung gesamt
  # Impfbeginn AUT: 27.12.20 plus 3 Wochen > 17.01.21
  myVisXstart <- as.Date("2020-12-27")+(3*7)
  myVisXend <- max(vis.daten1$Datum)+10
  # Y-Dimension Visualisierung gesamt
  myVisYmin <- as.Date("2020-01-01")
  myVisYmax <- as.Date("2029-12-31")
  # y Variablen für die Hotzones (heuer & nächstes Jahr)
  myThisYearMin <- as.Date("2021-01-01")
  myThisYearMax <- myThisYearMin + months(12) - days(1)
  myNextYearMin <- myThisYearMin + months(12)
  myNextYearMax <- myNextYearMin + months(12) - days(1)
  # Hotozone-Koordinaten
  hotzone.coord <- data.frame(xmin = c(myVisXstart, myVisXstart),
                              xmax = c(myVisXend, myVisXend),
                              ymin = c(myThisYearMin, myNextYearMin),
                              ymax = c(myThisYearMax, myNextYearMax),
                              zonename = c("dieses Jahr", "nächstes Jahr"))
  
  ggplot(vis.daten1, aes(x = Datum, y = TagErreichenImmunquote)) +
    geom_line(aes(color = bula), size = 1.1) +
    labs(x = "\nDatum", 
         y = yLabel,
         title = myTitle,
         subtitle = mySubTitle,
         caption = myCaption) +
    theme_gray() +
    theme(text = element_text(size=12, family="Calibri"),
          legend.text = element_text(size=10),
          legend.title = element_text(size=10, face = "bold"),
          legend.key.size = unit(1, 'lines'),
          plot.title = element_text(size=14, hjust = 0.5, face= "bold",
                                    margin=margin(7,0,0,0)),
          plot.subtitle = element_text(hjust = 0.5,
                                    margin=margin(5,0,10,0)),
          plot.caption = element_text(size=7, hjust = 0, face= "italic",
                                      margin=margin(14,0,0,0)),
          axis.title = element_text(face = "bold"),
          axis.text.x = element_text(angle = 90, vjust = 0.5),
          axis.ticks.length=unit(.15, "cm"),
          panel.border = element_rect(color = "black", fill = NA),
          panel.grid.minor.y = element_line(linetype = "solid")
    ) +
    scale_color_brewer(palette = "Spectral", name = "Bundesländer") +
    scale_x_date(date_breaks = "2 days", date_labels = "%d.%m") +
    scale_y_date(minor_breaks = "1 years") +
    geom_rect(hotzone.coord,
              mapping = aes(xmin=xmin,ymin=ymin,xmax=xmax,ymax=ymax,fill=zonename),
              alpha=c(0.3, 0.1),
              color=c("red", NA),
              inherit.aes=FALSE) +
    scale_fill_manual(name="Referenzzeiträume", 
                      labels = c("nächstes Jahr (2022)", "dieses Jahr (2021)"),
                      values=alpha(c("red","red"), c(0.1, 0.3))) +
    coord_cartesian(ylim = c(myVisYmin, myVisYmax),
                    xlim = c(min(vis.daten1$Datum), max(vis.daten1$Datum)))
  
  
  # ==== Diagramm speichern ====
  myFilename <- paste(myDia2Path, 
                      max.DBdatum, 
                      "_warpspeed.png",
                      sep = "")
  ggsave(myFilename, 
         width = 8, height = 5, 
         dpi = 200, units = "in",
         type = "cairo")  
  
  print("\n### Diagramm 2 gespeichert ###\n")
  
  #### ENDE BLOCK 3 ____________________________________________________________ 
}

# DB Verbindung lösen
dbDisconnect(conn)

# finales Feedback
print("\n### Ende ###")






