# Architektura i podział pracy

Cel: kilka osób pracuje równolegle i prawie nie dotyka tych samych plików.

## Zasady

1. **Schemat bazy jest gotowy dla wszystkich funkcji (#1–#6).** Tabele `ShowcaseSlot`, `Comment`, `Duel`
   i pola `xpEarned`, `displayName` już istnieją. Nie zmieniaj `schema.prisma` bez uzgodnienia – nowa migracja
   = potencjalny konflikt.
2. **Jedna funkcja = jeden folder** w `backend/src/<moduł>/` i `mobile/lib/features/<funkcja>/`.
3. **Wizyta emituje zdarzenie** `monument.visited` (`backend/src/events/monument-visited.event.ts`).
   Moduły nagród dopisują listener i zwracają swój fragment `VisitRewards` – nie edytują `visits/`.
4. **Wspólne kształty danych**: backend – `monuments/monument.mapper.ts`, `common/commons.util.ts`;
   aplikacja – `features/monuments/models/monument.dart`, `core/models/*`.
5. **Kontrakt API** opisujemy w [`API.md`](API.md) – kto dodaje endpoint, dopisuje go tam.
6. **Smoke testy**: każdy tor dodaje własny plik `backend/scripts/smoke/checks/NN-nazwa.ts`
   (runner wczytuje je automatycznie).

## Tory prac

| Tor | Issue | Backend | Aplikacja | Smoke |
|---|---|---|---|---|
| A – Mapa i zabytki | – | `monuments/`, `visits/` | `features/map/`, `features/monuments/` | `01-core.ts` |
| B – XP i achievementy | #1, #5 | `progression/`, `achievements/` | `features/achievements/`, `monuments/widgets/visit_feedback.dart` | `02-progression.ts` |
| C – Karty i kolekcja | #2 | (gotowe `GET /monuments`) | `features/collection/`, `core/models/rarity.dart` | – |
| D – Społeczność | #4, #6 | `users/`, `showcase/`, `comments/` | `features/profile/`, `features/comments/`, `features/leaderboard/` | `04-social.ts` |
| E – Gra | #3 | `game/` | `features/game/` | `05-game.ts` |

Puste moduły backendu mają w komentarzu plan endpointów – zacznij od przeczytania `<moduł>.module.ts`.

## Jak dopisać nagrodę za wizytę (przykład dla toru B)

```ts
// backend/src/progression/progression.listener.ts
@Injectable()
export class ProgressionListener {
  constructor(private readonly prisma: PrismaService) {}

  @OnEvent(MONUMENT_VISITED)
  async handle(event: MonumentVisitedEvent): Promise<Partial<VisitRewards>> {
    const { _sum } = await this.prisma.userVisited.aggregate({
      where: { userId: event.userId },
      _sum: { xpEarned: true },
    });
    // ... policz poziom
    return { progression: { xpGained: event.visit.xpEarned, totalXp: _sum.xpEarned ?? 0, level, levelUp } };
  }
}
// + dodaj ProgressionListener do providers w progression.module.ts
```

Błąd w listenerze jest logowany, ale nie psuje wizyty (domyślne `suppressErrors` w `@nestjs/event-emitter`).

## Dane zabytków

```
Wikidata (SPARQL) ──► scripts/import/build-snapshot.ts ──► prisma/data/monuments.wroclaw.json ──► npm run seed ──► Postgres
Wikipedia (API)  ──┘        (category-map.ts, enrich.ts)        (w repo, ~450 obiektów)
```

- Zewnętrzne API są wołane **tylko** przy `npm run import:wroclaw`, nigdy przez działający backend.
- Logika seeda: `src/database/monument-seed.ts` – używa jej `npm run seed` oraz automatyczny setup
  na Renderze (`src/database/database-setup.ts`: migracje przed startem, seed w tle, gdy brakuje zabytków).
- Atrybuty pochodne (kategoria, epoka, rzadkość, XP, promień wizyty) liczy `scripts/import/enrich.ts`.
  Zmiana wzoru = `npm run import:wroclaw && npm run seed` (wizyty graczy zostają – upsert po `externalId`).
- Zdjęcia: tylko nazwa pliku z Commons; adresy miniatur buduje `common/commons.util.ts`
  (bezpośrednio `upload.wikimedia.org`, bo `Special:FilePath` nie ma CORS i nie działa we Flutter Web).
- Licencje: Wikidata CC0, opisy z Wikipedii CC BY-SA 4.0, zdjęcia – licencja każdego pliku (link w aplikacji).
