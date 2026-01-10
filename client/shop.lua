--[[
    RSG-Weed Shop System
    Grid Layout (Moonshiner Style)
]]

local RSGCore = exports['rsg-core']:GetCoreObject()
local npcPed = nil
local npcBlip = nil
local npcSpawned = false

-- NUI State
local activeMenuOptions = {}

-- Helper to show NUI menu (same as rsg-moonshiner)
function ShowCustomMenu(title, options, description)
    activeMenuOptions = options
    local optionsForNui = {}
    for i, opt in ipairs(options) do
        table.insert(optionsForNui, {
            title = opt.title or opt.header,
            description = opt.description or opt.txt,
            image = opt.image,
            price = opt.price,
            btnLabel = opt.btnLabel,
        })
    end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openMenu",
        title = title,
        description = description,
        options = optionsForNui
    })
end



function OpenWagonDialog()
    local shopMenu = {}
    
    table.insert(shopMenu, {
        title = 'Rent Water Wagon',
        description = 'Rent a wagon with a 500L water tank. Refillable in rivers.',
        price = 50,
        image = "img/wagon.png",
        btnLabel = "RENT",
        onSelect = function()
            -- Direct purchase, no quantity modal
            TriggerServerEvent('rsg-weed:server:buyItem', 'wagon_rent', 50, 1)
            CloseCustomMenu()
        end
    })

    ShowCustomMenu("Need help farming?", shopMenu, "I can rent you one of my wagons. It has a water tank with enough water for all your plants. Interested?")
end

function CloseCustomMenu()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeMenu" })
end

-- NUI Callbacks
RegisterNUICallback('selectOption', function(data, cb)
    local index = data.index
    if activeMenuOptions[index] and activeMenuOptions[index].onSelect then
        activeMenuOptions[index].onSelect()
    end
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    if data.item and data.quantity and data.price then
        TriggerServerEvent('rsg-weed:server:buyItem', data.item, data.price, data.quantity)
    end
    cb('ok')
end)

-- Setup Blip
local function SetupBlip()
    local cfg = Config.SeedVendor
    local blipCoords = cfg.coords
    
    npcBlip = BlipAddForCoords(1664425300, blipCoords.x, blipCoords.y, blipCoords.z)
    SetBlipSprite(npcBlip, joaat(cfg.blip.sprite), true)
    SetBlipScale(npcBlip, cfg.blip.scale or 0.8)
    SetBlipName(npcBlip, cfg.blip.label)
end

-- Spawn NPC
local function SpawnNPC()
    if npcSpawned then return end
    
    local model = Config.SeedVendor.model
    local coords = Config.SeedVendor.coords
    
    lib.requestModel(model, 5000)
    
    local groundZ = coords.z
    local foundGround, groundHeight = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 100.0, false)
    if foundGround then groundZ = groundHeight end
    
    npcPed = CreatePed(joaat(model), coords.x, coords.y, groundZ, coords.w, false, false, false, false)
    
    local timeout = 0
    while not DoesEntityExist(npcPed) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not DoesEntityExist(npcPed) then return end
    
    Citizen.InvokeNative(0x283978A15512B2FE, npcPed, true) 
    SetEntityNoCollisionEntity(npcPed, PlayerPedId(), false)
    SetEntityCanBeDamaged(npcPed, false)
    SetEntityInvincible(npcPed, true)
    FreezeEntityPosition(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    PlaceEntityOnGroundProperly(npcPed, true)
    
    exports.ox_target:addLocalEntity(npcPed, {
        {
            name = 'weed_shop',
            label = 'Browse Exotic Herbs',
            icon = 'fa-solid fa-basket-shopping',
            distance = 3.0,
            onSelect = function()
                OpenWeedShop()
            end
        },
        {
            name = 'weed_wagon',
            label = 'Need help farming?',
            icon = 'fa-solid fa-wheat-awn',
            distance = 3.0,
            onSelect = function()
                OpenWagonDialog()
            end
        }
    })
    
    npcSpawned = true
end

-- Open Shop Menu
function OpenWeedShop()
    local shopMenu = {}
    
    -- Seeds
    for k, v in pairs(Config.Strains) do
        table.insert(shopMenu, {
            title = v.label .. ' Seed',
            description = "Plant to grow " .. v.label,
            price = 5,
            image = "img/" .. v.items.seed .. ".png",
            onSelect = function()
                SendNUIMessage({
                    action = "openQuantityModal",
                    item = v.items.seed,
                    label = v.label .. ' Seed',
                    price = 5
                })
            end
        })
    end
    
    -- Tools
    table.insert(shopMenu, {
        title = 'Shovel',
        description = 'For planting',
        price = 10,
        image = "img/" .. Config.ShovelItem .. ".png",
        onSelect = function()
            SendNUIMessage({
                action = "openQuantityModal",
                item = Config.ShovelItem,
                label = 'Shovel',
                price = 10
            })
        end
    })

    table.insert(shopMenu, {
        title = 'Empty Bucket',
        description = 'For collecting water',
        price = 2,
        image = "img/bucket.png",
        onSelect = function()
            SendNUIMessage({
                action = "openQuantityModal",
                item = Config.EmptyBucketItem,
                label = 'Empty Bucket',
                price = 2
            })
        end
    })


    
    table.insert(shopMenu, {
        title = 'Fertilizer',
        description = 'Speed growth',
        price = 15,
        image = "img/" .. Config.FertilizerItem .. ".png",
        onSelect = function()
            SendNUIMessage({
                action = "openQuantityModal",
                item = Config.FertilizerItem,
                label = 'Fertilizer',
                price = 15
            })
        end
    })
    
    -- Props
    table.insert(shopMenu, {
        title = 'Wash Barrel',
        description = 'Cleaning',
        price = 50,
        image = "img/wash_barrel.png", 
        onSelect = function()
            SendNUIMessage({
                action = "openQuantityModal",
                item = 'wash_barrel',
                label = 'Wash Barrel',
                price = 50
            })
        end
    })
    
    table.insert(shopMenu, {
        title = 'Process Table',
        description = 'Processing',
        price = 50,
        image = "img/processing_table.png", 
        onSelect = function()
            SendNUIMessage({
                action = "openQuantityModal",
                item = 'processing_table',
                label = 'Processing Table',
                price = 50
            })
        end
    })
    
    ShowCustomMenu("The Outlaw's Garden", shopMenu)
end



-- Delete NPC
local function DeleteNPC()
    if npcPed then
        DeletePed(npcPed)
        npcPed = nil
        npcSpawned = false
    end
end

CreateThread(function()
    SetupBlip()
    Wait(1000)
    SpawnNPC()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteNPC()
        if npcBlip then RemoveBlip(npcBlip) end
    end
end)
