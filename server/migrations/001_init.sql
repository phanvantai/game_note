-- Game Note schema. Ids are text so Firestore document ids carry over
-- unchanged during the one-shot import.
--
-- User ids are deliberately not foreign keys: legacy Firestore data can
-- reference users whose documents no longer exist, and the app already
-- renders those as unknown players.

CREATE TABLE users (
  id              text PRIMARY KEY,
  display_name    text,
  phone_number    text,
  email           text,
  photo_url       text,
  role            text NOT NULL DEFAULT 'user',
  is_placeholder  boolean NOT NULL DEFAULT false,
  deleted         boolean NOT NULL DEFAULT false,
  deleted_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX users_display_name_prefix ON users (lower(display_name) text_pattern_ops);
CREATE INDEX users_email_prefix ON users (lower(email) text_pattern_ops);
CREATE INDEX users_phone_prefix ON users (phone_number text_pattern_ops);

CREATE TABLE groups (
  id           text PRIMARY KEY,
  group_name   text NOT NULL DEFAULT '',
  owner_id     text NOT NULL,
  description  text NOT NULL DEFAULT '',
  status       text NOT NULL DEFAULT 'active',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX groups_owner ON groups (owner_id);

-- `position` preserves the order of the old `members` array.
CREATE TABLE group_members (
  group_id     text NOT NULL REFERENCES groups (id) ON DELETE CASCADE,
  user_id      text NOT NULL,
  position     integer NOT NULL,
  deactivated  boolean NOT NULL DEFAULT false,
  PRIMARY KEY (group_id, user_id)
);

CREATE INDEX group_members_user ON group_members (user_id);

CREATE TABLE leagues (
  id                        text PRIMARY KEY,
  owner_id                  text NOT NULL,
  group_id                  text NOT NULL REFERENCES groups (id) ON DELETE CASCADE,
  name                      text NOT NULL DEFAULT '',
  description               text NOT NULL DEFAULT '',
  start_date                timestamptz NOT NULL,
  end_date                  timestamptz,
  is_active                 boolean NOT NULL DEFAULT true,
  status                    text NOT NULL DEFAULT 'upcoming',
  -- Ordered list, as before. Small (a friend group), so an array with a GIN
  -- index is simpler than a join table.
  participants              text[] NOT NULL DEFAULT '{}',
  rank_payout_enabled       boolean NOT NULL DEFAULT false,
  rank_payouts              integer[] NOT NULL DEFAULT '{}',
  default_match_cost        integer NOT NULL DEFAULT 50000,
  default_per_goal_enabled  boolean NOT NULL DEFAULT false,
  default_cost_per_goal     integer NOT NULL DEFAULT 50000,
  merge_completed           boolean NOT NULL DEFAULT false,
  mode                      text NOT NULL DEFAULT 'league',
  group_count               integer NOT NULL DEFAULT 1,
  advance_count             integer NOT NULL DEFAULT 2,
  knockout_seeding          text[] NOT NULL DEFAULT '{}',
  -- Matchdays allocated so far in league mode (see generateRound).
  matchday_count            integer,
  created_at                timestamptz NOT NULL DEFAULT now(),
  updated_at                timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX leagues_group ON leagues (group_id);
CREATE INDEX leagues_owner ON leagues (owner_id);
CREATE INDEX leagues_active_start ON leagues (is_active, start_date DESC, id DESC);
CREATE INDEX leagues_participants ON leagues USING gin (participants);

-- Which standings rows a league has. The numbers are never stored: they are
-- folded from finished matches on read (see src/domain/standings.ts).
CREATE TABLE league_stat_rows (
  id           text PRIMARY KEY,
  league_id    text NOT NULL REFERENCES leagues (id) ON DELETE CASCADE,
  user_id      text NOT NULL,
  -- 'A', 'B', … for full-mode group stages; null for league-wide rows.
  group_label  text,
  UNIQUE NULLS NOT DISTINCT (league_id, user_id, group_label)
);

CREATE TABLE matches (
  id              text PRIMARY KEY,
  league_id       text NOT NULL REFERENCES leagues (id) ON DELETE CASCADE,
  home_team_id    text NOT NULL DEFAULT '',
  away_team_id    text NOT NULL DEFAULT '',
  home_score      integer,
  away_score      integer,
  date            timestamptz NOT NULL,
  is_finished     boolean NOT NULL DEFAULT false,
  match_cost      integer,
  cost_per_goal   integer,
  phase           text,
  group_label     text,
  knockout_round  integer,
  knockout_slot   integer,
  next_match_id   text,
  matchday        integer,
  -- Optimistic-lock version for score edits. Millisecond precision so the
  -- value survives a JSON round trip exactly.
  updated_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX matches_league ON matches (league_id);
CREATE INDEX matches_home ON matches (home_team_id) WHERE is_finished;
CREATE INDEX matches_away ON matches (away_team_id) WHERE is_finished;
