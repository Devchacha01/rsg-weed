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
        player.Functions.AddItem(item, amount)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bought ' .. amount .. 'x ' .. item })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough money' })
    end
end)

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

-- Fill Bucket
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
