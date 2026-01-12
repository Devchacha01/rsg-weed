local RSGCore = exports['rsg-core']:GetCoreObject()
local isSelling = false
local soldNPCs = {}
local PendingDeal = nil
local lastAlertTime = 0

local function Notify(msg, type)
    lib.notify({ title = 'Weed Selling', description = msg, type = type })
end

local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    
    RequestAnimDict(dict)
    
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if not HasAnimDictLoaded(dict) then
        return false
    end
    
    return true
end

local function nativeGetTownName(coords)
    local zoneId = Citizen.InvokeNative(0x43AD8FC02B429D33, coords.x, coords.y, coords.z, 1) -- GetNameOfZone
    if zoneId then
        local name = Citizen.InvokeNative(0xD0EF8A959B8A4CB9, zoneId) -- GetStringFromHashKey
        return name
    end
    return nil
end

local function PlayPassingAnimation(targetPed)
    local ped = PlayerPedId()
    
    -- Create Package Prop: s_drugpackage_02x
    local modelHash = 1180245127
    RequestModel(modelHash)
    
    local propTimeout = 0
    while not HasModelLoaded(modelHash) and propTimeout < 100 do 
        Wait(10) 
        propTimeout = propTimeout + 1
    end
    
    local prop = nil
    if HasModelLoaded(modelHash) then
        local x, y, z = table.unpack(GetEntityCoords(ped))
        prop = CreateObject(modelHash, x, y, z + 0.2, true, true, false)
        
        -- Disable collision so it doesn't fall out of hand
        SetEntityCollision(prop, false, true)
        
        -- Attach to right hand (SKEL_R_Hand is better for packages)
        local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Hand")
        AttachEntityToEntity(prop, ped, righthand, 0.12, 0.0, -0.05, 90.0, 0.0, 0.0, true, true, false, true, 1, true)
    end
    
    -- Play user requested animation: amb_misc@world_human_give_item@male_a@idle_a
    -- Play verified working animation (Shared with Joint Rolling)
    local animDict = "mech_inventory@crafting@fallbacks"
    local animName = "full_craft_and_stow"
    
    RequestAnimDict(animDict)
    local animTimeout = 0
    while not HasAnimDictLoaded(animDict) and animTimeout < 50 do
        Wait(10)
        animTimeout = animTimeout + 1
    end
    
    if HasAnimDictLoaded(animDict) then
        -- Duration 3000ms, Flag 31 (Matches Joint Rolling - Standing) 
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, 3000, 31, 0, false, false, false)
    end
    
    -- Show progress bar (sale happens during this)
    if lib.progressBar({
        duration = 3000,
        label = 'Handing over package...',
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, car = true, combat = true },
        anim = false
    }) then
        if prop then DeleteEntity(prop) end
        return true
    end
    
    if prop then DeleteEntity(prop) end
    return false
end

