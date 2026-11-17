-- Sports card collection.
--
-- Players earn sports cards (football, netball, rugby, hockey, sprinting,
-- swimming) from treasure chests on the Bubble Shooter level map. Each chest
-- opens once per player, so [source] — the chest that gave the card, e.g.
-- 'bubble_shooter_chest_5' — is unique per player alongside the card itself.
--
-- Players can read and add their own cards only; nothing updates or deletes
-- them from the app.

create table public.sports_collection (
  id         uuid primary key default gen_random_uuid(),
  player_id  uuid not null references auth.users on delete cascade,
  sport_id   text not null check (
    sport_id in ('football', 'netball', 'rugby', 'hockey', 'sprinting',
                 'swimming')
  ),
  source     text not null,
  earned_at  timestamptz not null default now(),
  unique (player_id, sport_id),
  unique (player_id, source)
);

alter table public.sports_collection enable row level security;

create policy "Players can see their own sports cards"
  on public.sports_collection for select
  using ((select auth.uid()) = player_id);

create policy "Players can add their own sports cards"
  on public.sports_collection for insert
  with check ((select auth.uid()) = player_id);
