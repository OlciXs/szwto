# Odkrywca Zabytków

Aplikacja do odkrywania i kolekcjonowania zabytków **Wrocławia** (~1400 obiektów z Wikidata, ~1000 ze zdjęciem).
Zabytek można odznaczyć tylko na miejscu – promień zależy od obiektu (40–400 m, geofencing sprawdzany po stronie backendu).

| Warstwa | Technologia |
|---|---|
| Frontend | Flutter (Dart), `flutter_map` + OpenStreetMap, `geolocator` |
| Backend | NestJS (TypeScript), JWT, `class-validator`, `@nestjs/event-emitter` |
| Baza danych | PostgreSQL (lokalnie lub Neon) + Prisma ORM |
| Dane | Wikidata (CC0), Wikipedia (CC BY-SA), zdjęcia Wikimedia Commons |

📐 **Architektura i podział pracy na tory:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
📄 **Kontrakt API:** [docs/API.md](docs/API.md)

## Szybki start (backend)

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate deploy   # tworzy/aktualizuje tabele
npm run seed                # ładuje zabytki ze snapshotu prisma/data/monuments.wroclaw.json
npm run start:dev           # http://localhost:3000
```

W drugim terminalu: `npm run smoke` – automatyczny test całego API (✅/❌).

| Komenda | Co robi |
|---|---|
| `npm run import:wroclaw` | pobiera świeże dane z Wikidata/Wikipedii i nadpisuje snapshot (~1 min) |
| `npm run seed` | ładuje snapshot do bazy (idempotentne, wizyty graczy zostają) |
| `npm run smoke` | smoke testy API (`-- --url https://szwto.onrender.com` dla produkcji) |

## Szybki start (aplikacja)

```bash
cd mobile
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

Bez `--dart-define` aplikacja łączy się z produkcją (`https://szwto.onrender.com`).

## Struktura projektu

```
backend/
├── prisma/schema.prisma          # schemat dla wszystkich funkcji (#1–#6)
├── prisma/data/                  # snapshot zabytków (JSON w repo)
├── scripts/import/               # Wikidata -> wzbogacenie -> snapshot
├── scripts/smoke/                # smoke testy (checks/NN-*.ts – każdy tor swój plik)
└── src/
    ├── auth/  prisma/  common/   # wspólne
    ├── events/                   # zdarzenie monument.visited (nagrody za wizytę)
    ├── monuments/  visits/       # tor A
    ├── progression/  achievements/   # tor B
    ├── users/  showcase/  comments/  # tor D
    ├── game/                     # tor E
    └── profile/
mobile/lib/
├── main.dart  app_shell.dart     # trasy + dolna nawigacja
├── core/                         # api_client, config, location, modele wspólne, widżety
└── features/                     # auth, map, monuments, comments, profile, collection, game
```

Pełna lista endpointów: [docs/API.md](docs/API.md).

---

# Instrukcja uruchomienia krok po kroku (bez Dockera)

## Wymagania

- Node.js 18 lub nowszy (zalecany 20/22) oraz npm
- PostgreSQL 14+ zainstalowany bezpośrednio w systemie (serwer musi działać na `localhost:5432`)
- Flutter SDK 3.22+ (`flutter doctor` powinien nie zgłaszać błędów dla wybranej platformy)
- Windows desktop, emulator Androida / symulator iOS albo fizyczny telefon

## Krok 1. Baza danych w lokalnym PostgreSQL

Plik `.env` zakłada użytkownika `postgres` z hasłem `haslo`. Jeśli masz inne hasło, zmień je w `DATABASE_URL` (krok 2) albo ustaw hasło `haslo` poleceniem z punktu A.

**A. Przez `psql` (terminal)**

Linux:
```bash
sudo -u postgres psql
```
macOS (Homebrew):
```bash
psql postgres
```
Windows (PowerShell lub „SQL Shell (psql)”):
```bash
psql -U postgres
```

W konsoli `psql` wykonaj:
```sql
ALTER USER postgres WITH PASSWORD 'haslo';   -- pomiń, jeśli masz już własne hasło
CREATE DATABASE zabytki_db;
\q
```

Jednolinijkowo (Linux):
```bash
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'haslo';" -c "CREATE DATABASE zabytki_db;"
```

**B. Przez pgAdmin**

1. Połącz się z serwerem lokalnym.
2. Prawy przycisk na *Databases* → *Create* → *Database…*
3. Nazwa: `zabytki_db`, owner: `postgres` → *Save*.

## Krok 2. Backend NestJS

```bash
cd zabytki/backend
```

1. Sprawdź plik `.env` i w razie potrzeby popraw hasło oraz ustaw własny `JWT_SECRET`:
   ```env
   DATABASE_URL="postgresql://postgres:haslo@localhost:5432/zabytki_db?schema=public"
   JWT_SECRET="zmien-mnie-na-dlugi-losowy-sekret"
   JWT_EXPIRES_IN="7d"
   PORT=3000
   # adres bez poolera – potrzebny do migracji; bez poolera = to samo co DATABASE_URL
   DIRECT_URL="postgresql://postgres:haslo@localhost:5432/zabytki_db?schema=public"
   ```
2. Zainstaluj zależności i wygeneruj klienta Prisma:
   ```bash
   npm install
   npx prisma generate
   ```
3. Utwórz tabele w bazie (migracja):
   ```bash
   npx prisma migrate deploy
   ```
4. Załaduj zabytki Wrocławia ze snapshotu (skrypt można uruchamiać wielokrotnie):
   ```bash
   npm run seed
   ```
