# Matlab:

## Schnittstelle PC / Board

### DE1-SoC
Der Datentransfer zum DE1-SoC Board baut auf SSH auf. 

1. Datentransfer zum Board: `ttd` (Transfer To Device)
    - `scp input.dat root@192.168.0.123:/ocl_data`
    - Über SCP (Secure Copy) wird eine Datei mit Lumnanzdaten auf das Board transferiert
    - Danach kann die Berechnung erfolgen
2. Ausführung auf dem Board `cmd` (Command), bestehend aus 3 Unterbefehlen:
    - `source ./init_opencl.sh` -- Initialisierung der OpenCL Umgebung
    - `aocl program /dev/acl0 lbp_ocl.aocx` -- Programmierung des FPGA mit dem kompilierten OpenCL Kernel
    - `./lbp_ocl_host input.dat 256 256 1` -- Ausführung des Hostprogramms mit Datei `input.dat`, Breite = `256`, Höhe = `256`, Radius = `1` 
    - Gesamtbefehl: `ssh root@192.168.0.123 "source ./init_opencl.sh;aocl program /dev/acl0 lbp_ocl.aocx;./lbp_ocl_host input.dat 256 256 1"`
    - Ergebnis wird unter `input.dat.res` gespeichert
3. Datentransfer zum PC: `tth` (Transfer To Host)
    - `scp root@192.168.0.123:/ocl_data/input.dat.res input.dat.res`
    - Über SCP (Secure Copy) wird eine Datei mit Ergebnissen zurück transferiert. Enthalten sind: 
        - Kernelzeit (Reine Ausführungszeit)
        - Systemzeit (Kernelzeit + Datentransfer vom Hostprogramm zum Kernel)
        - LBP-Verarbeitete Bilddatei (Luminanzdaten)
    - Diese Daten werden zur weiteren Auswertung herangezogen.

### ZedBoard (TODO!! Subject to change!!)

Der Datentransfer zum ZedBoard baut auf UART auf. 
der PC ist in diesem Fall der Master, das Board das Slave, jeweils abgekürzt als *S* und *M*.

Folgende Kommandos werden interpretiert:
- `init`    (Initialisierung)
- `ack`     (Acknowledge)
- `ttd`     (Transfer To Device)
- `tth`     (Transfer To Host)
- `proc`    (Process)

1. Initialisierung `init`
    - M --> `init` --> S (Device wird initialisiert)
    - M <-- `ack`  <-- S (Host darf Daten übertragen)
2. Datentransfer zum Board `ttd` (Transfer To Device)
    Für jedes zu übertragende Byte: 
    - M --> `ttd` --> S
    - M <-- `ack` <-- S
    - M --> `xhi` --> S (Obere 8 bit der Spaltenadresse)
    - M <-- `ack` <-- S
    - M --> `xlo` --> S (Untere 8 bit der Spaltenadresse)
    - M <-- `ack` <-- S
    - M --> `yhi` --> S (Obere 8 bit der Zeilenadresse)
    - M <-- `ack` <-- S
    - M --> `ylo` --> S (Untere 8 bit der Zeilenadresse)
    - M <-- `ack` <-- S
    - M --> `dat` --> S (ein Datenbyte)
    - M <-- `ack` <-- S (Host darf erneut einen neuen Befehl ausführen)
3. Ausführung auf dem Board `proc` (Process)
    - M --> `proc` --> S 
    - M <-- `ack` <-- S (Verarbeitung begonnen)
    - ...
    - M <-- `ack` <-- S (Verarbeitung beendet)
4. Datentransfer zum PC: `tth` (Transfer To Host)
    Für jedes zu übertragende Byte: 
    - M --> `tth` --> S
    - M <-- `ack` <-- S
    - M --> `xhi` --> S (Obere 8 bit der Spaltenadresse)
    - M <-- `ack` <-- S
    - M --> `xlo` --> S (Untere 8 bit der Spaltenadresse)
    - M <-- `ack` <-- S
    - M --> `yhi` --> S (Obere 8 bit der Zeilenadresse)
    - M <-- `ack` <-- S
    - M --> `ylo` --> S (Untere 8 bit der Zeilenadresse)
    - M <-- `dat` <-- S (ein Datenbyte, Host darf erneut einen neuen Befehl ausführen)

