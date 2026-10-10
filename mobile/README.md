# Odkrywca Zabytków

## Połączenie telefonu z backendem w tej samej sieci

Backend musi działać na komputerze i nasłuchiwać na `0.0.0.0:3000`:

```powershell
cd ..\backend
npm run start:dev
```

Telefon i komputer muszą być podłączone do tej samej sieci Wi-Fi. Adres IPv4
komputera można sprawdzić poleceniem `ipconfig` (np. `192.168.1.10`).
Jeśli Windows Firewall zapyta o dostęp dla Node.js, należy zezwolić na sieci
prywatne.

Na ekranie logowania aplikacji wpisz adres:

```text
http://192.168.1.10:3000
```

Adres jest zapisywany na urządzeniu, więc nie trzeba wpisywać go ponownie.
Dla emulatora Androida domyślnie używany jest `http://10.0.2.2:3000`.

## Uruchomienie aplikacji na Androidzie

```powershell
flutter pub get
flutter devices
flutter run -d <id_telefonu>
```

## Frontend w przeglądarce po sieci

Build webowy musi zawierać adres backendu dostępny dla telefonu:

```powershell
flutter build web --release --dart-define=API_URL=http://172.20.10.2:3000
cd build\web
py -m http.server 8080 --bind 0.0.0.0
```

Na telefonie otwórz:

```text
http://172.20.10.2:8080
```

Backend pozostaje dostępny pod `http://172.20.10.2:3000`. Jeśli Windows
Firewall zapyta o dostęp dla Pythona, należy zezwolić na sieci prywatne.
