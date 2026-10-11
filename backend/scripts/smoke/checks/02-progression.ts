import { expect, expectStatus, SmokeCheck } from '../lib';

/** Tor B: XP, poziomy, nagrody za poziom, osiągnięcia, zdarzenia (Wikipedia). */
export const checks: SmokeCheck[] = [
  {
    name: 'Nowy gracz zaczyna od 1. poziomu',
    run: async ({ api, state }) => {
      const res = await api.post('/auth/register', {
        email: `smoke_prog_${Date.now()}@test.local`,
        password: 'smoke-test-123',
      });
      expectStatus(res, 201);
      api.token = res.body.accessToken;

      const progress = await api.get('/progression');
      expectStatus(progress, 200);
      expect(progress.body.level === 1, `level=${progress.body.level}`);
      expect(progress.body.totalXp === 0, `totalXp=${progress.body.totalXp}`);
      expect(progress.body.perks.discoveryRadius === 250, 'zły startowy zasięg perełek');
      state.progMonuments = (await api.get('/monuments')).body;
      return `${progress.body.rank.name}, następna nagroda: ${progress.body.nextUnlock?.label} (poz. ${progress.body.nextUnlock?.level})`;
    },
  },
  {
    name: 'Legendarna wizyta: nowy poziom + osiągnięcia z premią XP',
    run: async ({ api, state }) => {
      const list = state.progMonuments as any[];
      const target = list.find((m) => m.rarity === 'LEGENDARY');
      expect(target, 'brak legendarnego zabytku');
      const res = await api.post(`/monuments/${target.id}/visit`, {
        latitude: target.latitude,
        longitude: target.longitude,
      });
      expectStatus(res, 200);
      const { progression, newAchievements } = res.body.rewards;
      expect(progression, 'brak rewards.progression');
      expect(progression.levelUp === true, 'brak awansu po legendarnej wizycie');
      expect(progression.level >= 3, `level=${progression.level}`);
      const ids = (newAchievements as any[]).map((a) => a.id);
      expect(ids.includes('visits-1'), `brak „Pierwszy krok” (${ids})`);
      expect(ids.includes('legendary-1'), `brak „Pierwsza legenda” (${ids})`);
      expect(
        progression.xpGained === target.xp + 25 + 50,
        `xpGained=${progression.xpGained}, oczekiwano ${target.xp + 75}`,
      );
      return `+${progression.xpGained} XP → poziom ${progression.level} (${progression.rank}), osiągnięcia: ${(newAchievements as any[]).map((a) => a.name).join(', ')}`;
    },
  },
  {
    name: 'Sekretne osiągnięcie: Pod pręgierzem',
    run: async ({ api, state }) => {
      const pillory = (state.progMonuments as any[]).find((m) => m.name === 'Pręgierz');
      expect(pillory, 'brak Pręgierza w danych');
      const res = await api.post(`/monuments/${pillory.id}/visit`, {
        latitude: pillory.latitude,
        longitude: pillory.longitude,
      });
      expectStatus(res, 200);
      const ids = (res.body.rewards.newAchievements as any[]).map((a) => a.id);
      expect(ids.includes('pillory'), `brak „Pod pręgierzem” (${ids})`);
      return `+${res.body.rewards.progression.xpGained} XP`;
    },
  },
  {
    name: 'Lista osiągnięć z postępem (sekretne ukryte)',
    run: async ({ api }) => {
      const res = await api.get('/achievements');
      expectStatus(res, 200);
      const all = res.body.achievements as any[];
      expect(res.body.total >= 40, `za mało osiągnięć: ${res.body.total}`);
      expect(all.find((a) => a.id === 'visits-1')?.unlocked, '„Pierwszy krok” nieodblokowany');
      const secretLocked = all.find((a) => a.secret && !a.unlocked);
      expect(secretLocked?.name === '???', 'sekretne osiągnięcie nie jest ukryte');
      const pillory = all.find((a) => a.id === 'pillory');
      expect(pillory?.name === 'Pod pręgierzem', 'odblokowane sekretne powinno mieć nazwę');
      return `${res.body.unlockedCount}/${res.body.total} odblokowanych`;
    },
  },
  {
    name: 'Otwarcie Wikipedii odblokowuje „Mól książkowy” (raz na zabytek)',
    run: async ({ api, state }) => {
      const monumentId = (state.progMonuments as any[])[0].id;
      const first = await api.post('/events', { type: 'WIKIPEDIA_OPENED', monumentId });
      expectStatus(first, 200);
      const ids = (first.body.rewards.newAchievements as any[]).map((a) => a.id);
      expect(ids.includes('reader-1'), `brak „Mól książkowy” (${ids})`);
      const again = await api.post('/events', { type: 'WIKIPEDIA_OPENED', monumentId });
      expect(again.body.rewards.newAchievements.length === 0, 'ponowne kliknięcie dało osiągnięcie');
      const bad = await api.post('/events', { type: 'COS_INNEGO' });
      expectStatus(bad, 400);
    },
  },
  {
    name: 'Profil zawiera poziom i osiągnięcia',
    run: async ({ api }) => {
      const res = await api.get('/profile');
      expectStatus(res, 200);
      expect(res.body.progression?.level >= 3, 'brak poziomu w profilu');
      expect(res.body.achievements?.unlockedCount >= 4, 'brak osiągnięć w profilu');
      return `poziom ${res.body.progression.level}, ${res.body.progression.totalXp} XP, ${res.body.achievements.unlockedCount} osiągnięć`;
    },
  },
];
