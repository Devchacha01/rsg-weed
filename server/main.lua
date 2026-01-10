local RSGCore = exports['rsg-core']:GetCoreObject()

-- Callback: Check if player has a shovel
RSGCore.Functions.CreateCallback('rsg-weed:server:hasShovel', function(source, cb)
    local player = RSGCore.Functions.GetPlayer(source)
    if player then
        local hasShovel = player.Functions.GetItemByName(Config.ShovelItem) ~= nil
        cb(hasShovel)
    else
        cb(false)
    end
end)

RSGCore.Functions.CreateCallback('rsg-weed:server:canProcess', function(source, cb, data)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    local type = data.type
    
    -- Roll Joint: 1x trimmed + 1x rolling_paper -> 1x joint
    if type == 'roll' then
        local hasRollingPaper = player.Functions.GetItemByName('rolling_paper')
        if not hasRollingPaper then
            cb(false, "You need Rolling Paper!")
            return
        end
        
        for _, strain in pairs(Config.Strains) do
            local item = player.Functions.GetItemByName(strain.items.trimmed)
            if item and item.amount >= 1 then
                cb(true)
                return
            end
        end
        cb(false, "You need trimmed buds to roll!")
        return
    end
    
    for _, strain in pairs(Config.Strains) do
        local requiredItem = nil
        if type == 'wash' then requiredItem = strain.items.leaf
        elseif type == 'dry' then requiredItem = strain.items.washed
        elseif type == 'trim' then requiredItem = strain.items.dried
        end
        
        if requiredItem then
            local item = player.Functions.GetItemByName(requiredItem)
            if item then
                if item.amount >= 50 then
                    cb(true)
                    return
                else
                    cb(false, "You need 50x " .. (RSGCore.Shared.Items[requiredItem].label or requiredItem))
                    return
                end
            end
        end
    end
    cb(false, "You don't have any materials to process (Need 50x)")
end)

RegisterNetEvent('rsg-weed:server:finishProcess', function(type)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    
    -- Roll Joint: 1x trimmed + 1x rolling_paper -> 1x joint
    if type == 'roll' then
        for _, strain in pairs(Config.Strains) do
            local item = player.Functions.GetItemByName(strain.items.trimmed)
            if item and item.amount >= 1 then
                if player.Functions.RemoveItem(strain.items.trimmed, 1) and player.Functions.RemoveItem('rolling_paper', 1) then
                    player.Functions.AddItem(strain.items.joint, 1)
                    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Rolled 1x ' .. (RSGCore.Shared.Items[strain.items.joint].label or 'Joint') })
                    return
                end
            end
        end
        return
    end
    
    for _, strain in pairs(Config.Strains) do
        local inputItem = nil
        local outputItem = nil
        
        if type == 'wash' then 
            inputItem = strain.items.leaf
            outputItem = strain.items.washed
        elseif type == 'dry' then 
            inputItem = strain.items.washed
            outputItem = strain.items.dried
        elseif type == 'trim' then 
            inputItem = strain.items.dried
            outputItem = strain.items.trimmed
        end
        
        if inputItem and outputItem then
            local item = player.Functions.GetItemByName(inputItem)
            if item and item.amount >= 50 then
                if player.Functions.RemoveItem(inputItem, 50) then
                    local amount = math.random(46, 49)
                    player.Functions.AddItem(outputItem, amount)
                    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Processed 50x -> ' .. amount .. 'x Result' })
                    
                    -- Return wash bucket if washing (Wait, logic says inherent water source now, so no bucket return needed unless used?)
                    -- Previous logic returned EMPTY bucket. But we removed water usage. 
                    -- If user wants Empty Bucket back because they filled it?
                    -- Actually we only removed 'fullbucket' CONSUMPTION.
                    -- If the player used a valid input, we just proceeded.
                    -- The previous code lines 44-48:
                    -- if player.Functions.RemoveItem(strain.items.leaf, 1) then ... end
                    -- So we just proceed.
                    return
                end
            end
        end
    end
end)

-- Buying Logic (with Quantity support)
RegisterNetEvent('rsg-weed:server:buyItem', function(item, price, quantity)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    local amount = quantity or 1
    local totalCost = price * amount -- price parameter is usually unit price, but let's be safe.
    -- Wait, looking at client code: price = selectedPrice * qty. So 'price' IS total cost.
    -- Let's re-verify client logic.
    -- Client: price: selectedPrice * qty. Correct.
    
    if item == 'wagon_rent' then
        local price = 50 * amount
        if player.Functions.RemoveMoney('cash', price) then
            TriggerClientEvent('rsg-weed:client:spawnWagon', src)
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Wagon rented! Check behind you.' })
        else
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough money' })
        end
        return
    end

    if player.Functions.RemoveMoney('cash', price) then
        -- Special handling for matches - add with 20 uses
        if item == 'matches' then
            for i = 1, amount do
                local matchInfo = { uses = 20 }
                player.Functions.AddItem('matches', 1, nil, matchInfo)
            end
        else
            player.Functions.AddItem(item, amount)
        end
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bought ' .. amount .. 'x ' .. item })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough money' })
    end
