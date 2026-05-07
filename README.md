# PSPS Safe Parser Build

This workspace copy focuses on value parsing from explicit Lua tables and local fixtures.

## What changed

- Added `src/core/value_extractor.lua` to normalize rank, stars, max zone, and goals.
- Added `src/core/schema_mapper.lua` to list candidate rank/goal paths from explicit tables.
- Added `src/features/rank_planner.lua` to summarize rank-up readiness from normalized values.
- Added `src/fixtures/sample_savedata.lua` for local parser development.
- Reworked `src/core/savedata.lua` to expose normalized values.
- Reworked `src/debug/sniffer.lua` into a safe parser/diagnostics module.
- Reworked `src/features/quest_manager.lua` to produce a readable quest plan.
- Updated `loader.lua`, `src/ui/window.lua`, and `bundler.js` for the new flow.

## Use

Run:

```sh
npm run bundle
```

Then inspect `test_bundle.lua`.

You can parse a custom table with:

```lua
shared._PS99.Debug.Sniffer.ParseSource({
    Profile = {
        Data = {
            Rank = 4,
            Stars = 9,
            MaxZone = 18,
            Goals = {
                quest_1 = { Type = "BreakBreakables", Progress = 10, Amount = 50 }
            }
        }
    }
}, "custom sample")
```
