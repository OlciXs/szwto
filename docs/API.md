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
| GET | `/profile` | własny profil: `displayName`, `visitedCount`, `totalMonuments`, `recentVisits[]`, `progression`, `achievements` (`unlockedCount`, `total`, `recent[]`) |
| GET | `/progression` | `{ totalXp, level, rank: {index, name}, levelStartXp, nextLevelXp, progress, perks: {discoveryRadius, showcaseSlots, radar}, nextUnlock }` |
| GET | `/achievements` | `{ unlockedCount, total, achievements: [{ id, name, description, icon, group, groupLabel, tier, xp, secret, target, progress, unlocked, unlockedAt }] }` – sekretne nieodblokowane mają `name: "???"` |
| POST | `/events` | `{ type: "WIKIPEDIA_OPENED", monumentId }` → `{ recorded, rewards }` (może odblokować „Mola książkowego”) |
| GET | `/users/:id` | publiczny profil **bez e-maila**: `displayName, level, rank, totalXp, visitedCount, achievements, showcase, isMe` |
| GET | `/users/leaderboard` | `{ totalPlayers, entries: [{ position, id, displayName, totalXp, visitedCount, level, rankIndex, rankName, isMe }], me }` (top 50 + pozycja oglądającego) |
| PATCH | `/users/me` | `{ displayName }` → `409`, gdy nazwa zajęta |
| GET | `/showcase` | moja gablotka: `{ unlockedSlots, maxSlots, slots: [{ slot, locked, unlockLevel, monument: MonumentCard | null }] }` |
| PUT | `/showcase/:slot` | `{ monumentId }` → `{ showcase, rewards }`; tylko odwiedzone (`400`), tylko odblokowane miejsca (`403`), duplikat = przeniesienie |
| DELETE | `/showcase/:slot` | → `{ showcase }` |
| GET | `/monuments/:id/comments?before=` | `{ total, visited, visitRadius, hasMore, comments: [{ id, body, createdAt, isMine, author: { id, displayName, level, rankIndex, rankName } }] }` |
| POST | `/monuments/:id/comments` | `{ body ≤ 500, latitude, longitude }` → `{ id, rewards }`; **tylko po wizycie I na miejscu** (`403`), maks. 1 na 10 s (`429`) |
| DELETE | `/comments/:id` | tylko własne (`403`) |

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
  "xp": 150, "visitRadius": 75,
  "visited": false, "visitedAt": null
}
```

### MonumentDetails (= MonumentListItem +)
```jsonc
{
  "teaser": "Ratusz · XIII wiek",
  "summary": "Stary Ratusz we Wrocławiu – późnogotycki budynek…",  // zajawka, widoczna zawsze
  "description": null,              // długi opis (akapity "\n\n") dopiero po wizycie (#6)
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

## Planowane (do uzupełnienia przez tory)

| Tor | Metoda | Ścieżka | Opis |
|---|---|---|---|
| E | GET | `/game/round` | runda solo |
| E | POST | `/duels`, `/duels/:code/join`, `/duels/:code/answers` | pojedynek asynchroniczny |