end)

-- Helper: Consume 1 match use
local function ConsumeMatch(player, src)
    if not Config.Smoking.requireMatches then return true end
    
    local matchItem = player.Functions.GetItemByName('matches')
    if not matchItem then return false end
    
    local uses = matchItem.info and matchItem.info.uses or 20
    uses = uses - 1
    
    -- Remove old match box
    player.Functions.RemoveItem('matches', 1, matchItem.slot)
    
    if uses > 0 then
        -- Add back with updated uses
        local matchInfo = { uses = uses }
        player.Functions.AddItem('matches', 1, nil, matchInfo)
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = uses .. ' matches remaining' })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Match box is empty' })
    end
    
    return true
end

-- Dynamic Selling Logic
RegisterNetEvent('rsg-weed:server:sellDynamic', function(typeString)
    -- typeString = 'trimmed' or 'joint'
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    
    local sold = false
    local total = 0
    
    -- Check all strains for this type
    for _, strain in pairs(Config.Strains) do
        local itemName = strain.items[typeString] -- e.g. trimmed_kalka
        if itemName then
            local invItem = player.Functions.GetItemByName(itemName)
            if invItem and invItem.amount > 0 then
                -- Sell ALL of this type
                local count = invItem.amount
                local price = math.random(Config.Selling.buyerPrices[typeString].min, Config.Selling.buyerPrices[typeString].max) * count
                
                if player.Functions.RemoveItem(itemName, count) then
                    player.Functions.AddMoney('cash', price)
                    total = total + price
                    sold = true
                end
            end
        end
    end
    
    if sold then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Sold weed for $' .. total })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You have nothing to sell!' })
    end
end)


-- Usable Placeables
RSGCore.Functions.CreateUseableItem('wash_barrel', function(source)
    TriggerClientEvent('rsg-weed:client:startPlacing', source, 'wash_barrel')
end)
RSGCore.Functions.CreateUseableItem('processing_table', function(source)
    TriggerClientEvent('rsg-weed:client:startPlacing', source, 'processing_table')
end)

-- Usable water bucket - triggers watering on client
RSGCore.Functions.CreateUseableItem(Config.WaterItem, function(source)
    TriggerClientEvent('rsg-weed:client:useWaterBucket', source)
end)

-- Note: Seed usable items are registered in database.lua (lines 95-99)

RegisterNetEvent('rsg-weed:server:removeItem', function(item, count)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    player.Functions.RemoveItem(item, count)
end)

-- Give placeable back when picked up
RegisterNetEvent('rsg-weed:server:givePlaceable', function(type)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if player then
        player.Functions.AddItem(type, 1)
    end
end)

RegisterNetEvent('rsg-weed:server:fillBucket', function()
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end

    if player.Functions.RemoveItem(Config.EmptyBucketItem, 1) then
        local info = { uses = Config.BucketUses }
        player.Functions.AddItem(Config.WaterItem, 1, nil, info)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.WaterItem], 'add')
    end
end)

-- Useable: Trimmed Buds -> Roll Joint (from inventory)
for strainKey, strain in pairs(Config.Strains) do
    RSGCore.Functions.CreateUseableItem(strain.items.trimmed, function(source, item)
        local src = source
        local player = RSGCore.Functions.GetPlayer(src)
        if not player then return end
        
        local hasRollingPaper = player.Functions.GetItemByName('rolling_paper')
        if not hasRollingPaper then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need Rolling Paper!' })
            return
        end
        
        -- Trigger client animation, then finish roll
        TriggerClientEvent('rsg-weed:client:rollJoint', src, strainKey)
    end)
end

-- Finish Roll Joint (called from client after animation)
RegisterNetEvent('rsg-weed:server:finishRollJoint', function(strainKey)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end
    
    local strain = Config.Strains[strainKey]
    if not strain then return end
    
    local hasTrimmed = player.Functions.GetItemByName(strain.items.trimmed)
    local hasRolling = player.Functions.GetItemByName('rolling_paper')
    
    if hasTrimmed and hasRolling then
        if player.Functions.RemoveItem(strain.items.trimmed, 1) and player.Functions.RemoveItem('rolling_paper', 1) then
            player.Functions.AddItem(strain.items.joint, 1)
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Rolled 1x ' .. (RSGCore.Shared.Items[strain.items.joint].label or 'Joint') })
        end
    end
end)

-- ============================================================================
-- SMOKING SYSTEM
-- ============================================================================

-- Useable: Joints -> Smoke
for strainKey, strain in pairs(Config.Strains) do
    RSGCore.Functions.CreateUseableItem(strain.items.joint, function(source, item)
        local src = source
        local player = RSGCore.Functions.GetPlayer(src)
        if not player then return end
        
        -- Check for matches if required
        if Config.Smoking.requireMatches then
            local hasMatches = RSGCore.Functions.HasItem(src, 'matches', 1)
            if not hasMatches then
                TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need Matches to light!' })
                return
            end
        end
        
        -- Trigger client smoking animation
        TriggerClientEvent('rsg-weed:client:smokeJoint', src, strainKey)
    end)
