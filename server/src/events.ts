import { EventEmitter } from "node:events";

/**
 * In-process change feed for league snapshots. The API runs as a single
 * instance, so an EventEmitter is enough; switch to Postgres LISTEN/NOTIFY if
 * it ever scales out.
 */
export class LeagueEvents {
  private readonly emitter = new EventEmitter();

  constructor() {
    // One listener per open tournament screen.
    this.emitter.setMaxListeners(0);
  }

  publish(leagueId: string): void {
    this.emitter.emit(leagueId);
  }

  subscribe(leagueId: string, listener: () => void): () => void {
    this.emitter.on(leagueId, listener);
    return () => this.emitter.off(leagueId, listener);
  }
}
