import { newId } from "../ids.js";

export interface NewMatch {
  id: string;
  homeTeamId: string;
  awayTeamId: string;
  phase: "group" | "knockout" | null;
  groupLabel: string | null;
  knockoutRound: number | null;
  knockoutSlot: number | null;
  nextMatchId: string | null;
  matchday: number | null;
}

export const isPowerOfTwo = (n: number) => n >= 2 && (n & (n - 1)) === 0;

export const groupLabel = (index: number) => String.fromCharCode("A".charCodeAt(0) + index);

const baseMatch = (homeTeamId: string, awayTeamId: string): NewMatch => ({
  id: newId(),
  homeTeamId,
  awayTeamId,
  phase: null,
  groupLabel: null,
  knockoutRound: null,
  knockoutSlot: null,
  nextMatchId: null,
  matchday: null,
});

/** Every pair of [teamIds] once, in list order (group-stage round). */
export function groupStageMatches(label: string, teamIds: string[]): NewMatch[] {
  const out: NewMatch[] = [];
  for (let i = 0; i < teamIds.length; i++) {
    for (let j = i + 1; j < teamIds.length; j++) {
      out.push({ ...baseMatch(teamIds[i]!, teamIds[j]!), phase: "group", groupLabel: label });
    }
  }
  return out;
}

/**
 * Single-elimination skeleton for [size] slots. With [seeding] (length ==
 * size), round 0 slot s pairs seeding[s] vs seeding[size-1-s]; later rounds
 * start empty. Winners advance to (round+1, slot/2).
 */
export function knockoutMatches(size: number, seeding: string[] | null): NewMatch[] {
  const totalRounds = Math.round(Math.log2(size));
  const r0Slots = size / 2;
  const ids = Array.from({ length: totalRounds }, (_, r) =>
    Array.from({ length: r0Slots >> r }, () => newId()),
  );
  const out: NewMatch[] = [];
  for (let r = 0; r < totalRounds; r++) {
    for (let s = 0; s < r0Slots >> r; s++) {
      const seeded = r === 0 && seeding !== null;
      out.push({
        ...baseMatch(seeded ? seeding[s]! : "", seeded ? seeding[size - 1 - s]! : ""),
        id: ids[r]![s]!,
        phase: "knockout",
        knockoutRound: r,
        knockoutSlot: s,
        nextMatchId: r < totalRounds - 1 ? ids[r + 1]![s >> 1]! : null,
      });
    }
  }
  return out;
}