end

-- Finish Smoke Joint (called from client after animation)
RegisterNetEvent('rsg-weed:server:finishSmokeJoint', function(strainKey)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end
    
    local strain = Config.Strains[strainKey]
    if not strain then return end
    
    local hasJoint = player.Functions.GetItemByName(strain.items.joint)
    if hasJoint then
        -- Consume 1 match
        ConsumeMatch(player, src)
        
        player.Functions.RemoveItem(strain.items.joint, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[strain.items.joint], 'remove')
        
        -- Apply health/stamina boost via client
        TriggerClientEvent('rsg-weed:client:applySmokingBoost', src, 'joint')
        
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'You smoked a ' .. strain.label .. ' Joint' })
    end
end)

-- Useable: Smoking Pipe -> Open Load Menu
RSGCore.Functions.CreateUseableItem('smoking_pipe', function(source, item)
    local src = source
    TriggerClientEvent('rsg-weed:client:openLoadPipeMenu', src)
end)

-- Check if player can load pipe (has trimmed bud)
RegisterNetEvent('rsg-weed:server:checkLoadPipe', function(strainKey)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end
    
    local strain = Config.Strains[strainKey]
    if not strain then return end
    
    local hasPipe = player.Functions.GetItemByName('smoking_pipe')
    local hasTrimmed = player.Functions.GetItemByName(strain.items.trimmed)
    
    if not hasPipe then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need a Smoking Pipe!' })
        return
    end
    
    if not hasTrimmed then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need ' .. strain.label .. ' Bud!' })
        return
    end
    
    -- Start loading animation
    TriggerClientEvent('rsg-weed:client:loadPipe', src, strainKey)
end)

-- Finish loading pipe
RegisterNetEvent('rsg-weed:server:finishLoadPipe', function(strainKey)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end
    
    local strain = Config.Strains[strainKey]
    if not strain then return end
    
    local hasPipe = player.Functions.GetItemByName('smoking_pipe')
    local hasTrimmed = player.Functions.GetItemByName(strain.items.trimmed)
    
    if hasPipe and hasTrimmed then
        -- Remove empty pipe and trimmed bud
        player.Functions.RemoveItem('smoking_pipe', 1)
        player.Functions.RemoveItem(strain.items.trimmed, 1)
        
        -- Add loaded pipe with metadata
        local loadedPipeName = 'loaded_pipe_' .. strainKey
        local pipeInfo = {
            puffs = Config.Smoking.pipePuffs,
            strain = strainKey
        }
        player.Functions.AddItem(loadedPipeName, 1, nil, pipeInfo)
        
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Loaded pipe with ' .. strain.label .. ' (' .. Config.Smoking.pipePuffs .. ' puffs)' })
    end
end)

-- Useable: Loaded Pipes -> Smoke
for strainKey, strain in pairs(Config.Strains) do
    local loadedPipeName = 'loaded_pipe_' .. strainKey
    RSGCore.Functions.CreateUseableItem(loadedPipeName, function(source, item)
        local src = source
        local player = RSGCore.Functions.GetPlayer(src)
        if not player then return end
        
        -- Check for matches if required
        if Config.Smoking.requireMatches then
            local hasMatches = RSGCore.Functions.HasItem(src, 'matches', 1)
            if not hasMatches then
                TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You need Matches to light!' })
                return
            end
        end
        
        local puffs = item.info and item.info.puffs or Config.Smoking.pipePuffs
        
        -- Trigger client smoking animation
        TriggerClientEvent('rsg-weed:client:smokePipe', src, strainKey, puffs)
    end)
end

-- Finish Smoke Pipe (called from client after animation)
RegisterNetEvent('rsg-weed:server:finishSmokePipe', function(strainKey)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if not player then return end
    
    local strain = Config.Strains[strainKey]
    if not strain then return end
    
    local loadedPipeName = 'loaded_pipe_' .. strainKey
    local pipeItem = player.Functions.GetItemByName(loadedPipeName)
    
    if pipeItem then
        local puffs = pipeItem.info and pipeItem.info.puffs or Config.Smoking.pipePuffs
        puffs = puffs - 1
        
        -- Remove old pipe
        player.Functions.RemoveItem(loadedPipeName, 1, pipeItem.slot)
        
        if puffs > 0 then
            -- Add back with updated puffs
            local pipeInfo = {
                puffs = puffs,
                strain = strainKey
            }
            player.Functions.AddItem(loadedPipeName, 1, nil, pipeInfo)
            TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = puffs .. ' puffs remaining' })
        else
            -- Pipe is empty, return empty pipe
            player.Functions.AddItem('smoking_pipe', 1)
            TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Pipe is empty' })
        end
        
        -- Apply health/stamina boost
        TriggerClientEvent('rsg-weed:client:applySmokingBoost', src, 'pipe')
    end
end)

