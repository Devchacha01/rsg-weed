local RSGCore = exports['rsg-core']:GetCoreObject()

-- Load plants & Schema Check
CreateThread(function()
    -- Check/Add fertilized column
    local checkFert = MySQL.scalar.await("SELECT count(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'rsg_weed_plants' AND column_name = 'fertilized'")
    if checkFert == 0 then
        MySQL.query('ALTER TABLE rsg_weed_plants ADD COLUMN fertilized INT DEFAULT 0')
        print('^3[RSG-WEED] Added initialized fertilized column to rsg_weed_plants^7')
    end

    -- Check/Add updated_at column (Required for growth/decay)
    local checkUpdated = MySQL.scalar.await("SELECT count(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'rsg_weed_plants' AND column_name = 'updated_at'")
    if checkUpdated == 0 then
        MySQL.query('ALTER TABLE rsg_weed_plants ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP')
        print('^3[RSG-WEED] Added initialized updated_at column to rsg_weed_plants^7')
    end

    local success, result = pcall(MySQL.query.await, 'SELECT * FROM rsg_weed_plants')
    if success and result then
        for _, plant in ipairs(result) do
            plant.coords = json.decode(plant.coords)
            plant.stage = plant.stage or 1
            plant.growth = plant.growth or 0
            plant.water = plant.water or 100
            plant.fertilized = plant.fertilized or 0
            TriggerClientEvent('rsg-weed:client:spawnPlant', -1, plant)
        end
    else
        print('^1[RSG-WEED] Error loading plants or table empty^7')
    end
end)

-- Sync on Player Join
RegisterNetEvent('RSGCore:Server:PlayerLoaded', function(src)
    local src = src
    MySQL.query('SELECT * FROM rsg_weed_plants', {}, function(plants)
        if plants then
            for _, plant in ipairs(plants) do
                plant.coords = json.decode(plant.coords)
                plant.stage = plant.stage or 1
                plant.growth = plant.growth or 0.0
                plant.water = plant.water or 100.0
                
                TriggerClientEvent('rsg-weed:client:spawnPlant', src, plant)
            end
        end
    end)
end)

-- Save new plant
RegisterNetEvent('rsg-weed:server:savePlant', function(coords, strain)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end

    local seedItem = Config.Strains[strain].items.seed

    if player.Functions.RemoveItem(seedItem, 1) then
        -- Sanitize coords to table to ensure JSON compatibility
        local coordsTable = { x = coords.x, y = coords.y, z = coords.z, w = coords.w or 0.0 }

        MySQL.insert('INSERT INTO rsg_weed_plants (coords, strain, water, growth, stage, fertilized, updated_at) VALUES (?, ?, 0, 0, 1, 0, NOW())', { json.encode(coordsTable), strain }, function(id)
            if not id then return print('^1[RSG-WEED] Failed to save plant to DB^7') end
            local plant = {
                id = id,
                strain = strain,
                coords = coordsTable, -- Use the sanitized table, not the raw argument
                stage = 1,
                water = 0.0,
                growth = 0.0,
                fertilized = 0
            }
            TriggerClientEvent('rsg-weed:client:spawnPlant', -1, plant)
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Plant saved with ID: ' .. id })
        end)
    end
end)

-- Growth Loop
CreateThread(function()
    while true do
        Wait(60000)
        MySQL.query('SELECT * FROM rsg_weed_plants', {}, function(plants)
            if plants then
                for _, plant in ipairs(plants) do
                    local newGrowth = plant.growth + (100 / Config.GrowthTime)
                    local newWater = plant.water - Config.WaterRate
                    
                    if newWater < 0 then newWater = 0 end
                    if newGrowth > 100 then newGrowth = 100 end

                    local newStage = 1
                    if newGrowth >= 33.0 then newStage = 2 end
                    if newGrowth >= 66.0 then newStage = 3 end
                    -- 3 Stages: Seedling (Milkweed) -> Small -> Large
                    
                    if newStage ~= plant.stage or math.floor(newGrowth) ~= math.floor(plant.growth) or math.floor(newWater) ~= math.floor(plant.water) then
                         MySQL.update('UPDATE rsg_weed_plants SET growth = ?, water = ?, stage = ?, updated_at = NOW() WHERE id = ?', { newGrowth, newWater, newStage, plant.id })
                         
                         plant.growth = newGrowth
                         plant.water = newWater
                         plant.stage = newStage
                         plant.coords = json.decode(plant.coords) -- CRITICAL: Decode coords string to table before sending to client
                         -- print('^3[RSG-WEED] DEBUG: Plant '..plant.id..' updated. Growth: '..newGrowth..' Stage: '..newStage..'^7')
                         TriggerClientEvent('rsg-weed:client:updatePlant', -1, plant)
                    end
                end
            end
        end)
    end
end)

-- Auto Decay Loop (Check every 5 minutes)
-- Auto Decay Loop (DISABLED for now)
-- CreateThread(function()
--     while true do
--         Wait(5 * 60000) -- 5 minutes
--         -- Delete plants older than 1 hour (3600 seconds)
--         MySQL.update('DELETE FROM rsg_weed_plants WHERE updated_at < (NOW() - INTERVAL 1 HOUR)', {}, function(affected)
--             if affected and affected > 0 then
--                 print('^3[RSG-WEED] Decayed ' .. affected .. ' old plants.^7')
--                 -- Force sync to clients to remove deleted plants
--                 TriggerEvent('rsg-weed:server:syncAll')
--             end
--         end)
--     end
-- end)

