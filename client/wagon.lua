local RSGCore = exports['rsg-core']:GetCoreObject()

local activeWagon = nil

local function PlayWagonCam(vehicle)
    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 1433.0, 258.0, 92.5, -15.0, 0.0, 145.0, 50.0, false, 0)
    PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
    
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)
    
    Wait(4000)
    
    RenderScriptCams(false, true, 1000, true, true)
    DestroyCam(cam, false)
end

-- Spawn Wagon Event
RegisterNetEvent('rsg-weed:client:spawnWagon', function()
    -- Prevent multiple wagons (Delete old one)
    if activeWagon and DoesEntityExist(activeWagon) then
        DeleteVehicle(activeWagon)
    end

    local model = GetHashKey('cart05')
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 50 do Wait(100); timeout = timeout + 1 end
    
    if HasModelLoaded(model) then
        -- Spawn at specific location near shop
        local spawnCoords = vector4(1426.9, 252.6, 90.8, 180.0) -- Heading adjusted
        
        local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
        
        -- Wait a moment for physics to settle
        Wait(500)
        SetVehicleOnGroundProperly(vehicle)
        Wait(200)
        
        -- Freeze vehicle briefly to stabilize
        FreezeEntityPosition(vehicle, true)
        Wait(100)
        FreezeEntityPosition(vehicle, false)
        
        SetModelAsNoLongerNeeded(model)
        
        -- Set State
        Entity(vehicle).state:set('isWaterWagon', true, true)
        Entity(vehicle).state:set('waterLevel', 50, true) -- 50 uses
        
        activeWagon = vehicle -- Track it
        
        PlayWagonCam(vehicle)
        
        lib.notify({ title = 'Wagon Rented', description = '50 Litres water still left', type = 'success' })
    else
        lib.notify({ title = 'Error', description = 'Failed to load wagon model', type = 'error' })
    end
end)

-- Interaction Setup (Target)
CreateThread(function()
    local models = { GetHashKey('cart05') }
    
    exports['rsg-target']:AddTargetModel(models, {
        options = {
            -- 1. Fill Bucket (Back of Wagon)
            {
                name = 'wagon_fill_bucket',
                icon = 'fa-solid fa-bucket',
                label = 'Fill Bucket',
                canInteract = function(entity)
                    return Entity(entity).state.isWaterWagon
                end,
                action = function(entity)
                    local currentLevel = Entity(entity).state.waterLevel or 0
                    
                    if currentLevel <= 0 then
                        lib.notify({ title = 'Empty', description = 'The water tank is empty!', type = 'error' })
                        return
                    end
                    
                    local hasBucket = RSGCore.Functions.HasItem(Config.EmptyBucketItem)
                    if not hasBucket then
                        lib.notify({ title = 'Error', description = 'You need an empty bucket!', type = 'error' })
                        return
                    end
                    
                    local ped = PlayerPedId()
                    TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), -1, true, false, false, false)
                    Wait(4000)
                    ClearPedTasksImmediately(ped)
                    
                    TriggerServerEvent('rsg-weed:server:fillBucket') -- Gives fullbucket
                    
                    -- Decrease Level
                    local newLevel = currentLevel - 1
                    Entity(entity).state:set('waterLevel', newLevel, true)
                    
                    lib.notify({ title = 'Water Tank', description = newLevel .. ' Litres water still left', type = 'info' })
                end
            },
            -- 2. Refill Wagon Tank (In River)
            {
                name = 'wagon_refill_tank',
                icon = 'fa-solid fa-water',
                label = 'Refill Tank',
                canInteract = function(entity)
                    return Entity(entity).state.isWaterWagon and IsEntityInWater(entity)
                end,
                action = function(entity)
                   local ped = PlayerPedId()
                   -- Maybe play animation?
                   TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), -1, true, false, false, false)
                   Wait(5000)
                   ClearPedTasksImmediately(ped)
                   
                   Entity(entity).state:set('waterLevel', 50, true)
                   lib.notify({ title = 'Refilled', description = 'Water Tank Refilled (50/50)', type = 'success' })
                end
            }
        },
        distance = 3.0,
    })
end)

-- Cleanup on Resource Stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if activeWagon and DoesEntityExist(activeWagon) then
            DeleteVehicle(activeWagon)
            activeWagon = nil
        end
    end
end)