-- NPC Smoke after sale - Manual Animation + Prop (Most reliable)
-- NPC Walk Away with Package (Replaces Smoking)
local function PlayNPCWalkAway(npc)
    SetEntityAsMissionEntity(npc, true, true)
    ClearPedTasks(npc)
    ClearPedSecondaryTask(npc)
    Wait(500)
    
    -- 1. Create Package Prop
    local modelHash = GetHashKey(Config.Selling.model or 's_drugpackage_02x')
    RequestModel(modelHash)
    local unusedTimeout = 0
    while not HasModelLoaded(modelHash) and unusedTimeout < 50 do
        Wait(10)
        unusedTimeout = unusedTimeout + 1
    end
    
    local x, y, z = table.unpack(GetEntityCoords(npc))
    local package = CreateObject(modelHash, x, y, z + 0.2, true, true, true)
    
    -- Attach to Hand (Right Hand)
    -- Adjust offsets for s_drugpackage_02x if needed. 
    -- Typical hand hold: 0.12, 0.0, -0.05, 90.0, 0.0, 0.0 (from PlayPassingAnimation)
    local righthand = GetEntityBoneIndexByName(npc, "SKEL_R_Hand")
    AttachEntityToEntity(package, npc, righthand, 0.12, 0.0, -0.05, 90.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- 2. Make them wander (carrying the item)
    TaskWanderStandard(npc, 10.0, 10)
        
    -- Cleanup after 1 minute
    SetTimeout(60000, function()
        if DoesEntityExist(package) then DeleteEntity(package) end
        if DoesEntityExist(npc) then
            ClearPedTasks(npc)
            
            -- Release NPC back to the world
            TaskWanderStandard(npc, 10.0, 10)
            SetEntityAsMissionEntity(npc, false, true)
            SetPedAsNoLongerNeeded(npc)
        end
    end)
end

local function TryToSellToNpc(entity)
    if IsPedDeadOrDying(entity, true) or IsPedAPlayer(entity) then return end
    
    -- Town Restriction
    local inCity = false
    for _, city in ipairs(Config.Selling.allowedCities) do
        if #(GetEntityCoords(PlayerPedId()) - city.coords) < city.radius then inCity = true break end
    end
    
    if not inCity then 
        Notify('You must be in a city (Valentine, Rhodes, Saint Denis, Blackwater) to sell.', 'error') 
        return 
    end

    -- Stop NPC and Face Player
    ClearPedTasks(entity)
    TaskTurnPedToFaceEntity(entity, PlayerPedId(), 2000)
    Wait(500)
    TaskStandStill(entity, -1) -- Force them to stand still

    -- Check Inventory for Weed
    local hasWeed = false
    local availableItems = {}
    
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.items then return end

    for _, strain in pairs(Config.Strains) do
        -- Check both Trimmed and Joints
        local checkItems = { 
            { name = strain.items.trimmed, type = 'trimmed', label = strain.label .. ' Bud' },
            { name = strain.items.joint, type = 'joint', label = strain.label .. ' Joint' }
        }
        
        for _, check in ipairs(checkItems) do
            local item = RSGCore.Functions.HasItem(check.name)
            if item then
                -- Get exact amount from player data to be safe
                for _, invItem in pairs(PlayerData.items) do
                    if invItem.name == check.name then
                        -- Check if item type is sellable (in config)
                        if Config.Selling.buyerPrices[check.type] then
                            table.insert(availableItems, {
                                name = check.name,
                                label = check.label,
                                type = check.type,
                                amount = invItem.amount
                            })
                        end
                    end
                end
            end
        end
    end
    
    if #availableItems == 0 then
        Notify('You have no weed to sell!', 'error')
        -- Resume wandering if no weed
        ClearPedTasks(entity)
        TaskWanderStandard(entity, 10.0, 10)
        return
    end
    
    -- Notify Negotiating
    Notify('Negotiating with buyer...', 'inform')
    
    -- Pick Random Item to "Demand"
    local selectedItem = availableItems[math.random(#availableItems)]
    -- Limit demand to max 10 or whatever player has
    local maxDemand = math.min(selectedItem.amount, 10)
    local demandAmount = math.random(1, maxDemand)
    
    -- Calculate Offer (Dynamic Pricing)
    local priceRange = Config.Selling.buyerPrices[selectedItem.type]
    local basePrice = math.random(priceRange.min, priceRange.max)
    local pricePerUnit = basePrice
    
    -- Dynamic Logic: 40% Lowball, 10% Highball, 50% Normal
    local moodRng = math.random(1, 100)
    
    if moodRng <= 40 then
        -- Lowball: ~70% Less (30% of value)
        pricePerUnit = math.floor(basePrice * 0.30)
        if pricePerUnit < 1 then pricePerUnit = 1 end
    elseif moodRng >= 91 then
        -- Highball: Bonus (e.g. 50% more)
        pricePerUnit = math.floor(basePrice * 1.50)
    end
    
    local totalPrice = pricePerUnit * demandAmount
    
    -- Store Pending Deal
    PendingDeal = {
        entity = entity,
        item = selectedItem,
        amount = demandAmount,
        price = totalPrice,
        time = GetGameTimer()
    }
    
    -- Open Custom UI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openSelling',
        label = selectedItem.label,
        amount = demandAmount,
        price = totalPrice
    })
    
    -- Timeout Thread (10 Seconds)
    CreateThread(function()
        local dealTime = PendingDeal.time
        Wait(10000)
        
        -- Check if the deal is still pending and matches the original deal time
        if PendingDeal and PendingDeal.time == dealTime then
            -- Auto-Decline
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'close' })
            
            local npc = PendingDeal.entity
            if DoesEntityExist(npc) then
                ClearPedTasks(npc)
                TaskWanderStandard(npc, 10.0, 10)
            end
            
            PendingDeal = nil
            Notify('Buyer lost patience and walked away.', 'error')
        end
    end)
end

