# Odkrywca Zabytków

Prosta aplikacja mobilna do odkrywania i odznaczania zabytków w Polsce.
Zabytek można odznaczyć tylko wtedy, gdy użytkownik jest od niego oddalony o **maksymalnie 50 metrów** (geofencing sprawdzany po stronie backendu).

| Warstwa | Technologia |
|---|---|
| Frontend | Flutter (Dart), `flutter_map` + OpenStreetMap, `geolocator` |
| Backend | NestJS (TypeScript), JWT, `class-validator` |
| Baza danych | lokalny PostgreSQL + Prisma ORM (bez Dockera) |

## Struktura projektu

```
zabytki/
├── backend/
│   ├── .env                      # DATABASE_URL, JWT_SECRET, PORT
│   ├── package.json
│   ├── prisma/
│   │   ├── schema.prisma         # User, Monument, UserVisited
│   │   └── seed.ts               # przykładowe zabytki w Polsce
│   └── src/
│       ├── main.ts
│       ├── app.module.ts
│       ├── prisma/               # PrismaService (moduł globalny)
│       ├── auth/                 # rejestracja, logowanie, JWT
│       ├── common/geo.util.ts    # wzór haversine
│       └── monuments/            # GET /monuments, POST /monuments/:id/visit
└── mobile/
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart
    │   ├── config.dart           # adres API
    │   ├── models/monument.dart
    │   ├── services/api_service.dart
    │   └── screens/
    │       ├── login_screen.dart
    │       └── map_screen.dart   # mapa, pinezki, BottomSheet
    └── test/widget_test.dart
```

## API

`GET http://localhost:3000/` returns the backend status:

```json
{ "name": "zabytki-backend", "status": "ok" }
```

| Metoda | Ścieżka | Opis |
|---|---|---|
| POST | `/auth/register` | `{ "email", "password" }` → `{ accessToken, user }` |
| POST | `/auth/login` | `{ "email", "password" }` → `{ accessToken, user }` |
| GET | `/monuments` | lista zabytków + pole `visited` dla zalogowanego użytkownika (wymaga `Authorization: Bearer <token>`) |
| POST | `/monuments/:id/visit` | `{ "latitude": 51.1, "longitude": 17.0 }` → sukces, gdy odległość ≤ 50 m, inaczej `400 "Za daleko od zabytku"` |

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
   ```
2. Zainstaluj zależności (to również wygeneruje klienta Prisma):
   ```bash
   npm install
   ```
3. Utwórz tabele w bazie (migracja):
   ```bash
   npx prisma migrate dev --name init
   ```
4. Załaduj przykładowe zabytki (skrypt można uruchamiać wielokrotnie):
   ```bash
   npm run seed
   ```
5. Uruchom serwer w trybie deweloperskim:
   ```bash
   npm run start:dev
   ```
   Backend nasłuchuje na `http://localhost:3000`.

### Szybki test API w terminalu (opcjonalnie)

```bash
# rejestracja
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456"}'

# skopiuj accessToken z odpowiedzi
export TOKEN="wklej_token_tutaj"

# lista zabytków
curl http://localhost:3000/monuments -H "Authorization: Bearer $TOKEN"

# odznaczenie Wawelu (id 1) z miejsca oddalonego o kilkadziesiąt kilometrów -> 400 "Za daleko od zabytku"
curl -X POST http://localhost:3000/monuments/1/visit \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"latitude":51.1,"longitude":17.0}'

# odznaczenie Wawelu ze współrzędnych zabytku -> sukces
curl -X POST http://localhost:3000/monuments/1/visit \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"latitude":50.0540,"longitude":19.9354}'
```

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
npx prisma migrate dev
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

- **Emulator Androida:** `…` (Extended controls) → *Location* → wpisz współrzędne zabytku, np. Wawel `50.0540, 19.9354` → *Set location*.
- **Symulator iOS:** menu *Features* → *Location* → *Custom Location…* i wpisz współrzędne.
- Następnie dotknij pinezki zabytku i naciśnij **„Oznacz jako odwiedzony”**. Pinezka zmieni kolor z szarego na zielony.
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
