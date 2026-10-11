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
      expect(list.length > 300, `za mało zabytków: ${list.length} (czy był npm run seed?)`);
      const first = list[0];
      for (const field of ['category', 'rarity', 'isMajor', 'xp', 'visitRadius', 'latitude', 'visited']) {
        expect(field in first, `brak pola "${field}"`);
      }
      const withPhoto = list.filter((m) => m.thumbUrl).length;
      const major = list.filter((m) => m.isMajor).length;
      expect(major > 10 && major < list.length, `dziwna liczba głównych zabytków: ${major}`);
      state.monuments = list;
      return `${list.length} zabytków (${major} głównych, ${list.length - major} perełek), ${withPhoto} ze zdjęciem`;
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
        list.find((m) => m.name === 'Ratusz') ??
        list.find((m) => m.rarity === 'LEGENDARY' && m.thumbUrl);
      expect(target, 'nie znaleziono zabytku testowego');
      const res = await api.get(`/monuments/${target.id}`);
      expectStatus(res, 200);
      expect(res.body.descriptionLocked === true, 'opis powinien być zablokowany');
      expect(res.body.description === null, 'opis powinien być ukryty');
      expect(res.body.teaser, 'brak typu/daty (teaser)');
      expect(res.body.summary, 'brak zajawki (summary) przed wizytą');
      expect(res.body.wikipediaUrl === null, 'link do Wikipedii widoczny przed wizytą');
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
      expect(
        res.body.description.length > 500,
        `opis za krótki (${res.body.description.length} znaków)`,
      );
      expect(res.body.visitorsCount >= 1, 'visitorsCount < 1');
      expect(res.body.wikipediaUrl, 'brak linku do Wikipedii po wizycie');
      return `${res.body.description.length} znaków, ${
        res.body.description.split('\n\n').length
      } akapitów (źródło: ${res.body.descriptionSource})`;
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