-- NUI Callbacks
RegisterNUICallback('sell_accept', function(data, cb)
    SetNuiFocus(false, false)
    
    local deal = PendingDeal
    if deal and deal.entity then
        Notify('Offer accepted. Handing over goods...', 'success')
        
        -- Animation & Logic
        if PlayPassingAnimation(deal.entity) then
            soldNPCs[deal.entity] = true
            TriggerServerEvent('rsg-weed:server:sellDynamicItem', deal.item.name, deal.amount, deal.price)
            PlayNPCWalkAway(deal.entity)
            
            -- Police Alert Logic
            if Config.PoliceAlerts and Config.PoliceAlerts.enabled then
                local currentTime = GetGameTimer()
                if (currentTime - lastAlertTime) > (Config.PoliceAlerts.cooldown or 600000) then
                    local chance = math.random(1, 100)
                    if chance <= Config.PoliceAlerts.chance then
                        local ped = PlayerPedId()
                        local coords = GetEntityCoords(ped)
                        local area = nativeGetTownName(coords) or "Unknown Location"
                        
                        TriggerServerEvent('rsg-weed:server:alertLaw', coords, area)
                        Notify('A witness reported you to the law!', 'error')
                        
                        lastAlertTime = currentTime
                    end
                end
            end
        else
            -- Check for animation failure -> UNFREEZE NPC
            Notify('Transaction cancelled or failed.', 'error')
            ClearPedTasks(deal.entity)
            TaskWanderStandard(deal.entity, 10.0, 10)
        end
    end
    
    PendingDeal = nil
    cb('ok')
end)

RegisterNUICallback('sell_decline', function(data, cb)
    SetNuiFocus(false, false)
    
    local deal = PendingDeal
    if deal and deal.entity then
        soldNPCs[deal.entity] = true
        Notify('You declined the offer.', 'inform')
        -- Resume wandering
        ClearPedTasks(deal.entity)
        TaskWanderStandard(deal.entity, 10.0, 10)
    end
    
    PendingDeal = nil
    cb('ok')
end)

local function IsValidBuyer(entity)
    if not DoesEntityExist(entity) then return false end
    if IsPedDeadOrDying(entity, true) then return false end
    if IsPedAPlayer(entity) then return false end
    if not IsPedHuman(entity) then return false end
    if soldNPCs[entity] then return false end
    
    -- Strict Ped Type Check (Civilians only: 4=Male, 5=Female)
    -- This filters out Cops, Gangs, and Animals
    local pedType = GetPedType(entity)
    -- Relaxed check: Allow more types but exclude animals/horses (usually 28+)
    -- if pedType ~= 4 and pedType ~= 5 then return false end -- Too strict
    
    -- Ensure it's not a player (already checked) and IS human (already checked)
    -- Just return true if Human check passed.
    -- if not IsPedHuman(entity) then return false end -- Already checked above
    
    -- Extra safety against animals
    local model = GetEntityModel(entity)
    if IsModelAPed(model) and not IsPedHuman(entity) then return false end
    
    return true
end

local function HasWeed()
    for _, strain in pairs(Config.Strains) do
        if RSGCore.Functions.HasItem(strain.items.trimmed) or RSGCore.Functions.HasItem(strain.items.joint) then
            return true
        end
    end
    return false
end

-- Third Eye Target
-- Third Eye Target
CreateThread(function()
    exports['rsg-target']:AddGlobalPed({
        options = {
            {
                type = "client",
                action = function(entity)
                    TryToSellToNpc(entity)
                end,
                icon = "fas fa-cannabis",
                label = "Sell Weed",
                canInteract = function(entity)
                    return IsValidBuyer(entity) and HasWeed()
                end,
            }
        },
        distance = 3.0, -- Increased from 2.0 to ensure ease of use
    })
end)


RegisterNetEvent('rsg-weed:client:policeBlip', function(coords)
    local blip = BlipAddForCoords(1664425300, coords)
    SetBlipSprite(blip, joaat(Config.PoliceAlerts.blip.sprite))
    SetBlipScale(blip, 1.0)
    SetBlipName(blip, "Drug Sale Reported")
    local blipColor = Config.PoliceAlerts.blip.color or 'BLIP_MODIFIER_MP_COLOR_8'
    Citizen.InvokeNative(0x662D364AB21693F3, blip, joaat(blipColor), 1) -- SetBlipModifier
    
    SetTimeout(Config.PoliceAlerts.blip.time, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)
