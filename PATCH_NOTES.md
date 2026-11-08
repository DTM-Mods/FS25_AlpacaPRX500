# Alpaca PRX500 – Patch notes

## 1.14.1.0 – 2026-11-08 – Productivity shows bonuses; straw check

Untested in game.

- **Productivity row** on the barn's info screen now shows the real total with the straw bedding and hay bonuses (e.g. **110%** with full bedding), instead of stopping at 100%.
- **Straw not going down (being investigated):** the log now gets one line per in-game hour with the straw level before and after, to find out why it stays full.

## 1.14.0.0 – 2026-11-08 – Hay 105%

Untested in game.

- **Hay is worth 5% more** than the sheep's hay value: shown as **Hay (105%)** on the barn's info screen.
- How it works: the part of each hour's food that was hay adds up to **+5% fleece output** (all hay = +5%, half hay = +2.5%).
- Done as an output bonus (like the straw bedding) so the barn stays safe in multiplayer.

## 1.13.0.0 – 2026-11-08 – 5,000 l fleece pallets

Untested in game.

- **Fleece pallets from this barn hold 5,000 l** (the DLC's own fleece pallet holds 2,000 l).
- They use the game's wool-bag pallet look, filled with alpaca fleece; not sold in the shop.
- Fleece pallets already made before this version stay at 2,000 l.

## 1.12.0.0 – 2026-11-08 – Food at sheep %, pallets stack 2 high

Untested in game.

- **Food effectiveness matches the sheep on the map.** Alpaca grass gets the sheep's grass %, alpaca hay gets the sheep's hay %. On maps where sheep get 100% for both, **Grass and Meadow (pasture) are 100%** for alpacas too.
- **Fleece pallets can stack 2 high** on the 6 spawn rows in the garage (each spawn spot allows up to 4 m; a fleece pallet is about 1.8 m).

## 1.11.2.0 – 2026-11-08 – Food fix

Untested in game.

- **Trough food now gets eaten.** On maps where sheep keep grass and hay in one food group, fresh grass was counted as alpaca *hay* (100%). The pasture supplies fresh grass, so the alpacas grazed it as top food and never touched the trough.
- Food types are now sorted one by one: dry grass, dry alfalfa and dry clover are **Hay**; fresh grass, alfalfa and clover are **Grass**.
- As a result **Meadow** (pasture) counts as Grass at **60%**.
- Like before, this applies to every alpaca barn while this mod is loaded.

## 1.11.1.0 – 2026-11-08 – Round lamp removed

Untested in game.

- **Round ceiling lamp removed** from the shearing room.
- The room's existing **tube light** is now the one that's **always on** (day and night); before, it only came on at night.

## 1.11.0.0 – 2026-11-08 – Shelf, flowers and ceiling light

Untested in game.

- **Wall shelf** on the back wall of the shearing room, left of the wagon wheel.
- **Box of red geraniums** on the shelf.
- **Small ceiling lamp** in the shearing room, **always on** (day and night).

## 1.10.4.0 – 2026-11-08 – Fleece pallet moved

Untested in game.

- **Fleece pallet** in the shearing room moved to the front of the rope pile, at the edge of the stall.

## 1.10.3.0 – 2026-11-08 – Wagon wheel, fleece pallet by the ropes

Untested in game.

- **Old wagon wheel** hangs flat on the back wall of the shearing room.
- **One fleece pallet** moved into the shearing room, right up against the rope pile. The other stays in the corridor.

## 1.10.2.0 – 2026-11-08 – Ropes on the floor, fleece pallets

Untested in game.

- **Halter ropes** taken off the wall (they showed through to the other side); now a pile on the floor of the shearing room.
- **Two fleece pallets** stand on the floor in the corridor by the shearing room, for looks only.

## 1.10.1.0 – 2026-11-08 – Shearing room fixes

Untested in game.

- **Halter ropes** no longer go through the back wall; moved out to hang in front of it.
- **Broom** taken off the workbench; it now stands on the floor in the corner by the window, leaning against the wall.

## 1.10.0.0 – 2026-11-08 – Shearing room and pallet bays

Untested in game.

- **Shearing room** (the old milking stall) is furnished:
  - a workbench with tools and a blade
  - a wooden table with tools, and a stool
  - halter ropes hanging on the back wall
  - The middle stays clear for shearing.
- **Pallet area** in the garage:
  - White painted lines frame it, in 3 bays.
  - The game's floating pallet icon hangs over it.
- **Pallet spawn height** lowered to just above the garage floor (they were set 0.3 m up).
- All new items are base-game models: no extra download size, and they work on every map.

## 1.9.3.0 – 2026-11-08 – Meadow same as grass

Untested in game.

- **Meadow** (pasture grazing) now counts the same as grass: 60% instead of 100%, matching whatever grass is on the map.
- Like the grass/hay food change, this applies to every alpaca barn while this mod is loaded, because the food list belongs to the animal.

## 1.9.2.0 – 2026-11-08 – Pasture fix and shop picture

Untested in game.

- **Pasture can be customised again.** The alpaca fence from the Beans & Alpacas DLC didn't load, so there was no pasture to set when placing the barn. This also caused the "Navigation mesh node not defined" error, because the alpacas' walking area is built from the fence outline.
- **Shop picture:** transparent background, like the other buildings in the list (the green is gone).
- **Unchanged:** the mod icon in the mod list.

## 1.9.1.0 – 2026-11-08 – First build

Untested in game.

- New placeable: **Alpaca PRX500**, a large alpaca barn built on the Hörmann barn, with its own covered fleece pallet shed.
- **Needs the Beans & Alpacas DLC.**
- **Alpacas:** holds at least 100.
- **Shearing:** spot in the old milking stall.
- **Fleece:** comes out as pallets (up to 8) on 6 rows inside an Open Wooden Garage next to the barn, open side facing the barn, on a 7 × 16 m concrete pad.
- **Food:** grass and hay, the same as sheep on any map (including alfalfa, clover and map crops). Holds 360,000 l.
- **Straw bedding:**
  - Holds 120,000 l.
  - Used up every day at the same rate pigs use straw.
  - Production follows the bedding level in a straight line: 110% when full, 85% when empty (half full = 97.5%).
  - No manure.
- **Water:** automatic; you pay for the water used.
- **Not in this barn:** no milk, no slurry, no manure.
- **Solar panels:** one shop option for the barn and the garage together: +$82,500, up to $287 an hour in full sun (less in winter, rain and at night).
- **Price:** $268,200. **Upkeep:** $268 a day.
- **Footprint:** 65 × 28.5 m, the same as the Fed goat barns. The placement check covers the whole building, garage included.
