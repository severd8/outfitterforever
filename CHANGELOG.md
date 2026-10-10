# Changelog

## 1.3.4

- **Outfit bar:** the outfit you wear now has a bright gold edge instead of a red wash, and the highlight under your mouse lines up with each button.

## 1.3.3

- **Outfit bar:** the buttons no longer overlap. Each sits in its own space on the dark panel.
- **Outfit bar settings:** Vertical, Lock Position and Hide Background each have their own switch again; they were drawn on top of each other.

## 1.3.2

- **The outfit bar and menus in the new look.** The outfit bar is a flat dark panel with a thin gold edge and flat icon buttons; the outfit you wear has a dark red wash. Its settings and the icon picker match the rest of Outfitter Forever, and every Outfitter menu is a flat dark panel with a dark red row under the mouse.
- **Update to current items** is now right under Rename at the top of the outfit menu: one click to save the gear you're wearing into an outfit.
- **Waiting for combat.** Gear can't change in combat. If you pick an outfit during a fight, one chat line says it goes on when combat ends. Outfit scripts (stances, forms) stay quiet.
- **Translations.** Outfitter Forever's own text is now in German, French, Chinese, Korean and Russian too.
- Smaller download: the old Outfitter manual is no longer included.

## 1.3.1

- **Edit Script dialog in the new look.** The window for an outfit's script now matches the rest of Outfitter Forever: a red header bar, Settings and Source tabs at the top, flat fields, on/off switches for yes/no settings, and flat Done and Cancel buttons. It works exactly as before.
- **One way to read the scripts switch.** In Options, "Disable all outfit scripts" is now an **Outfit scripts** switch that works like the one at the bottom of the outfit list: on means outfits with a script change by themselves. The two switches always agree.
- Fixed a rare error in a text helper shared with other addons.

## 1.3.0

The whole Outfitter Forever window has the new look now, not just its frame. Outfits work exactly as before.

- **Tabs at the top.** Outfits and Options sit under the red header bar instead of hanging below the window.
- **Outfit list.** Flat checkboxes, category names in orange capitals with a small arrow to fold them, and a flat menu button on each outfit. An outfit with a script shows the script's name in grey beside its name, where the gear icon was. The outfit you've selected has a dark red row with a red bar at its left.
- **Footer.** An **Outfit scripts** switch turns all automatic outfits off and on (the same as "Disable all outfit scripts" in Options), next to a flat **New Outfit** button.
- **Options.** On/off switches in three groups: Outfits, Tooltips and Quick access.
- **New Outfit dialog** and the checkboxes on your character's slots match the rest of the window.
- The outfit menu, the minimap menu and the outfit bar look the same as before.

## 1.2.2

- **Fixed: a reload could take gear off a new character.** On a character's first session, the gear you put on yourself wasn't saved. After a `/reload` or logging back in, the next automatic outfit change (a stance, a form, mounting) put you back in the gear you had when Outfitter first saw the character: newly filled slots were emptied, and chat showed "Can't find item" for anything you had sold. What you put on yourself is now saved properly.
- **Logging in never changes your gear.** Whatever you're wearing when you log in or reload is taken as it is, even if Outfitter's saved outfits say otherwise.

## 1.2.1

- **Works with Baganator.** If you use the Baganator bag addon with its equipment set groups, every outfit now gets its own group in your bags, not only the outfits stored on the server. The groups follow the order of your outfit list and update when you add, change, rename or delete an outfit. Nothing changes if you don't use Baganator.

## 1.2.0

- **Put your outfits in your own order.** Open the menu to the right of an outfit and pick **Move up** or **Move down**. The order is saved for each character and is used in the outfit list, the minimap menu and the outfit bar. New outfits go to the end of the list. **Sort this list by name** in the same menu puts a list back in A to Z order. Lists you haven't touched stay in A to Z order.
- **The Equipment Manager tab opens Outfitter Forever.** The second tab at the top of your character window (it used to say Equipment Manager) now shows the Outfitter Forever icon and opens and closes your outfits. The small Outfitter button is gone while that tab is showing; it comes back if you collapse the stats pane. To get the game's Equipment Manager tab back, untick **Use the Equipment Manager tab** in Options.
- The Outfits and Options tabs have a plain dark background. The large faded logo is gone.

## 1.1.1

- The scroll track beside the outfit list is flat and dark like the rest of the window. It was still the original stone art.

## 1.1.0

One look for Outfitter Forever, TauntMaster Forever and ToppedOff Forever.

- The Outfitter Forever window is a flat dark panel with a red header bar: the logo, then the name and version, and a flat X to close it.
- Chat lines start with the logo and "Outfitter Forever".
- Nothing else changes: the outfit list, tabs, buttons and dialogs are as they were.

## 1.0.4

Fixes from a code review. Nothing changes in how outfits work.

- Fixed: Outfitter wrote throwaway values into the game's shared variables every time it looked at an item in your bags or on your character. That can make the game blame Outfitter for blocked actions. Those values now stay inside Outfitter.
- Fixed: if something went wrong in the middle of a gear change, the game's sound effects could stay switched off (Outfitter mutes them while it swaps gear). They're now always switched back on.
- Fixed: the comparison tooltip (the item you're wearing, shown next to the one under your mouse) listed the outfits that use the item under your mouse. It now lists the outfits that use the item it shows, and a comparison tooltip the game isn't showing is left alone.
- Fixed: the icon picker's list of your items left out the items you're wearing.
- Fixed: four error messages that caused a Lua error instead of being shown (a menu item without its outfit, a missing window part, a stat item without a slot, and "bags are full" for a worn item).

## 1.0.3

- It's **Outfitter Forever** everywhere now: the window title, options, minimap menu, chat messages, tooltips and the keybindings group.
- The minimap button shows the Outfitter Forever logo. (It used to show the icon of the outfit you were wearing.)
- The Outfits and Options tabs have the logo as their faint background.
- The About tab is gone. The first tab is now called Outfits.

## 1.0.2

- Fixed: "Open Outfitter" from the minimap menu (or a right-click on the minimap button, or the keybinding) caused a Lua error, "attempt to compare a secret number value". On WoW: Forever an addon can't open or close the character window without breaking the game's own health and mana text. Outfitter now leaves that window to you: if it's closed, Outfitter asks you to open it and then opens along with it. Type `/reload` once after updating.

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
