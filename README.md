# RSG Weed - Advanced Farming System

A comprehensive weed farming system for RedM (RSG Core), featuring multi-stage growth, water management, batch processing, and a unique water wagon rental system.

## Features

### 🌿 Advanced Farming
- **3 Unique Strains**: Kalka (Guarma Gold), Purp (Ambarino Frost), Tex (New Austin Haze).
- **Growth Stages**: Seedling -> Young -> Mature.
- **Watering System**: Plants require water. Rent a water wagon or use buckets.
- **Visuals**: Props scale with growth and change models.

### 🚜 Water Wagon Rental
- Rent a **Water Wagon** from the Seed Vendor for $50.
- Holds **50 Litres** of water.
- Use it to fill your buckets anywhere on the farm.
- **Refillable**: Drive the wagon into a river/lake and "Refill Tank".
- Cinematic camera sequence upon rental.

### 🏭 Batch Processing
- **Washing**: Wash dirty leaves in the Wash Bucket. **Requires 50x Leaves**. Yields 46-49x Washed.
- **Drying**: Hang washed weed on the Drying Rack. **Requires 50x Washed**. Yields 46-49x Dried.
- **Trimming**: Trim dried buds at the table. **Requires 50x Dried**. Yields 46-49x Trimmed.
- **Loss Mechanic**: You always lose a small percentage during processing to simulate waste.

### 💰 Dynamic Selling
- Sell processed weed (Trimmed or Joints) to dynamic buyers in towns.
- Prices fluctuate based on strain and location.

## Installation

1. **Dependencies**:
   - `rsg-core`
   - `rsg-inventory`
   - `rsg-target`
   - `ox_lib` (for menu, notifications, progress bar)

2. **Items**:
   - Import the items from `items.lua` into your `rsg-core/shared/items.lua` or inventory config.

3. **Database**:
   - Ensure your database has the `rsg_weed_plants` table (created by the script automatically on first run if configured, or check `server/database.lua`).

4. **Config**:
   - Configure strains, growth times, and locations in `config.lua`.

## Usage

1. **Buy Seeds**: Visit the **Gardening Supplies** blip (near Valentine).
2. **Plant**: Use a `seed_[strain]` item on suitable soil.
3. **Water**:
   - Use a `fullbucket` on the plant.
   - Or rent a **Water Wagon** from the vendor ("Need help farming?").
4. **Harvest**: Use a `shovel` when the plant is 100% grown.
5. **Process**:
   - Place a **Wash Bucket** (`wash_barrel`) and **Processing Rack** (`processing_table`).
   - Interact via Third-Eye (Alt).
   - **Note**: You need a batch of **50 items** to start processing.

## Commands
- `/sellweed`: Start the selling mission (if configured).

## Credits
 **Weed Plant Props**: [DerHobbs](https://github.com/DerHobbs/Weed_plant_prop_for_RedM)
