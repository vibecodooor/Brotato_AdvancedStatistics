# AdvancedStatistics integration regression

The opt-in `Local-AdvancedStatisticsRegression` fixture exercises the mod inside an owned Brotato development/test runtime. It uses base-game Well-Rounded characters and has no dependency on character packs or other UI mods.

Use a disposable copy of your test runtime, with Steam/Cloud disabled and these application settings:

```ini
[application]
config/name="AdvancedStatistics-Isolated-Test"
config/use_custom_user_dir=true
config/custom_user_dir_name="AdvancedStatistics-Isolated-Test"
```

Install this branch as `mods-unpacked/meinfesl-AdvancedStatistics`. Copy `Local-AdvancedStatisticsRegression` into `mods-unpacked` alongside it, or package it in a ModLoader ZIP with that directory prefix. Keep the fixture out of normal release ZIPs. It only starts when `--advstats-coop-test` is present and the user directory ends with the exact isolated directory name above.

Run the test runtime four times, passing `--advstats-coop-test --players=1`, then `--players=2`, `--players=3`, and `--players=4`. Run them sequentially because they use the same disposable profile. The final `ADVSTATS_RESULT` JSON lists the assertion count and failures; the exit code is nonzero on assertion failure. Also inspect the log for `SCRIPT ERROR`, because engine script exceptions do not necessarily change the process exit code.

Coverage includes distinct weapon damage and inventories, deep-copy snapshots, per-slot disk round trips, legacy saves without extra-player ledgers, shared material conversion, critical-hit income, healing, real enemy hits, pause-menu player switching, shop rerolls and weapon combinations, co-op end statistics, and clearing both direct/burning weapon ledgers. Targets for direct-hit assertions are spawned explicitly, so a cleared wave cannot make the test flaky.

Validation was performed on Brotato 1.1.15.4 with ModLoader 6.3.0 in a local macOS Godot 3 headless harness. The owned game, DLC, and private test-runtime compatibility files are not distributed here. This verifies script behavior and scene integration; native Windows execution, rendered layout and physical-controller navigation still require interactive testing. Existing headless renderer/resource shutdown warnings are separate from script exceptions.