5. Uruchom serwer w trybie deweloperskim:
   ```bash
   npm run start:dev
   ```
   Backend nasłuchuje na `http://localhost:3000`.

### Test API (zalecane)

Przy działającym backendzie, w drugim terminalu:

```bash
npm run smoke
```

Skrypt zakłada konto testowe, pobiera zabytki, sprawdza geofencing, wizytę, XP i profil – wypisuje ✅/❌ dla każdego kroku.

## Krok 3. Aplikacja Flutter

```bash
cd zabytki/mobile
```

### 3a. Przygotuj platformę uruchomieniową

Repozytorium zawiera kod Darta i `pubspec.yaml`. Foldery natywne są generowane przez Fluttera. Jeśli chcesz uruchomić aplikację na Windows (najprostsza opcja na komputerze bez emulatora), wykonaj:

```bash
flutter create . --platforms=windows
```

Jeśli chcesz uruchomić aplikację na Androidzie lub iOS, wygeneruj odpowiednie platformy:

```bash
flutter create . --project-name zabytki_app --org pl.zabytki --platforms=android,ios
```

Nie trzeba wykonywać tych poleceń ponownie, jeśli folder wybranej platformy już istnieje.

### 3b. Uruchom backend

Backend musi działać w osobnym terminalu:

```bash
cd zabytki/backend
npm install
npx prisma generate
npx prisma migrate deploy
npm run seed
npm run start:dev
```

Sprawdź, czy działa, otwierając `http://localhost:3000/`. Powinieneś zobaczyć:

```json
{ "name": "zabytki-backend", "status": "ok" }
```

### 3c. Uprawnienia lokalizacji i HTTP (jednorazowo)

**Android** – plik `android/app/src/main/AndroidManifest.xml`:

1. Tuż nad znacznikiem `<application ...>` dodaj:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   ```
2. W znaczniku `<application ...>` dopisz atrybut (backend działa po zwykłym HTTP):
   ```xml
   android:usesCleartextTraffic="true"
   ```

**iOS** – plik `ios/Runner/Info.plist`, wewnątrz głównego `<dict>`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Aplikacja potrzebuje Twojej lokalizacji, aby odznaczać zabytki w pobliżu.</string>
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key>
  <true/>
</dict>
```

### 3d. Pobierz pakiety i uruchom

W drugim terminalu:

```bash
cd zabytki/mobile
flutter pub get
```

Na Windows:

```bash
flutter run -d windows
```

Jeśli używasz emulatora Androida:

```bash
flutter run -d emulator-5554
```

Jeśli nie wiesz, jaki identyfikator ma urządzenie, wyświetl dostępne urządzenia:

```bash
flutter devices
```

Polecenie `flutter run` bez `-d` zadziała tylko wtedy, gdy Flutter znajdzie dokładnie jedno obsługiwane urządzenie. Samo zainstalowanie Chrome lub Windows nie wystarczy, jeśli foldery `web` albo `windows` nie zostały wygenerowane.

### Adres backendu

Aplikacja wybiera adres automatycznie:

| Środowisko | Adres |
|---|---|
| Emulator Androida | `http://10.0.2.2:3000` |
| Symulator iOS / desktop | `http://localhost:3000` |
| **Fizyczny telefon** | podaj IP komputera w tej samej sieci Wi-Fi |

Na Windows uruchomionym na tym samym komputerze aplikacja korzysta z `http://localhost:3000`.

Dla fizycznego telefonu:
```bash
flutter run --dart-define=API_URL=http://192.168.0.15:3000
```
(zastąp `192.168.0.15` adresem IP swojego komputera; zapora systemowa musi przepuszczać port 3000).

### Jak przetestować odznaczanie zabytku bez podróży

- **Emulator Androida:** `…` (Extended controls) → *Location* → wpisz współrzędne zabytku, np. Ratusz we Wrocławiu `51.1096, 17.0318` → *Set location*.
- **Symulator iOS:** menu *Features* → *Location* → *Custom Location…* i wpisz współrzędne.
- Następnie dotknij pinezki zabytku i naciśnij **„Oznacz jako odwiedzony”**. Pinezka (kolor = rzadkość) zmieni się na zieloną z ptaszkiem.
- Z dowolnego innego miejsca zobaczysz komunikat **„Za daleko od zabytku”**.

## Rozwiązywanie problemów

| Problem | Rozwiązanie |
|---|---|
| `P1000` / `password authentication failed` | Hasło w `DATABASE_URL` nie zgadza się z hasłem użytkownika `postgres` (patrz krok 1). |
| `P1001: Can't reach database server` | Serwer PostgreSQL nie działa lub nasłuchuje na innym porcie. |
| `database "zabytki_db" does not exist` | Wykonaj `CREATE DATABASE zabytki_db;` (krok 1). |
| `No supported devices connected` | Wygeneruj platformę poleceniem `flutter create . --platforms=windows` i uruchom `flutter run -d windows`, albo uruchom emulator Androida. |
| Aplikacja: „Brak połączenia z serwerem” | Backend nie działa albo zły adres API (patrz *Adres backendu*); na Androidzie sprawdź `usesCleartextTraffic`. |
| Brak pinezki użytkownika na mapie | Włącz GPS i zaakceptuj zgodę na lokalizację; w emulatorze ustaw lokalizację ręcznie. |
| Mapa pokazuje szare kafelki | Brak internetu na urządzeniu (kafelki OpenStreetMap są pobierane online). |
