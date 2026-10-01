# Outfitter Forever

**Outfitter, ported to World of Warcraft: Forever.**

Outfitter is an equipment management addon that gives you fast access to multiple outfits to optimize your abilities in PvE and PvP, automated equip and unequip for convenience doing a variety of activities, or to enhance role-playing.

This is the same Outfitter you know, with the same windows, menus, outfits and scripts. It's based on [Outfitter (Retrofit)](https://www.curseforge.com/wow/addons/outfitter-retrofit) 5.5.4.3 by GovtGeek, which continues [Outfitter](https://www.curseforge.com/wow/addons/outfitter) by John Stephen (Mundocani). The only changes are the ones Forever needs.

---

## Features

- **Outfits.** Save any set of gear as an outfit and put it on with one click. Outfits come in four kinds:
  - **Complete wardrobes** have an item for every slot and replace whatever you're wearing.
  - **Mix-n-match** outfits cover some slots and go on top of your complete wardrobe.
  - **Accessories** cover some slots, and you can wear as many as you like at once (fishing pole, Carrot on a Stick, ...).
  - **Special occasions** go on by themselves at the right time.
- **Ready-made outfits.** On first use Outfitter saves your current gear as **Normal**, makes a **Birthday Suit**, and builds outfits from items it finds in your bags.
- **Automatic outfits.** Riding, swimming, fishing, dining, spirit regen, cities, battlegrounds, dungeons, PvP flagged, resting, falling, warrior stances, druid forms, rogue stealth, Feign Death, and more. Each is just a script, and you can turn any of them off.
- **Scripts.** Attach a ready-made script to an outfit, or write your own, to decide when it goes on and comes off.
- **Outfit bar.** An icon bar for one-click access, horizontal or vertical, that expands away from the nearest screen corner.
- **Minimap menu.** Every outfit from the minimap button.
- **Generate outfits.** Build an outfit that maximizes a stat or a combination of stats, or uses your Pawn weights (needs Pawn).
- **Icon picker.** Search thousands of icons for your outfits.
- **QuickSlots.** Click an inventory slot to see the items in your bags that fit it.
- **Item comparisons and tooltips.** Item tooltips show which outfits use the item.
- **Key bindings and macros.** Bind outfits to keys, or use `/outfitter` commands in macros.
- **Equipment Manager.** Store outfits on the server with Blizzard's Equipment Manager.
- **LibDataBroker** support.

## What's different on Forever

- **The ranged slot.** Bows, guns, crossbows, wands, thrown weapons and relics are managed in their own slot, with an outfit checkbox on the character window.
- **Warrior stances.** The Battle, Defensive and Berserker Stance outfits follow your three stances.
- **Talent trees.** Scripts that can be limited to some specializations use your talent trees.
- **Character window.** The Outfitter button sits at the top right of your character, beside the arrow that hides the stats pane. The Outfitter window opens to the right of the character window's tabs.
- **Escape** closes Outfitter's dialogs without touching Blizzard's code (so it can't cause "action blocked" errors).

### Limits on Forever

Forever hides some things from addons. These work a little differently because of it:

- **Low Health / Low Mana outfit** can't tell your health or mana, so it never changes your gear.
- **Spirit regen (five-second rule)** can't read your mana, so it treats any spell cast followed by a mana change as mana spent.
- **Buffs can't be read in combat.** Outfits that depend on a buff (riding, dining, Has Buff, ...) update when combat ends.
- **Armor can't be changed in combat** (the game's rule, as always). Outfitter puts the outfit on as soon as combat ends.

## Installation

1. Download the latest release.
2. Unzip it into your WoW: Forever `Interface\AddOns` folder so you end up with an `AddOns\OutfitterForever\` folder.
3. Restart the game, or type `/reload` if it's already running.

Don't install another copy of Outfitter alongside it.

## Using it

- **Open Outfitter.** Open your character window (`C`) and click the Outfitter button at the top right of your character, or left-click the minimap button for the outfit menu.
- **Make an outfit.** Put on the gear, click **New Outfit**, and name it. Untick the slots the outfit shouldn't change.
- **Wear an outfit.** Click it in the Outfitter window, the minimap menu or the outfit bar.
- **Automatic outfits.** Use the menu to the right of an outfit to pick a script or turn it off.

| Command | What it does |
|---|---|
| `/outfitter help` | Lists all the commands |
| `/outfitter wear Name` | Puts on the outfit |
| `/outfitter unwear Name` | Takes the outfit off |
| `/outfitter toggle Name` | Puts it on or takes it off |

## Feedback

Found a bug or have an idea? Open an issue on GitHub.

## Credits

- **John Stephen (Mundocani)**, who created Outfitter.
- **GovtGeek**, for Outfitter (Retrofit), and everyone credited in the addon's About tab.
- WoW: Forever port by **severd8**.

## License

MIT. See [LICENSE](LICENSE).