# Umsetzung LBP in OpenCL
2 Varianten wurden entworfen. Beide wurden zuvor auf dem Rechner getestet (7700K, 32GB, GTX1080Ti)
## Kanonisch
- viele Gleitkomma Operationen
- round() auf GTX1080Ti ist fehlerhaft. Dadurch gab es sämtliche Speicherbereichsüberschreitungen. Ersetzt durch eine eigene Umsetzung.
- beliebige Anzahl an Samples
- beliebiger Radius (Gleitkomma)
- Interpolation, da der Radius beliebig sein kann
- Vorberechnung der Samplepunkte mit trigonometrischen Funktionen
- Entspricht (visuell!!) der Referenz von Ramesh Kumar
- **nicht Synthetisierbar**
    - Gleitkommaarithmetik und trigonometrische Funktionen
    - Sehr große generierte "schaltung"
    - Passt nicht auf das Cyclone V des DE1-SoC: 97% aller Logikzellen belegt
    - => Neuentwicklung des Kernels, reduktion auf das Wesentliche

## Synthetisierbar
- Keine Gleitkommaoperationen
- Anzahl Samples auf Wert 8 fixiert.
- Beliebiger ganzzahliger, diskreter Radius, z.B: (x = Samplepunkt, c = Zentrum)
    - Radius 1:
    x x x
    x c x
    x x x
    - Radius 2:
    0 0 x 0 0
    0 x 0 x 0
    x 0 c 0 x
    0 x 0 x 0 
    0 0 x 0 0 
    - Radius 3:
    x 0 0 x 0 0 x
    0 0 0 0 0 0 0
    0 0 0 0 0 0 0
    x 0 0 c 0 0 x
    0 0 0 0 0 0 0
    0 0 0 0 0 0 0
    x 0 0 x 0 0 x
- **synthetisierbar**
    - Passt auf das Cyclone V des DE1-SoC: 19-20% aller Logikzellen belegt
    - Es können mehrere Kernel synthetisiert werden
    - Ausführungszeit für ein 256x256 Bild
        - 1 Kernel: ~49s
        - 4 Kernel: ~56s
        - => Speicherprobleme (konkurrente Zugriffe)

# Umsetzung LBP in VHDL

- Kumar's Lösung ist nur für Simulation gedacht.
- Viele nicht synthetisierbare Konstrukte
- Keine in Hardware verwertbare Infrastruktur für Eingabe/Ausgabe

## Grundlagen
- LBP Operator
    - Verrechnet ein Datenfenster
- LBP Kernel
    - Verarbeitet Daten in einem Speicherbereich
- LBP Kernel Array
    - Mehrere Kernel
- Processing unit
    Hauptrecheneinheit, beinhaltet:
    - Eingabepuffer
    - Ausgabepuffer
    - Kernel array
- Processing unit input memory
    - Eingabepuffer, Speicherbereich für das komplette Eingangsbild
    - Block-RAM basiert
    - Multi-port fähig
- Processing unit output memory
    - Ausgabepuffer, Speicherbereich für das verarbeitete Ausgangsbild
    - Block-RAM basiert
    - Bedingt Multi-port fähig
- Control unit
    - Hauptsteuereinheit
    - Zuständig für Datentransfers und Steuerung vom Host
    - Implementiert das oben beschriebene (Matlab -> ZedBoard) Protokoll
- Host interface UART (PHY)
    - UART Schnittstelle
- Avalon Schnittstelle
    - Kommunikation mit dem ARM Prozessor über die Avalon / AXI Schnittstelle

## DE1-SoC
- Für das DE1-SoC ist der Aufwand enorm:
    - Avalon MM Schnittstelle, damit eine Anbindung an den ARM Hauptprozessor stattfinden kann
    - Linux-Kernelmodul als Treiber
    - Userspace-Programm für den eigentlichen Datentransfer (Ansteuerung vom Host via SSH, vgl. dazu DatenTransfer für OpenCL)
- Es wurde ein Qsys-Projekt erstellt
    - lbp-modul mit Avalon Schnittstelle als IP-Core
    - Hard Processor System IP-Core
- Probleme
    - Aufgrund von Fehlern bei der Umsetzung des LBP-Moduls nicht synthetisierbar
    - Potentielle Probleme mit dem Betriebssystem / Treiber falls zur Laufzeit das FPGA umprogrammiert wird (Wechsel zwischen VHDL / OpenCL Lösung)    
    - Auf eine weitere Entwicklung wurde verzichtet und ein reiner Hardware-basierter Ansatz auf Basis des ZedBoards (um Rekonfiguration bei der Präsentation zu vermeiden) mit UART-Schnittstelle weiterverfolgt

## ZedBoard
- UART Schnittstelle zum Hostrechner
- Keine Avalon Schnittstelle
- Weitere Komponenten wie oben geschildert.
- Simulation nicht zu 100% erfolgreich.


