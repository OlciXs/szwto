export type RankKind = 'LEVEL' | 'CATEGORY' | 'ACHIEVEMENT';

export interface RankDefinition {
  id: string;
  name: string;
  description: string;
  kind: RankKind;
  minLevel?: number;
  category?: 'SAKRALNY' | 'MOST' | 'KAMIENICA';
  achievementId?: string;
}

export const SELECTABLE_RANKS: RankDefinition[] = [
  {
    id: 'level-tourist',
    name: 'Turysta',
    description: 'Osiągnij poziom 1.',
    kind: 'LEVEL',
    minLevel: 1,
  },
  {
    id: 'level-walker',
    name: 'Spacerowicz',
    description: 'Osiągnij poziom 3.',
    kind: 'LEVEL',
    minLevel: 3,
  },
  {
    id: 'level-explorer',
    name: 'Odkrywca',
    description: 'Osiągnij poziom 5.',
    kind: 'LEVEL',
    minLevel: 5,
  },
  {
    id: 'level-tracker',
    name: 'Tropiciel',
    description: 'Osiągnij poziom 8.',
    kind: 'LEVEL',
    minLevel: 8,
  },
  {
    id: 'level-guide',
    name: 'Przewodnik',
    description: 'Osiągnij poziom 11.',
    kind: 'LEVEL',
    minLevel: 11,
  },
  {
    id: 'level-heritage',
    name: 'Strażnik Dziedzictwa',
    description: 'Osiągnij poziom 17.',
    kind: 'LEVEL',
    minLevel: 17,
  },
  {
    id: 'level-legend',
    name: 'Legenda Wrocławia',
    description: 'Osiągnij poziom 20.',
    kind: 'LEVEL',
    minLevel: 20,
  },
  {
    id: 'category-sacral',
    name: 'Pielgrzym',
    description: 'Odkryj wszystkie obiekty sakralne.',
    kind: 'CATEGORY',
    category: 'SAKRALNY',
  },
  {
    id: 'category-bridges',
    name: 'Władca Mostów',
    description: 'Odkryj wszystkie mosty.',
    kind: 'CATEGORY',
    category: 'MOST',
  },
  {
    id: 'category-tenements',
    name: 'Kamienicznik',
    description: 'Odkryj wszystkie kamienice.',
    kind: 'CATEGORY',
    category: 'KAMIENICA',
  },
  {
    id: 'achievement-legends',
    name: 'Łowca Legend',
    description: 'Odblokuj osiągnięcie „Wszystkie legendy”.',
    kind: 'ACHIEVEMENT',
    achievementId: 'legendary-all',
  },
  {
    id: 'achievement-versatile',
    name: 'Wszechstronny',
    description: 'Odblokuj osiągnięcie „Wszechstronny”.',
    kind: 'ACHIEVEMENT',
    achievementId: 'all-categories',
  },
];
