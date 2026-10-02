# Changelog

## 1.0.1

- Fixed for the latest WoW: Forever update (build 70170). The game now identifies itself differently to addons, and Outfitter stopped recognising it: Lua errors every time a tooltip closed, and Forever's own handling (ranged slot, stances, talent trees, the button by the character window) switched off. Outfitter recognises both the old and the new client now.
- Outfits that follow a buff (Hunter aspects, Ghost Wolf, dining, ...) no longer come off when combat starts. Buffs can't be read in combat, so they keep their state until after it.

## 1.0.0

First release: Outfitter on WoW: Forever. Based on Outfitter (Retrofit) 5.5.4.3.

- Loads on WoW: Forever.
- Manages the ranged slot (bows, guns, crossbows, wands, thrown, relics), with its own outfit checkbox.
- Warrior stance outfits follow Battle, Defensive and Berserker Stance.
- Scripts limited to some specializations use your talent trees.
- The Outfitter button and window fit Forever's character window.
- Escape closes Outfitter's dialogs without changing Blizzard's code.
- No errors from values Forever hides from addons (your health and mana, buffs in combat, some names).
- Outfit bar icon picker, outfit tooltips and quest checks use Forever's API.
- The Has Debuff and Cooking outfits, fish tracking, and helm and cloak display work on Forever.
- Buff and debuff outfits keep their state in combat instead of coming off.
- The Dining outfit stays on until the food or drink buff ends.
- The Outfitter Forever logo in the addon list, the addon compartment and broker displays.
- Outfitter hooks Blizzard's frames instead of replacing their scripts.
