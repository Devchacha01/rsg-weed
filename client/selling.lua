local RSGCore = exports['rsg-core']:GetCoreObject()
local isSelling = false
local currentBuyer = nil
local sellingCooldown = false

local function Notify(msg, type)
    RSGCore.Functions.Notify(msg, type)
end

local function EndSelling()
    isSelling = false
    if currentBuyer then 
        SetEntityAsMissionEntity(currentBuyer, false, true)
        SetPedAsNoLongerNeeded(currentBuyer)
        currentBuyer = nil 
    end
    sellingCooldown = true
    SetTimeout(Config.Selling.cooldownTime, function() sellingCooldown = false end)
    Notify('Thinking of finding more buyers later...', 'primary')
end

local function HandleBuyerInteraction()
    if not isSelling or not currentBuyer then return end
    
    local options = {}
    
    -- Check items
    -- We'll assume player has something if they started
    -- Add generic "Sell Trimmed" and "Sell Joint"
    for _, type in ipairs({'trimmed', 'joint'}) do
        table.insert(options, {
            title = 'Sell ' .. type,
            icon = 'dollar-sign',
            onSelect = function()
                TriggerServerEvent('rsg-weed:server:sellDynamic', type)
                
                -- Buyer leaves
                ClearPedTasks(currentBuyer)
                TaskWanderStandard(currentBuyer, 10.0, 10)
                SetTimeout(10000, function() 
                   if currentBuyer then SetEntityAlpha(currentBuyer, 0, false); DeleteEntity(currentBuyer); currentBuyer = nil end
                   -- Next buyer
                   if isSelling then TriggerEvent('rsg-weed:client:nextBuyer') end
                end)
            end
        })
    end
    
     table.insert(options, {
        title = 'Shoo away',
        icon = 'hand',
        onSelect = function()
             ClearPedTasks(currentBuyer)
             TaskWanderStandard(currentBuyer, 10.0, 10)
             if isSelling then TriggerEvent('rsg-weed:client:nextBuyer') end
        end
    })
    
    lib.registerContext({
        id = 'weed_buyer_menu',
        title = 'Shady Buyer',
        options = options
    })
    lib.showContext('weed_buyer_menu')
end

RegisterNetEvent('rsg-weed:client:nextBuyer', function()
    if not isSelling then return end
    Wait(math.random(Config.Selling.timeBetweenBuyers.min, Config.Selling.timeBetweenBuyers.max))
    if not isSelling then return end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Spawn logic (simplified)
    local model = GetHashKey('a_m_m_valcity_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    
    local spawnPos = coords + vector3(math.random(-20,20), math.random(-20,20), 0)
    -- Find safe z? Just simplified for now
    
    local npc = CreatePed(model, spawnPos.x, spawnPos.y, coords.z, 0, true, true)
    currentBuyer = npc
    
    TaskGoToEntity(npc, ped, -1, 2.0, 1.0, 0, 0)
    Notify('A buyer is approaching...', 'primary')
    
    -- Check arrival
    CreateThread(function()
        while isSelling and currentBuyer == npc do
            Wait(1000)
            if #(GetEntityCoords(npc) - GetEntityCoords(ped)) < 3.0 then
                HandleBuyerInteraction()
                break
            end
        end
    end)
end)

RegisterCommand(Config.Selling.command, function()
    if sellingCooldown then Notify('Chill for a bit.', 'error') return end
    if isSelling then EndSelling() return end
    
    -- City Check (Simplified)
    -- local inCity = false
    -- for _, city in ipairs(Config.Selling.allowedCities) do
    --     if #(GetEntityCoords(PlayerPedId()) - city.coords) < city.radius then inCity = true break end
    -- end
    -- if not inCity then Notify('Go to a city.', 'error') return end
    
    isSelling = true
    Notify('You are now looking for buyers...', 'success')
    TriggerEvent('rsg-weed:client:nextBuyer')
end)
