import { Api, expect, expectStatus, SmokeCheck } from '../lib';

/** Tor D: forum (tylko po wizycie i na miejscu), gablotka, profile publiczne, ranking. */

async function newPlayer(api: Api, prefix: string) {
  const res = await api.post('/auth/register', {
    email: `smoke_${prefix}_${Date.now()}@test.local`,
    password: 'smoke-test-123',
  });
  expectStatus(res, 201);
  return { token: res.body.accessToken as string, id: res.body.user.id as number };
}

/** ~1,1 km na północ – poza promieniem każdego zabytku. */
const farFrom = (m: any) => ({ latitude: m.latitude + 0.01, longitude: m.longitude });
const at = (m: any) => ({ latitude: m.latitude, longitude: m.longitude });

export const checks: SmokeCheck[] = [
  {
    name: 'Dwóch graczy: A odwiedza Ratusz, B nie',
    run: async ({ api, state }) => {
      state.a = await newPlayer(api, 'socA');
      state.b = await newPlayer(api, 'socB');
      api.token = state.a.token;
      const list = (await api.get('/monuments')).body as any[];
      state.ratusz = list.find((m) => m.name === 'Ratusz') ?? list.find((m) => m.rarity === 'LEGENDARY');
      state.other = list.find((m) => m.id !== state.ratusz.id && !m.visited);
      const visit = await api.post(`/monuments/${state.ratusz.id}/visit`, at(state.ratusz));
      expectStatus(visit, 200);
    },
  },
  {
    name: 'Komentarz z daleka jest odrzucany (trzeba być na miejscu)',
    run: async ({ api, state }) => {
      api.token = state.a.token;
      const res = await api.post(`/monuments/${state.ratusz.id}/comments`, {
        body: 'Z kanapy',
        ...farFrom(state.ratusz),
      });
      expectStatus(res, 403);
      return res.body.message;
    },
  },
  {
    name: 'A komentuje na miejscu → osiągnięcie „Głos zabrany”',
    run: async ({ api, state }) => {
      api.token = state.a.token;
      const res = await api.post(`/monuments/${state.ratusz.id}/comments`, {
        body: '  Piękny gotyk, warto wejść do Piwnicy Świdnickiej!  ',
        ...at(state.ratusz),
      });
      expectStatus(res, 201);
      state.commentId = res.body.id;
      const ids = (res.body.rewards.newAchievements as any[]).map((a) => a.id);
      expect(ids.includes('comment-1'), `brak „Głos zabrany” (${ids})`);
      const again = await api.post(`/monuments/${state.ratusz.id}/comments`, {
        body: 'Spam',
        ...at(state.ratusz),
      });
      expectStatus(again, 429);
    },
  },
  {
    name: 'B (bez wizyty) nie może komentować, ale widzi komentarz A z poziomem',
    run: async ({ api, state }) => {
      api.token = state.b.token;
      const post = await api.post(`/monuments/${state.ratusz.id}/comments`, {
        body: 'Też tu jestem',
        ...at(state.ratusz),
      });
      expectStatus(post, 403);
      const list = await api.get(`/monuments/${state.ratusz.id}/comments`);
      expectStatus(list, 200);
      expect(list.body.visited === false, 'B nie powinien mieć statusu odwiedzenia');
      const c = list.body.comments.find((x: any) => x.id === state.commentId);
      expect(c, 'brak komentarza A');
      expect(c.body === 'Piękny gotyk, warto wejść do Piwnicy Świdnickiej!', 'komentarz nieprzycięty');
      expect(c.author.level >= 3 && c.isMine === false, 'zły autor / isMine');
      expect(!('email' in c.author), 'e-mail autora w odpowiedzi!');
      const del = await api.delete(`/comments/${state.commentId}`);
      expectStatus(del, 403);
      return `${c.author.displayName}, poziom ${c.author.level} (${c.author.rankName})`;
    },
  },
  {
    name: 'Gablotka: tylko odwiedzone i tylko odblokowane miejsca',
    run: async ({ api, state }) => {
      api.token = state.a.token;
      const ok = await api.put('/showcase/0', { monumentId: state.ratusz.id });
      expectStatus(ok, 200);
      expect(ok.body.showcase.slots[0].monument?.id === state.ratusz.id, 'zabytek nie trafił do gablotki');
      const notVisited = await api.put('/showcase/1', { monumentId: state.other.id });
      expectStatus(notVisited, 400);
      const locked = await api.put('/showcase/4', { monumentId: state.ratusz.id });
      expectStatus(locked, 403);
      // przeniesienie zamiast duplikatu
      const moved = await api.put('/showcase/1', { monumentId: state.ratusz.id });
      expectStatus(moved, 200);
      const slots = moved.body.showcase.slots as any[];
      expect(slots[0].monument === null && slots[1].monument?.id === state.ratusz.id, 'zabytek zduplikowany');
      return `${moved.body.showcase.unlockedSlots}/${moved.body.showcase.maxSlots} miejsc odblokowanych; ${locked.body.message}`;
    },
  },
  {
    name: 'Profil publiczny A (oglądany przez B) – bez e-maila, z gablotką',
    run: async ({ api, state }) => {
      api.token = state.b.token;
      const res = await api.get(`/users/${state.a.id}`);
      expectStatus(res, 200);
      expect(!('email' in res.body), 'e-mail w profilu publicznym!');
      expect(res.body.isMe === false, 'isMe powinno być false');
      expect(res.body.showcase.slots[1].monument?.id === state.ratusz.id, 'brak gablotki');
      expect(res.body.achievements.unlockedCount >= 3, 'brak osiągnięć');
      return `${res.body.displayName}: poziom ${res.body.level}, ${res.body.visitedCount} odwiedzonych`;
    },
  },
  {
    name: 'Ranking: A wyżej niż B, pozycja „Ty”',
    run: async ({ api, state }) => {
      api.token = state.b.token;
      const res = await api.get('/users/leaderboard');
      expectStatus(res, 200);
      const all = res.body.entries as any[];
      const posA = all.find((e) => e.id === state.a.id)?.position ?? Infinity;
      expect(res.body.me?.id === state.b.id, 'brak pozycji „Ty”');
      expect(posA < res.body.me.position, 'A powinien być wyżej niż B');
      expect(all.every((e) => !('email' in e)), 'e-mail w rankingu!');
      return `${res.body.totalPlayers} graczy, B na miejscu ${res.body.me.position}`;
    },
  },
  {
    name: 'Zmiana nazwy gracza (zajęta nazwa = 409) i usunięcie własnego komentarza',
    run: async ({ api, state }) => {
      api.token = state.a.token;
      const name = `Tester_${Date.now() % 100000}`;
      const ok = await api.patch('/users/me', { displayName: name });
      expectStatus(ok, 200);
      api.token = state.b.token;
      const taken = await api.patch('/users/me', { displayName: name });
      expectStatus(taken, 409);
      api.token = state.a.token;
      const del = await api.delete(`/comments/${state.commentId}`);
      expectStatus(del, 200);
    },
  },
];