RegisterNetEvent('rsg-weed:server:syncAll', function()
    MySQL.query('SELECT * FROM rsg_weed_plants', {}, function(plants)
        if plants then
             -- We can optimize this by sending a "cleanup" event, but for now, let's just re-sync known plants
             -- Actually, client needs to know which ones to REMOVE.
             -- Simplest way: Trigger client to reload all, or send list of IDs to keep.
             local ids = {}
             for _, p in ipairs(plants) do ids[p.id] = true end
             TriggerClientEvent('rsg-weed:client:cleanupPlants', -1, ids)
        end
    end)
end)

-- Harvest / Destroy
RegisterNetEvent('rsg-weed:server:deletePlant', function(plantId, actionType)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end
    
    -- Need to fetch strain first to give correct item (if harvesting)
    MySQL.query('SELECT strain FROM rsg_weed_plants WHERE id = ?', { plantId }, function(result)
        if result and result[1] then
            local strain = result[1].strain
            MySQL.update('DELETE FROM rsg_weed_plants WHERE id = ?', { plantId }, function(affectedRows)
                if affectedRows > 0 then
                     TriggerClientEvent('rsg-weed:client:removePlant', -1, plantId)
                     
                     if actionType == 'harvest' then
                         local amount = math.random(Config.HarvestAmount.min, Config.HarvestAmount.max)
                         
                         -- Fertilizer Bonus
                         if result[1].fertilized and result[1].fertilized == 1 then
                             amount = math.floor(amount * 1.5)
                         end
                         
                         local leafItem = Config.Strains[strain].items.leaf
                         
                         player.Functions.AddItem(leafItem, amount)
                         TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[leafItem], 'add')
                         TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Harvested ' .. amount .. 'x ' .. RSGCore.Shared.Items[leafItem].label })
                     else
                        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Plant destroyed' })
                     end
                end
            end)
        end
    end)
end)

-- Register Usable Seeds
for strain, data in pairs(Config.Strains) do
    RSGCore.Functions.CreateUseableItem(data.items.seed, function(source, item)
        TriggerClientEvent('rsg-weed:client:startPlanting', source, strain)
    end)
end

-- Callbacks for Plant Interaction
RSGCore.Functions.CreateCallback('rsg-weed:server:waterPlant', function(source, cb, plantId)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    
    -- Check if player has item (Reusable)
    local hasItem = player.Functions.GetItemByName(Config.WaterItem)
    if hasItem then
        MySQL.query('SELECT * FROM rsg_weed_plants WHERE id = ?', { plantId }, function(result)
            if result and result[1] then
                -- Multi-use Logic
                local uses = hasItem.info and hasItem.info.uses or Config.BucketUses
                uses = uses - 1
                
                player.Functions.RemoveItem(Config.WaterItem, 1, hasItem.slot)
                
                if uses <= 0 then
                    player.Functions.AddItem(Config.EmptyBucketItem, 1)
                    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.EmptyBucketItem], 'add')
                else
                    local info = hasItem.info or {}
                    info.uses = uses
                    player.Functions.AddItem(Config.WaterItem, 1, nil, info)
                end

                local newWater = math.min(100.0, result[1].water + 50.0)
                MySQL.update('UPDATE rsg_weed_plants SET water = ?, updated_at = NOW() WHERE id = ?', { newWater, plantId })
                
                local plant = result[1]
                plant.water = newWater
                plant.coords = json.decode(plant.coords) -- Decoded for client compatibility if needed
                -- Ensure growth is passed correctly
                plant.growth = plant.growth or 0.0
                -- print('^3[RSG-WEED] DEBUG: Watered Plant '..plantId..'. New Water: '..newWater..' Growth: '..plant.growth..'^7')
                TriggerClientEvent('rsg-weed:client:updatePlant', -1, plant)
                
                cb({ success = true, usesLeft = uses })
            else
                cb({ success = false, msg = 'Plant not found' })
            end
        end)
    else
        cb({ success = false, msg = 'You need water!' })
    end
end)


RSGCore.Functions.CreateCallback('rsg-weed:server:fertilizePlant', function(source, cb, plantId)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    
    if player.Functions.RemoveItem(Config.FertilizerItem, 1) then
         MySQL.query('SELECT * FROM rsg_weed_plants WHERE id = ?', { plantId }, function(result)
            if result and result[1] then
                if result[1].fertilized == 1 then
                    cb({ success = false, msg = 'Already fertilized!' })
                    return
                end
                
                if result[1].growth >= 99 then
                    player.Functions.AddItem(Config.FertilizerItem, 1)
                    cb({ success = false, msg = 'Plant is fully grown!' })
                    return
                end

                local newGrowth = math.min(100.0, result[1].growth + 10.0)
                -- Mark as fertilized
                MySQL.update('UPDATE rsg_weed_plants SET growth = ?, fertilized = 1, updated_at = NOW() WHERE id = ?', { newGrowth, plantId })
                
                local plant = result[1]
                plant.growth = newGrowth
                plant.fertilized = 1
                plant.coords = json.decode(plant.coords)
                TriggerClientEvent('rsg-weed:client:updatePlant', -1, plant)
                
                cb({ success = true })
            else
                cb({ success = false, msg = 'Plant not found' })
            end
        end)
    else
        cb({ success = false, msg = 'You need fertilizer!' })
    end
end)
