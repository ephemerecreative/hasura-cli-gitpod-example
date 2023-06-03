-- Reset the "fake_demo_events" table:
TRUNCATE "public"."fake_demo_events";

-- Populate with randomic data:
-- (this query was generated by ChatGPT)
INSERT INTO "public"."fake_demo_events" (created_at, data)
SELECT
    NOW() - INTERVAL '7 days' * RANDOM() AS created_at,
    jsonb_build_object(
        'goals_scored', FLOOR(RANDOM() * 6),
        'corners', FLOOR(RANDOM() * 11),
        'yellow_cards', FLOOR(RANDOM() * 4),
        'red_cards', FLOOR(RANDOM() * 2)
    ) AS data
FROM generate_series(1, 1000);