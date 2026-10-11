import { Api, expect, expectStatus, SmokeCheck } from '../lib';

/** Znajomi: kod gracza, zaproszenia, akceptacja, oznaczenia ZNAJOMY, ranking znajomych. */

async function newPlayer(api: Api, prefix: string) {
  const res = await api.post('/auth/register', {
    email: `smoke_${prefix}_${Date.now()}@test.local`,
    password: 'smoke-test-123',
  });
  expectStatus(res, 201);
  return { token: res.body.accessToken as string, id: res.body.user.id as number };
}

export const checks: SmokeCheck[] = [
  {
    name: 'Każdy gracz ma unikalny kod znajomego',
    run: async ({ api, state }) => {
      state.fa = await newPlayer(api, 'frA');
      state.fb = await newPlayer(api, 'frB');
      state.fc = await newPlayer(api, 'frC');
      api.token = state.fa.token;
      const a = await api.get('/friends');
      expectStatus(a, 200);
      api.token = state.fb.token;
      const b = await api.get('/friends');
      state.codeA = a.body.myCode;
      expect(/^[A-Z0-9]{6}$/.test(state.codeA), `zły format kodu: ${state.codeA}`);
      expect(state.codeA !== b.body.myCode, 'kody nie są unikalne');
      const profile = await api.get('/profile');
      expect(profile.body.friendCode === b.body.myCode, 'brak kodu w profilu');
      return `#${state.codeA}, #${b.body.myCode}`;
    },
  },
  {
    name: 'Zaproszenie po kodzie (z # i małymi literami), błędy: własny kod, nieznany, duplikat',
    run: async ({ api, state }) => {
      api.token = state.fb.token;
      const res = await api.post('/friends', { code: `#${state.codeA.toLowerCase()}` });
      expectStatus(res, 200);
      expect(res.body.status === 'PENDING', `status=${res.body.status}`);
      expectStatus(await api.post('/friends', { code: state.codeA }), 409);
      expectStatus(await api.post('/friends', { code: '#OOOOOO' }), 404);
      api.token = state.fa.token;
      expectStatus(await api.post('/friends', { code: state.codeA }), 400);
      return res.body.message;
    },
  },
  {
    name: 'A widzi zaproszenie od B i akceptuje → „Pierwszy znajomy”',
    run: async ({ api, state }) => {
      api.token = state.fa.token;
      const overview = await api.get('/friends');
      expect(
        overview.body.incoming.some((u: any) => u.id === state.fb.id),
        'brak zaproszenia od B',
      );
      const res = await api.post(`/friends/${state.fb.id}/accept`);
      expectStatus(res, 200);
      expect(res.body.status === 'ACCEPTED', 'nie zaakceptowano');
      const ids = (res.body.rewards.newAchievements as any[]).map((a) => a.id);
      expect(ids.includes('friends-1'), `brak „Pierwszy znajomy” (${ids})`);
      const after = await api.get('/friends');
      expect(after.body.friends.some((u: any) => u.id === state.fb.id), 'B nie jest na liście');
      return res.body.message;
    },
  },
  {
    name: 'Oznaczenia ZNAJOMY: profil publiczny i ranking (także zakres „znajomi”)',
    run: async ({ api, state }) => {
      api.token = state.fa.token;
      const profile = await api.get(`/users/${state.fb.id}`);
      expect(profile.body.friendStatus === 'FRIENDS' && profile.body.isFriend, 'B nie jest oznaczony');
      expect(/^[A-Z0-9]{6}$/.test(profile.body.friendCode), 'brak publicznego kodu w profilu');
      expect(!('email' in profile.body), 'profil publiczny zawiera e-mail');
      const all = await api.get('/users/leaderboard');
      const b = (all.body.entries as any[]).concat(all.body.me ?? []).find((e) => e.id === state.fb.id);
      if (b) expect(b.isFriend === true, 'brak isFriend w rankingu');
      const friendsOnly = await api.get('/users/leaderboard?scope=friends');
      const ids = (friendsOnly.body.entries as any[]).map((e) => e.id).sort();
      expect(
        JSON.stringify(ids) === JSON.stringify([state.fa.id, state.fb.id].sort()),
        `ranking znajomych zawiera obcych: ${ids}`,
      );
      return `ranking znajomych: ${friendsOnly.body.totalPlayers} graczy`;
    },
  },
  {
    name: 'Komentarz znajomego ma oznaczenie ZNAJOMY',
    run: async ({ api, state }) => {
      api.token = state.fb.token;
      const list = (await api.get('/monuments')).body as any[];
      const m = list.find((x) => x.isMajor) ?? list[0];
      await api.post(`/monuments/${m.id}/visit`, { latitude: m.latitude, longitude: m.longitude });
      const c = await api.post(`/monuments/${m.id}/comments`, {
        body: 'Komentarz znajomego',
        latitude: m.latitude,
        longitude: m.longitude,
      });
      expectStatus(c, 201);
      api.token = state.fa.token;
      const comments = await api.get(`/monuments/${m.id}/comments`);
      const mine = comments.body.comments.find((x: any) => x.id === c.body.id);
      expect(mine?.author.isFriend === true, 'brak oznaczenia ZNAJOMY przy komentarzu');
    },
  },
  {
    name: 'Odrzucenie zaproszenia i usunięcie znajomego',
    run: async ({ api, state }) => {
      api.token = state.fc.token;
      expectStatus(await api.post('/friends', { code: state.codeA }), 200);
      api.token = state.fa.token;
      expectStatus(await api.delete(`/friends/${state.fc.id}`), 200); // odrzucenie
      expectStatus(await api.delete(`/friends/${state.fb.id}`), 200); // usunięcie znajomego
      const after = await api.get('/friends');
      expect(after.body.friends.length === 0 && after.body.incoming.length === 0, 'listy nie są puste');
    },
  },
];
