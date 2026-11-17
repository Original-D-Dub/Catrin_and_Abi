-- Hints used in the run that set a player's personal best.
--
-- Card matching's Champion Mode lets players reveal a card's pair up to
-- three times per game. When a run sets a new personal best, the number of
-- hints it used is stored alongside it so the scores page can show it.
-- Null for games without hints and for bests recorded before this column.

alter table public.player_stats
  add column best_hints smallint
    check (best_hints is null or best_hints >= 0);
