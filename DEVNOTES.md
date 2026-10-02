# Outfitter Forever — developer notes

Outfitter for **World of Warcraft: Forever** (interface 16001, client 1.60.x).

- Author of the port: `severd8`. License: MIT (keep John Stephen's notice).
- Based on **Outfitter (Retrofit) 5.5.4.3** by GovtGeek: https://github.com/GovtGeek/Outfitter. This repo keeps that history; the remote `upstream` points at it.
- CurseForge project ID: in the `.toc` as `X-Curse-Project-ID`.
- Sister addons: TauntMaster Forever and ToppedOff Forever, whose setup this mirrors.

## Rule for changes

Keep Outfitter exactly as it is. Only change what Forever needs, and keep each change small and marked, so upstream fixes can be merged later (`git fetch upstream`, then merge or cherry-pick).

## Files

- `OutfitterForever.toc` — upstream's Mainline TOC with interface 16001, the folder name `OutfitterForever` and `@project-version@` (filled in by the packager from the git tag).
- `Outfitter.xml` — upstream's `Mainline/Outfitter.xml` (Forever uses the Mainline UI). The Vanilla XML and the old `Mainline/*.lua` copies upstream no longer loads were removed.
- `OutfitterPrefix.lua` — `Outfitter.IsForever`, `Outfitter.IsMainlineClient`, `Outfitter.IsSecret`, `Outfitter:GetSpecialization()`, `Outfitter:GetSpecializationInfo()`.
- Everything else is upstream's code with the Forever changes below.
- `tests/` — offline tests (not shipped). See Testing.

## What Forever is

- The **Mainline client and UI** (Midnight 12.x API, "Camelot" variant of Blizzard's UI). Until build 70170 `WOW_PROJECT_ID` was Mainline's (1); since then the client reports its own, `WOW_PROJECT_CAMELOT` (18). `Outfitter.IsForever` (in `OutfitterPrefix.lua`) is true for either: the Camelot ID, or the Mainline ID with an interface number below 20000. `Outfitter.IsMainlineClient` is true on retail and on Forever. **Never compare `WOW_PROJECT_ID` with `WOW_PROJECT_MAINLINE` directly**: upstream does that to pick its Mainline code paths, and on Forever it's now false. Use `Outfitter.IsMainlineClient` (the file-local `IsMainline` in `Outfitter.lua` is set from it). The tests run under both project IDs.
- The **game is classic**: a ranged slot (and ammo slot, which Outfitter never managed), three warrior stances, talent trees reported as specializations (`C_SpecializationInfo`).
- `LE_EXPANSION_LEVEL_CURRENT` on Forever isn't known, so nothing depends on it for Forever. The tests run with both 0 and 11.
- Removed globals: `GetSpellInfo`, `GetItemInfo`, `GetSpecialization`, `GetSpecializationInfo`, `GetTalentInfo`, `GetTalentTabInfo`, `GetNumSkillLines`, `GetSpellTabInfo`, `GetSpellTexture`, `GetNumQuestLogEntries`, `UnitDefense`, `GetMouseFocus`, `BankButtonIDToInvSlotID`, `EquipmentFlyoutPopoutButton_SetReversed`, `EquipmentManager_UnpackLocation`. Use the `C_*` versions.
- **Secret values**: your own health, mana (`UnitPower`, `UnitPowerMax`), and some names are hidden from addons. Comparing, doing math on or concatenating one throws. Check `Outfitter.IsSecret(v)` first.
- **Auras throw in combat** ("Auras cannot be accessed when secret while tainted"). Call `C_UnitAuras` through `pcall`. `Outfitter:PlayerHasAuraNamed(name, filter)` returns `nil` when auras can't be read, and scripts must then change nothing. `canaccesssecrets()` isn't used on Forever (its value for addons is unknown).
- Registering an event the client doesn't have throws. MC2EventLib registers through `pcall`.
- **Taint**: never assign one of Blizzard's globals (even to wrap it), and never `SetScript` on Blizzard's frames (`MC2AddonLib`'s `hookScript` always uses `HookScript` on Forever). Adding to Blizzard tables (`UISpecialFrames`, `StaticPopupDialogs[key]`) and `hooksecurefunc` / `HookScript` are fine. The tests fail if a Blizzard global or a Blizzard frame's script is replaced.
- Don't register addon functions with `RegisterGameMenuEscHandler`: Blizzard's Escape loop would read the addon's entry and run the rest of Escape (game menu included) tainted.
- Removed or changed on the Mainline API that Outfitter used: `UnitDebuff`, `GetTradeSkillLine` (now `C_TradeSkillUI.GetBaseProfessionInfo`), `C_Minimap.GetTrackingInfo` returns a table (`Outfitter:GetTrackingInfo` handles both).

## Forever changes (search for `IsForever`, `IsRetail`, `IsSecret`)

- **Never open or close the character window from addon code** (`ToggleCharacter`, `ShowUIPanel(CharacterFrame)`, `CharacterFrame:Show()` / `:Hide()`). `CharacterFrameMixin:OnShow` and `OnHide` update the player frame's health and mana text (`ShowStatusBarText`, which compares the bar's values and writes `showNumeric` / `lockShow`). Those values are secret, so when the show was started by an addon the compare throws ("attempt to compare a secret number value (execution tainted by ...)"), and the fields it wrote stay tainted. `Outfitter:OpenUI` shows only `OutfitterFrame` when the window is already open; otherwise it prints `cOpenCharacterWindow` and sets `OpenWithCharacterWindow`, and `Outfitter:CharacterWindowShown` (hooked to `OutfitterButtonFrame`'s `OnShow`) opens Outfitter when the player opens the window within a minute. `ToggleUI` no longer closes the character window. The tests' fake client reports an error if the addon touches the window (`W.PlayerTogglesCharacter()` is the player doing it).

- **Slots** (`Outfitter.lua`): `RangedSlot` added on Forever; ranged item types stay in the ranged slot. `OutfitterOutfits.lua` no longer strips the ranged slot from outfits on Forever. `Outfitter.xml` has the `OutfitterEnableRangedSlot` checkbox (anchored to `CharacterRangedSlot`).
- **Character window** (`OutfitterButtonAdjust`): the button goes left of `CharacterFrame.RightPaneToggleButton`; `OutfitterFrame` opens right of `CharacterFrameModeTab1` (Forever has a column of tabs down the window's right edge). The retail `PaperDollSidebarTabs` nudge is skipped. Tab templates use `PanelTabButtonTemplate` (Forever has no `CharacterFrameTabTemplate`).
- **Specializations**: `TalentsChanged` (no Titan's Grip), `GetTalentTreeName`, and the preset scripts use `Outfitter:GetSpecialization()`.
- **Warrior stances**: the stance scripts use `Outfitter.IsRetail` (Mainline client *and* not Forever) instead of `IsMainline`, so Forever gets stance forms 1/2/3.
- **Secrets**: spirit regen (`UnitHealthOrManaChanged`), dining (`PlayerIsFull` is false while health is hidden, so Dining ends with the food buff), the Low Health and Equip on Target scripts, aura scanning. Your own `UnitHealth` and `UnitPower` are always secret; `UnitHealthMax` and `UnitPowerMax` aren't.
- **Aura states in combat**: `GetPlayerAuraStates` keeps the last states read before combat on Forever (upstream clears them, which took buff outfits off when combat started).
- **Auras in scripts**: Has Buff, Has Debuff (`"HARMFUL"` filter) and the Trinket Queue buff check do nothing when auras can't be read.
- **Helm and cloak display**: Forever has `ShowHelm` / `ShowCloak`, so outfits apply them (`OutfitterEquipment.lua`).
- **Cooking / Fishing scripts**: `Outfitter:TradeSkillIsCooking()` and `Outfitter:GetTrackingInfo()`.
- **Stats** (`OutfitterItemStats.lua`): Forever uses the original game's stat list, plus spell power.
- **Minimap button** radius is the modern minimap's.
- **Icon picker / cursor icons** (`OutfitterBar.lua`): `C_SpellBook` and `C_Spell`.
- **Escape** (`MC2UIElementsLib.lua`): a hidden, parentless frame (`OutfitterForeverDialogEscape`) in `UISpecialFrames` stands in for open dialogs instead of replacing `StaticPopup_EscapePressed`. Forever's Escape runs `CloseAllWindows`, so the character window closes on the same press.
- **Logo**: `Textures/Logo.tga` (64×64, made from `art/icon.svg`) is the addon list / compartment icon and the broker icon when no outfit is worn. Outfit icons, the minimap button and the window backgrounds are unchanged. `art/logo.svg` / `logo.png` are the CurseForge logo.
- **Folder name**: textures point at `Interface\AddOns\OutfitterForever\`; the version comes from `Outfitter.AddonName`.

## Testing

Run from the repo root before every commit:

    lua5.1 tests/run.lua

- `tests/wow.lua` — a fake Forever client. Globals resolve against `tests/forever_api.lua`; anything Forever doesn't have is nil, so calling a removed API fails like it would in game. Frame methods are checked against Forever's widget API. Loads the `.toc`, builds the XML (templates, `$parent` names, scripts, OnLoad order) and runs events and `OnUpdate`.
- `tests/fakes.lua` — the game state: a level 60 character, gear, bags, a cursor that moves items like the real one (including two-handers pushing off-hands into bags, and no armor changes in combat), auras (buffs and debuffs) that throw in combat, secret health and mana, minimap tracking, the trade skill window, Forever's character window frames.
- `tests/run_tests.lua` — the scenarios: load and log in, button/window placement, saving and wearing outfits, the ranged slot, combat, stance and other scripts (buffs, debuffs, dining, cooking, fishing), helm display, slash commands, minimap menu, tooltips, riding, options, Escape, and that no Blizzard global or frame script is replaced. A fake the addon uses that Forever doesn't have also fails.
- `tests/forever_api.lua` is generated by `tests/tools/make_forever_api.py` from Blizzard's Forever UI source (https://github.com/Gethe/wow-ui-source, `forever` branch) and the client's API reference (https://github.com/imperial64/forever-addon-dev). Rerun it after using a new API or Blizzard frame (instructions at the top of the script).

Only testable in game: layout and looks, real item swapping timing, Forever's exact secret and taint rules.

## Releasing

1. Run the tests and add a section at the top of `CHANGELOG.md`.
2. Commit and push to `main`. The **Tests** workflow must be green.
3. Tag in GitHub Desktop (History → right-click the commit → Create Tag → e.g. `v1.0.1` → Push origin).
4. **Package and release** runs the tests again and uploads to CurseForge. Needs the `CF_API_KEY` repository secret.
