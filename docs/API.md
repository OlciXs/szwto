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
  "visitorsCount": 3
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
| D | GET | `/users/:id` | publiczny profil (bez e-maila): displayName, poziom, gablotka, achievementy |
| D | GET | `/users/leaderboard` | ranking |
| D | PATCH | `/users/me` | `{ displayName }` |
| D | PUT / DELETE | `/showcase/:slot` | `{ monumentId }` – tylko odwiedzone |
| D | GET / POST | `/monuments/:id/comments` | lista / dodanie (`{ body ≤ 500 }`, tylko po wizycie) |
| D | DELETE | `/comments/:id` | tylko własne |
| E | GET | `/game/round` | runda solo |
| E | POST | `/duels`, `/duels/:code/join`, `/duels/:code/answers` | pojedynek asynchroniczny |
