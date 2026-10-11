import { Monument } from '@prisma/client';
import { commonsImage, commonsThumbUrl } from '../common/commons.util';

/**
 * Kształty odpowiedzi API dla zabytków – używaj ich także w innych modułach
 * (kolekcja, gablotka, gra), żeby aplikacja dostawała wszędzie te same pola.
 */

/** Wersja lekka – lista na mapie (bez opisów). */
export function toMonumentListItem(
  m: Monument,
  visit: { visitedAt: Date } | null,
) {
  return {
    id: m.id,
    name: m.name,
    category: m.category,
    rawType: m.rawType,
    rarity: m.rarity,
    // Główny = zawsze widoczny na mapie; pozostałe to ukryte perełki (odkrywane w zasięgu)
    isMajor: m.isMajor,
    latitude: m.latitude,
    longitude: m.longitude,
    thumbUrl: m.imageFile ? commonsThumbUrl(m.imageFile, 330) : null,
    builtYear: m.builtYear,
    builtLabel: m.builtLabel,
    era: m.era,
    xp: m.xp,
    visitRadius: m.visitRadius,
    visited: visit !== null,
    visitedAt: visit?.visitedAt ?? null,
  };
}

/** Karta zabytku – gablotka, profile, kolekcja (tor C). */
export function toMonumentCard(
  m: Pick<Monument, 'id' | 'name' | 'category' | 'rawType' | 'rarity' | 'imageFile' | 'builtLabel'>,
) {
  return {
    id: m.id,
    name: m.name,
    category: m.category,
    rawType: m.rawType,
    rarity: m.rarity,
    builtLabel: m.builtLabel,
    thumbUrl: m.imageFile ? commonsThumbUrl(m.imageFile, 330) : null,
  };
}

const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

/** Typ i data powstania, np. „Ratusz · XIII wiek”. */
export function monumentTeaser(m: Monument): string {
  const type = m.rawType ? capitalize(m.rawType) : 'Zabytek';
  return m.builtLabel ? `${type} · ${m.builtLabel}` : type;
}

/** Wersja pełna – ekran szczegółów. Długi opis dopiero po odwiedzeniu (#6). */
export function toMonumentDetails(
  m: Monument,
  visit: { visitedAt: Date } | null,
  visitorsCount: number,
) {
  const visited = visit !== null;
  return {
    ...toMonumentListItem(m, visit),
    teaser: monumentTeaser(m),
    /** 1–2 zdania z Wikipedii – widoczne zawsze */
    summary: m.summary,
    /** Długi opis historyczny (akapity oddzielone \n\n) – dopiero po wizycie */
    description: visited ? m.description : null,
    descriptionLocked: !visited,
    descriptionSource: m.descriptionSource,
    address: m.address,
    image: commonsImage(m.imageFile),
    heritageLevel: m.heritageLevel,
    registerNumber: m.registerNumber,
    // Link do artykułu dopiero po wizycie – inaczej omijałby blokadę historii
    wikipediaUrl: visited ? m.wikipediaUrl : null,
    source: m.source,
    externalId: m.externalId,
    visitorsCount,
  };
}
