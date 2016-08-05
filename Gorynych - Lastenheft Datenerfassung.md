# Stichpunkte Lastenheft

## Überblick über das Projekt:
"gorynych" ist eine Abstraktionsschicht zur Durchführung von beschleunigten Berechnungen auf heterogenen Systemen.
Mit diesem Framework ist es möglich, ein einziges Mal den Algorithmus zu implementieren und von der automatischen Abbildung
auf verschiedene Prozessor-Fähigkeiten zu profitieren.

Ohne "gorynych" müsste man für jeden Prozessor-Fähigkeit den Algorithmus neu schreiben,
dies hat erhöhte Entwicklungs- und Wartungskosten zur Folge.

Im Groben unterscheidet sich die Entwicklung mit diesem Framework nicht von der Entwicklung mit purem C++, mit einer Außnahme:
- Das Framework ist auf größere Datenmengen ausgelegt und bietet entsprechende Funktionen an, um Datenfelder abzuarbeiten. Bei der Zusammenrechnung von zwei einzelnen Zahlen profitiert man nicht.
- Die üblichen Konditionsoperatoren sind i.d.R nicht anwendbar, bei der Entwicklung muss man sich an die Sprunglose Arithmetik halten.


### Beispiel für eine Addition MIT "gorynych":

Dieser Block wird dann entsprechend in alle von "gorynych" unterstützen Prozessor-Fähigkeiten umgesetzt.

```C++
VECTORIZED vreal add(const vreal &a, const vreal &b)
{
  return a + b;
}
```

### Beispiel für eine Addition OHNE "gorynych":

#### SSE:

```C++
__m128 add(__m128 &a, __m128 &b)
{
  return _mm_add_ps(a, b);
}
```

#### AVX:

```C++
__m256 add(__m256 &a, __m256 &b)
{
  return _mm256_add_ps(a, b);
}
```

#### OpenCL:

```OpenCL
__kernel void add (__global const float* a, __global const float* b, __global float* result, const int num)
{
   const int idx = get_global_id(0);

   if (idx < num)
      res[idx] = src_a[idx] + src_b[idx];
}
```


An diesem sehr einfachen beispiel sieht man bereits dass man ohne Gorynych für jede
Fähigkeit andere Funktionen oder sogar Programmiersprachen nehmen und denselben Algorithmus
mehrmals umsetzen und warten muss, was dem DRY-Prinzip widerspricht.

## Ist Zustand:
Aktuell unterstützt "gorynych" x86-64 CPU Befehlssätze wie
* x87
* SSE2
* SSE3
* SSSE3
* SSE4.1/SSE4.2
* FMA3/FMA4
* AVX1 (unvollständig)
* AVX2
Aktuell bietet "gorynych" folgende Basisfunktionen:
* arithmetische Operationen
* logische Operationen
* lineare Algebra
* Rundung
* Basisfunktionen wie absolutwert, minimum, maximum, etc.

## Soll Zustand:
* Mit "gorynych" erstellte Projekte sollen auch auf hochparallelen, modernen Grafikprozessoren lauffähig sein
* Diese Projekte sollen möglichst ohne Anpassungen lauffähig sein.
* Dies bedeutet, dass die vorhandene Schnttstelle auch für GPGPU implementiert werden soll.

## Funktionale Anforderungen:
* Es müssen alle aktuell unterstützten Funktioen auch für GPU's umgesetzt werden.

## Nicht-funktionale Anforderungen
### Benutzbarkeit
* Für den Endanwender des Frameworks muss dieses logisch schlüssig und nachvollziehbar sein
* Eine entsprechende Dokumentation wird erweitert bzw. erstellt.
### Wartbarkeit:
* Die Frameworkarchitektur muss weiterhin modular bleiben.
### Zuverlässigkeit:
* Die angebotene Funktionalität wird im TDD-Verfahren entwickelt und validiert.
* Für jede Funktion sind entsprechende Unit-Tests notwendig.
