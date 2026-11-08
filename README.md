# FS25 Alpaca PRX500

A Farming Simulator 25 placeable by PropaineX: a large alpaca barn with its own covered fleece pallet shed.

**Requires the Beans & Alpacas DLC.**

## Features
- Holds at least 100 alpacas.
- Shearing spot in the old milking stall.
- Fleece pallets on 6 rows inside an Open Wooden Garage, open side facing the barn.
- Food: grass and hay, the same as sheep on any map (alfalfa, clover and map crops included), 360,000 l.
- Straw bedding: 120,000 l.
  - Used up daily at the pig rate.
  - Production 110% when full, falling in a straight line to 85% when empty.
  - No manure.
- Automatic water (paid).
- No milk, no slurry.
- Solar panels as one option for barn and garage.
- Price $268,200, upkeep $268/day.

## Files
- `modDesc.xml`: mod description and the custom placeable type.
- `placeables/alpacaPRX500/`: the barn's settings file, its model, and the shop picture.
- `scripts/`:
  - `PRXRandomCapacity.lua`: herd size.
  - `PRXAlpacaFood.lua`: alpacas eat what sheep eat.
  - `PRXStrawBedding.lua`: straw bedding and its production effect.
- `PATCH_NOTES.md`: changes per version. Not part of the mod zip.

To build the mod zip, zip the mod files with `modDesc.xml` at the root. Leave out `PATCH_NOTES.md`, `README.md` and `.gitignore`.
