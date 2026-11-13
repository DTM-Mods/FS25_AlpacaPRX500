<p align="center">
  <a href="https://github.com/DTM-Mods"><img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/dtm-header.jpg" alt="DTM Mods by PropaineX & Fennell" width="100%"></a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/icons/FS25_AlpacaPRX500.png" alt="Alpaca PRX500 icon" width="128">
</p>

<h1 align="center">Alpaca PRX500</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Farming%20Simulator-25-2E6B4F" alt="Farming Simulator 25">
  <a href="https://github.com/DTM-Mods/FS25_AlpacaPRX500/releases/latest"><img src="https://img.shields.io/github/v/release/DTM-Mods/FS25_AlpacaPRX500?label=version&color=D9A441" alt="Latest version"></a>
  <a href="https://github.com/DTM-Mods"><img src="https://img.shields.io/badge/DTM-Mods-143326" alt="DTM Mods"></a>
</p>

<p align="center">
  <b>A large alpaca barn with its own covered fleece pallet shed.</b><br>
  <sub>by PropaineX</sub>
</p>

<p align="center">
  <a href="https://github.com/DTM-Mods/FS25_AlpacaPRX500/releases/latest"><img src="https://img.shields.io/badge/Download-latest%20release-D9A441?style=for-the-badge&logo=github&logoColor=143326&labelColor=E9C77A" alt="Download the latest release"></a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/features.jpg" alt="Features" width="100%">
</p>

A Farming Simulator 25 placeable by PropaineX: a large alpaca barn with its own covered fleece pallet shed.

**Requires the Beans & Alpacas DLC.**

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

<!-- dtm-screenshots -->

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/screenshots.jpg" alt="Screenshots" width="100%">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/screens/FS25_AlpacaPRX500/shop.jpg" alt="Alpaca PRX500" width="100%">
</p>

<!-- /dtm-screenshots -->

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/installation.jpg" alt="Installation" width="100%">
</p>

Download `FS25_AlpacaPRX500.zip` from the [latest release](https://github.com/DTM-Mods/FS25_AlpacaPRX500/releases/latest) and put it in `Documents/My Games/FarmingSimulator2025/mods`, without unzipping or renaming it. In multiplayer, the server and every player need the same version.

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/license.jpg" alt="License" width="100%">
</p>

MIT, see [LICENSE](LICENSE). Anything here that comes from Farming Simulator 25 or its DLC (models, textures, sounds and other game files) belongs to GIANTS Software and is not covered by it.

<details>
<summary><b>For developers</b>: files, building and tests</summary>

### Files

- `modDesc.xml`: mod description and the custom placeable type.
- `placeables/alpacaPRX500/`: the barn's settings file, its model, and the shop picture.
- `scripts/`:
  - `PRXRandomCapacity.lua`: herd size.
  - `PRXAlpacaFood.lua`: alpacas eat what sheep eat.
  - `PRXStrawBedding.lua`: straw bedding and its production effect.
- `PATCH_NOTES.md`: changes per version. Not part of the mod zip.

To build the mod zip, zip the mod files with `modDesc.xml` at the root. Leave out `PATCH_NOTES.md`, `README.md` and `.gitignore`.

</details>

---

<p align="center">
  <a href="https://github.com/DTM-Mods"><img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/dtm-intro.gif" alt="DTM Mods by PropaineX & Fennell" width="420"></a><br>
  <sub>Part of <a href="https://github.com/DTM-Mods">DTM Mods</a> (Designed To Manage) by PropaineX & Fennell</sub>
</p>
