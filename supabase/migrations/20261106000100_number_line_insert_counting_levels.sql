-- Make 10 (number line) gained two counting levels at the front, so the
-- existing levels 1–3 are now levels 3–5. Stats are stored per level as
-- 'number_line_game_<n>', so move existing rows up by two to keep each
-- personal best on the level it was scored on. Highest first, so a moved
-- row never collides with one not yet moved.

update public.player_stats
  set game_id = 'number_line_game_5',
      level = case when level is null then null else 5 end
  where game_id = 'number_line_game_3';

update public.player_stats
  set game_id = 'number_line_game_4',
      level = case when level is null then null else 4 end
  where game_id = 'number_line_game_2';

update public.player_stats
  set game_id = 'number_line_game_3',
      level = case when level is null then null else 3 end
  where game_id = 'number_line_game_1';
