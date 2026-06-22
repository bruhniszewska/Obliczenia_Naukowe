# Obliczenia naukowe

## Zawartość Projektu i Metodologia Badawcza

Projekt podzielony jest na dwa główne nurty badawcze:

### Nurt 1: Przestrzenny Automat Komórkowy (Symulacja i Kalibracja RK4)
Główna część aplikacji umożliwia badanie wpływu przestrzeni (w tym bariery w postaci rzeki) na dynamikę populacji.
* Kompletny kod symulatora, algorytmów przestrzennych oraz interfejsu GUI znajduje się wewnątrz pliku **`symulator.ipynb`**.
* Wygenerowane przez automat serie czasowe są bezpośrednio wewnątrz notebooka przekazywane do modułu kalibracyjnego. Moduł ten za pomocą napisanego od zera algorytmu Rungego-Kutty (RK4) przeprowadza próby dopasowania teoretycznego układu równań różniczkowych do stochastycznych danych z siatki. 

### Nurt 2: Kalibracja Modeli Teoretycznych na Danych Rzeczywistych (Isle Royale)
W repozytorium znajdują się osobne skrypty analityczne, które służą do walidacji klasycznych modeli ekologicznych na podstawie rzeczywistych, trwających kilkadziesiąt lat pomiarów populacji wilków i łosi na wyspie Isle Royale (`isle-royale.csv`):

* **`Lotka-Volterra.jl`** – Implementacja podstawowego, deterministycznego modelu ofiara-drapieżnik. Skrypt korzysta z pakietu `DifferentialEquations.jl` oraz narzędzi optymalizacyjnych do znalezienia makroskopowych współczynników (narodzin, śmierci, interakcji) najlepiej opisujących historyczne trendy ekologiczne.
* **`Rosenzweig-MacArthur.jl`** – Rozszerzenie analizy o zaawansowany model uwzględniający pojemność środowiska ($K$) dla ofiar oraz funkcję odpowiedzi drapieżnika typu Holling II (limitacja prędkości konsumpcji). Model ten znacznie lepiej oddaje nieliniowości i ograniczenia zasobowe prawdziwego ekosystemu.

## Struktura Projektu

Po optymalizacji pod kątem niezawodności i łatwości uruchomienia przez użytkownika, projekt składa się z następujących plików:

* **`Lotka-Volterra.jl`** – Skrypt optymalizacyjny dla klasycznego modelu dopasowywanego do danych rzeczywistych.
* **`Rosenzweig-MacArthur.jl`** – Skrypt optymalizacyjny dla zaawansowanego modelu dopasowywanego do danych rzeczywistych.
* **`isle-royale.csv`** – Historyczna baza danych populacji łosi i wilków z wyspy Isle Royale.
* **`symulator.ipynb`** – Główny plik projektu stanowiący kompletne środowisko badawcze. Zawiera definicje struktur danych, pełną logikę automatu komórkowego, algorytm RK4, funkcje kalibracyjne oraz interaktywny pulpit sterowniczy (GUI) oparty na bibliotece `GLMakie` i `Plots`.
* **`Project.toml` & `Manifest.toml`** – Pliki środowiska Julii, gwarantujące zgodność wersji bibliotek (`GLMakie`, `Plots`, `BenchmarkTools`, itp.).

## Instrukcja Instalacji i Przygotowania Środowiska

Aby uruchomić symulator, na komputerze musi być zainstalowana **Julia** (zalecana wersja 1.10 lub nowsza) oraz edytor obsługujący pliki `.ipynb` (zalecane **VS Code** z rozszerzeniami "Julia" oraz "Jupyter").

1. Sklonuj lub pobierz to repozytorium do jednego folderu.
2. Otwórz edytor VS Code i wybierz `File -> Open Folder...`, wskazując ten folder.
3. Otwórz plik **`symulator.ipynb`**.

## Jak Uruchomić Symulator?

Wystarczy po kolei uruchomić komórki w pliku symulator.ipynb


