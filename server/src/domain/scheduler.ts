// Port of lib/firebase/firestore/esport/league/match/round_robin_scheduler.dart.

export interface Pairing {
  homeId: string;
  awayId: string;
  /** 1-based, relative to the leg being generated. */
  matchday: number;
}

export interface ExistingFixture {
  homeId: string;
  awayId: string;
}

export function distinctIds(ids: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const id of ids) {
    if (!id || seen.has(id)) continue;
    seen.add(id);
    out.push(id);
  }
  return out;
}

/**
 * One full round-robin leg via the circle method. Within a head-to-head,
 * whoever has hosted fewer times gets home advantage, so a second leg mirrors
 * the first. Returns [] for fewer than two distinct teams.
 */
export function buildRoundRobinSchedule(teamIds: string[], existing: ExistingFixture[]): Pairing[] {
  const teams = distinctIds(teamIds);
  if (teams.length < 2) return [];

  const homeCounts = new Map<string, number>();
  for (const f of existing) {
    const k = `${f.homeId}|${f.awayId}`;
    homeCounts.set(k, (homeCounts.get(k) ?? 0) + 1);
  }
  const hosted = (home: string, away: string) => homeCounts.get(`${home}|${away}`) ?? 0;

  const bye = "";
  let rotation = [...teams, ...(teams.length % 2 === 1 ? [bye] : [])];
  const size = rotation.length;
  const schedule: Pairing[] = [];

  for (let round = 0; round < size - 1; round++) {
    for (let i = 0; i < size / 2; i++) {
      let home = rotation[i]!;
      let away = rotation[size - 1 - i]!;
      if (home === bye || away === bye) continue;

      // Alternate the fixed team's ground between matchdays.
      if (i === 0 && round % 2 === 1) [home, away] = [away, home];

      if (hosted(away, home) < hosted(home, away)) [home, away] = [away, home];

      schedule.push({ homeId: home, awayId: away, matchday: round + 1 });
    }
    rotation = [rotation[0]!, rotation[size - 1]!, ...rotation.slice(1, size - 1)];
  }
  return schedule;
}
