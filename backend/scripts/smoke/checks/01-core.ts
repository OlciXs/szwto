import { expect, expectStatus, SmokeCheck } from '../lib';

/** Etap 0: rejestracja, katalog zabytków, wizyta (geofencing), profil. */
export const checks: SmokeCheck[] = [
  {
    name: 'Backend odpowiada',
    run: async ({ api }) => {
      const res = await api.get('/');
      expectStatus(res, 200);
      expect(res.body.status === 'ok', 'status != ok');
    },
  },
  {
    name: 'Rejestracja nowego gracza (z automatycznym displayName)',
    run: async ({ api, state }) => {
      const stamp = Date.now();
      state.email = `smoke_${stamp}@test.local`;
      state.password = 'smoke-test-123';
      const res = await api.post('/auth/register', {
        email: state.email,
        password: state.password,
      });
      expectStatus(res, 201);
      expect(res.body.accessToken, 'brak accessToken');
      expect(res.body.user.displayName, 'brak displayName');
      state.displayName = res.body.user.displayName;
      return `displayName: ${state.displayName}`;
    },
  },
  {
    name: 'Logowanie',
    run: async ({ api, state }) => {
      const res = await api.post('/auth/login', {
        email: state.email,
        password: state.password,
      });
      expectStatus(res, 200);
      api.token = res.body.accessToken;
    },
  },
  {
    name: 'Lista zabytków Wrocławia z nowymi polami',
    run: async ({ api, state }) => {
      const res = await api.get('/monuments');
      expectStatus(res, 200);
      const list = res.body as any[];
      expect(list.length > 1000, `za mało zabytków: ${list.length} (czy był npm run seed?)`);
      const first = list[0];
      for (const field of ['category', 'rarity', 'xp', 'visitRadius', 'latitude', 'visited']) {
        expect(field in first, `brak pola "${field}"`);
      }
      const withPhoto = list.filter((m) => m.thumbUrl).length;
      const legendary = list.filter((m) => m.rarity === 'LEGENDARY').length;
      state.monuments = list;
      return `${list.length} zabytków, ${withPhoto} ze zdjęciem, ${legendary} legendarnych`;
    },
  },
  {
    name: 'Filtr ?category=MOST',
    run: async ({ api }) => {
      const res = await api.get('/monuments?category=MOST');
      expectStatus(res, 200);
      expect(res.body.length > 0, 'brak mostów');
      expect(
        res.body.every((m: any) => m.category === 'MOST'),
        'filtr zwrócił inne kategorie',
      );
      return `${res.body.length} mostów`;
    },
  },
  {
    name: 'Szczegóły zabytku przed wizytą: opis zablokowany, jest zajawka i zdjęcie',
    run: async ({ api, state }) => {
      const list = state.monuments as any[];
      const target =
        list.find((m) => m.name === 'Ratusz we Wrocławiu') ??
        list.find((m) => m.rarity === 'LEGENDARY' && m.thumbUrl);
      expect(target, 'nie znaleziono zabytku testowego');
      const res = await api.get(`/monuments/${target.id}`);
      expectStatus(res, 200);
      expect(res.body.descriptionLocked === true, 'opis powinien być zablokowany');
      expect(res.body.description === null, 'opis powinien być ukryty');
      expect(res.body.teaser, 'brak zajawki');
      state.target = res.body;
      return `${res.body.name} (${res.body.rarity}, ${res.body.xp} XP, zajawka: "${res.body.teaser}")`;
    },
  },
  {
    name: 'Wizyta z daleka jest odrzucana (geofencing)',
    run: async ({ api, state }) => {
      const t = state.target;
      const res = await api.post(`/monuments/${t.id}/visit`, {
        latitude: t.latitude + 0.01, // ~1,1 km na północ
        longitude: t.longitude,
      });
      expectStatus(res, 400);
      return res.body.message;
    },
  },
  {
    name: 'Wizyta na miejscu daje XP',
    run: async ({ api, state }) => {
      const t = state.target;
      const res = await api.post(`/monuments/${t.id}/visit`, {
        latitude: t.latitude,
        longitude: t.longitude,
      });
      expectStatus(res, 200);
      expect(res.body.alreadyVisited === false, 'pierwsza wizyta oznaczona jako powtórna');
      expect(res.body.xpEarned === t.xp, `xpEarned=${res.body.xpEarned}, oczekiwano ${t.xp}`);
      expect(typeof res.body.rewards === 'object', 'brak pola rewards');
      return `+${res.body.xpEarned} XP, rewards: ${JSON.stringify(res.body.rewards)}`;
    },
  },
  {
    name: 'Ponowna wizyta nie daje XP drugi raz',
    run: async ({ api, state }) => {
      const t = state.target;
      const res = await api.post(`/monuments/${t.id}/visit`, {
        latitude: t.latitude,
        longitude: t.longitude,
      });
      expectStatus(res, 200);
      expect(res.body.alreadyVisited === true, 'powinno być alreadyVisited');
      expect(res.body.xpEarned === 0, 'XP przyznane drugi raz');
    },
  },
  {
    name: 'Po wizycie opis jest odblokowany',
    run: async ({ api, state }) => {
      const res = await api.get(`/monuments/${state.target.id}`);
      expectStatus(res, 200);
      expect(res.body.visited === true, 'visited != true');
      expect(res.body.description, 'brak opisu po wizycie');
      expect(res.body.visitorsCount >= 1, 'visitorsCount < 1');
      return `"${res.body.description.slice(0, 70)}…" (źródło: ${res.body.descriptionSource})`;
    },
  },
  {
    name: 'Profil gracza',
    run: async ({ api, state }) => {
      const res = await api.get('/profile');
      expectStatus(res, 200);
      expect(res.body.displayName === state.displayName, 'zły displayName');
      expect(res.body.visitedCount === 1, `visitedCount=${res.body.visitedCount}`);
      return `${res.body.visitedCount}/${res.body.totalMonuments} odwiedzonych`;
    },
  },
];
