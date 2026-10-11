# Kontrakt API

Wszystkie endpointy poza `/auth/*` i `GET /` wymagają nagłówka `Authorization: Bearer <token>`.
Dopisując endpoint, dodaj wiersz w tabeli swojego toru.

## Gotowe (etap 0)

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/` | status backendu |
| POST | `/auth/register` | `{ email, password, displayName? }` → `{ accessToken, user: { id, email, displayName } }` |
| POST | `/auth/login` | `{ email, password }` → jak wyżej |
| GET | `/monuments?category=&rarity=` | lista na mapę (lekka, bez opisów) – patrz `MonumentListItem` |
| GET | `/monuments/:id` | szczegóły – patrz `MonumentDetails` |
| POST | `/monuments/:id/visit` | `{ latitude, longitude }` → `VisitResponse`; `400`, gdy dalej niż `visitRadius` |
| GET | `/profile` | własny profil: `displayName`, `visitedCount`, `totalMonuments`, `recentVisits[]`, `progression`, `achievements` (`unlockedCount`, `total`, `recent[]`), `showcase`, `friendCode`, `friendsCount`, `incomingRequests` |
| GET | `/progression` | `{ totalXp, level, rank: {index, name}, levelStartXp, nextLevelXp, progress, perks: {discoveryRadius, showcaseSlots, radar}, nextUnlock }` |
| GET | `/achievements` | `{ unlockedCount, total, achievements: [{ id, name, description, icon, group, groupLabel, tier, xp, secret, target, progress, unlocked, unlockedAt }] }` – sekretne nieodblokowane mają `name: "???"` |
| POST | `/events` | `{ type: "WIKIPEDIA_OPENED", monumentId }` → `{ recorded, rewards }` (może odblokować „Mola książkowego”) |
| GET | `/users/:id` | publiczny profil **bez e-maila**: `displayName, friendCode, level, rank, totalXp, visitedCount, achievements, showcase, isMe, friendStatus (NONE/OUTGOING/INCOMING/FRIENDS), isFriend` |
| GET | `/users/leaderboard?scope=friends` | `{ totalPlayers, entries: [{ position, id, displayName, totalXp, visitedCount, level, rankIndex, rankName, isMe, isFriend }], me }` (top 50 + pozycja oglądającego); `scope=friends` – tylko znajomi i ja |
| PATCH | `/users/me` | `{ displayName }` → `409`, gdy nazwa zajęta |
| GET | `/showcase` | moja gablotka: `{ unlockedSlots, maxSlots, slots: [{ slot, locked, unlockLevel, monument: MonumentCard | null }] }` |
| PUT | `/showcase/:slot` | `{ monumentId }` → `{ showcase, rewards }`; tylko odwiedzone (`400`), tylko odblokowane miejsca (`403`), duplikat = przeniesienie |
| DELETE | `/showcase/:slot` | → `{ showcase }` |
| GET | `/monuments/:id/comments?before=` | `{ total, visited, visitRadius, hasMore, comments: [{ id, body, createdAt, isMine, author: { id, displayName, level, rankIndex, rankName, isFriend } }] }` |
| POST | `/monuments/:id/comments` | `{ body ≤ 500, latitude, longitude }` → `{ id, rewards }`; **tylko po wizycie I na miejscu** (`403`), maks. 1 na 10 s (`429`) |
| DELETE | `/comments/:id` | tylko własne (`403`) |
| GET | `/friends` | `{ myCode, friends[], incoming[], outgoing[] }`; element: `{ id, displayName, friendCode, level, rankIndex, rankName, totalXp, visitedCount }` |
| POST | `/friends` | `{ code }` (np. `#K7Q2MX`, wielkość liter i # bez znaczenia) → `{ status: PENDING/ACCEPTED, message, rewards }`; `404` nieznany kod, `400` własny kod, `409` już znajomi / zaproszenie czeka; jeśli ta osoba zaprosiła nas wcześniej – od razu `ACCEPTED` |
| POST | `/friends/:userId/accept` | akceptuje zaproszenie od `userId` → `{ status, message, rewards }` (`404`, gdy brak zaproszenia) |
| DELETE | `/friends/:userId` | usuwa znajomego / odrzuca zaproszenie / anuluje wysłane → `{ removed: true }` |

### MonumentListItem
```jsonc
{
  "id": 42, "name": "Ratusz we Wrocławiu",
  "category": "PUBLICZNY",          // KAMIENICA | PALAC | SAKRALNY | MOST | POMNIK | RZEZBA | PARK | PUBLICZNY | TECHNICZNY | ARCHITEKTURA
  "rawType": "ratusz",
  "rarity": "LEGENDARY",            // COMMON | RARE | EPIC | LEGENDARY
  "isMajor": true,                  // zabytek główny (zawsze na mapie); false = ukryta perełka
  "latitude": 51.1096, "longitude": 17.0318,
  "thumbUrl": "https://upload.wikimedia.org/...330px-....jpg",   // lub null
  "builtYear": 1250, "builtLabel": "XIII wiek",
  "era": "SREDNIOWIECZE",           // SREDNIOWIECZE | NOWOZYTNOSC | WIEK_XIX | WIEK_XX | POWOJENNE | null
  "xp": 150, "visitRadius": 40,
  "visited": false, "visitedAt": null
}
```

### MonumentDetails (= MonumentListItem +)
```jsonc
{
  "teaser": "Ratusz · XIII wiek",
  "summary": "Stary Ratusz we Wrocławiu – późnogotycki budynek…",  // zajawka, widoczna zawsze
  "description": null,              // opis (maks. 5 akapitów, "\n\n") dopiero po wizycie (#6)
  "funFact": null,                  // ciekawostka – też dopiero po wizycie
  "descriptionLocked": true,
  "descriptionSource": "wikipedia", // lub "generated"
  "address": "Rynek Ratusz 1 50-116 Wrocław",
  "image": { "thumbUrl": "...500px...", "fullUrl": "...1280px...", "pageUrl": "https://commons.wikimedia.org/wiki/File:..." },
  "heritageLevel": "REJESTR",       // UNESCO | POMNIK_HISTORII | REJESTR | EWIDENCJA | BRAK
  "registerNumber": "A/2908/135",
  "wikipediaUrl": "https://pl.wikipedia.org/wiki/...",
  "source": "WIKIDATA", "externalId": "wd:Q910225",
  "visitorsCount": 3,
  "commentsCount": 2               // tor D
}
```

### VisitResponse
```jsonc
{
  "success": true,
  "message": "Zabytek „Ratusz we Wrocławiu” został odznaczony!",
  "alreadyVisited": false,
  "distanceMeters": 12.3,
  "visitedAt": "2026-10-11T00:00:00.000Z",
  "xpEarned": 150,                  // 0 przy ponownej wizycie
  "rewards": {                      // achievements/rewards.service.ts (kształt: events/monument-visited.event.ts)
    "progression": {                // policzone PO premiach za nowe osiągnięcia
      "xpGained": 225, "totalXp": 225, "level": 3, "levelUp": true,
      "rank": "Spacerowicz", "rankUp": true, "newPerks": ["2. miejsce w gablotce"]
    },
    "newAchievements": [{ "id": "legendary-1", "name": "Pierwsza legenda", "description": "...", "icon": "star", "tier": null, "xp": 50 }]
  }
}
```

## Tor E – Gra / Pojedynki 1v1

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/game/eligibility` | Sprawdzenie kwalifikacji (wymóg min. 10 kart) dla gracza i listy znajomych |
| GET | `/game/duels` | Lista aktywnych i zakończonych pojedynków gracza |
| POST | `/game/duels` | `{ opponentId?, isBot? }` → utworzenie pojedynku (wymaga min. 10 kart u obu graczy) |
| GET | `/game/duels/:id` | Pobranie stanu pojedynku i 3 wygenerowanych rund z kartami |
| POST | `/game/duels/:id/answers` | `{ answers: ['CREATOR' | 'OPPONENT', ...] }` → przesłanie odpowiedzi na 3 rundy i rozliczenie wyników |
