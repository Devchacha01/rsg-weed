local RSGCore = exports['rsg-core']:GetCoreObject()
local PlantsData = {} -- All known plants data
local spawnedPlants = {} -- Physically spawned objects
local inPlanting = false

-- Quick ground check function
local function GetGroundZ(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 20.0, false)
    if found then return groundZ end
    return z
end

-- Model Loader
local function LoadPropModel(modelName)
    local model = GetHashKey(modelName)
    if not HasModelLoaded(model) then
        RequestModel(model)
        local t = 0
        while not HasModelLoaded(model) do Wait(10) t=t+1 end
    end
    return model
end

-- Helper to draw 3D text
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    if onScreen then
        SetTextScale(0.40, 0.40)
        SetTextFontForCurrentCommand(1) -- Default RDR2 Serif-like
        SetTextColor(248, 222, 126, 255) -- Vintage Gold
        SetTextDropshadow(4, 0, 0, 0, 255) -- Strong Shadow
        local str = CreateVarString(10, "LITERAL_STRING", text)
        SetTextCentre(1)
        DisplayText(str, _x, _y)
    end
end

local function DespawnPlantObject(plantId)
    if spawnedPlants[plantId] then
        local zoneName = "weed_plant_" .. plantId
        exports['rsg-target']:RemoveZone(zoneName)
        
        if DoesEntityExist(spawnedPlants[plantId].entity) then
            DeleteEntity(spawnedPlants[plantId].entity)
        end
        spawnedPlants[plantId] = nil
    end
end

local function SpawnPlantObject(plant)
    if spawnedPlants[plant.id] then return end -- Already spawned

    local strainData = Config.Strains[plant.strain]
    if not strainData then return end
    
    local stage = plant.stage or 1
    local modelName = strainData.props['stage' .. stage]
    if not modelName then return end
    
    local model = LoadPropModel(modelName)
    if not HasModelLoaded(model) then 
        print('^1[RSG-WEED] Failed to load model: ' .. tostring(modelName) .. '^7')
        return 
    end
    
    -- Safe Coordinate Extraction
    local pCoords = plant.coords
    local x, y, z
    if type(pCoords) == 'table' then
       x = pCoords.x or pCoords[1]
       y = pCoords.y or pCoords[2]
       z = pCoords.z or pCoords[3]
    elseif type(pCoords) == 'vector3' or type(pCoords) == 'vector4' then
       x, y, z = pCoords.x, pCoords.y, pCoords.z
    end

    if not x or not y or not z then 
        print('^1[RSG-WEED] Invalid coordinates for plant ID: ' .. tostring(plant.id) .. ' - REMOVING LOCAL DATA^7')
        -- print('^3[RSG-WEED] Dump: ' .. json.encode(plant) .. '^7') 
        PlantsData[plant.id] = nil -- Self-heal: Remove broken plant from local cache
        return 
    end

    -- Calculate precise ground Z
    local groundZ = GetGroundZ(x, y, z)
    
    -- Create object (Local only is fine for visual prop with zone target)
    local obj = CreateObject(model, x, y, groundZ, false, false, false)
    
    SetEntityAsMissionEntity(obj, true, true)
    SetEntityHeading(obj, plant.coords.w or 0.0)
    SetEntityCollision(obj, true, true)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    
    spawnedPlants[plant.id] = { entity = obj }
    
    -- Add ZONE Target instead of Entity Target (Fixes small model / no collision issues)
    local zoneName = "weed_plant_" .. plant.id
    local label = strainData.label
    if plant.stage == 1 then 
        label = "Seedling " .. label 
    elseif plant.stage == 2 then 
        label = "Young " .. label 
    end
    
    exports['rsg-target']:AddCircleZone(zoneName, vector3(x, y, z), 0.75, {
        name = zoneName,
        debugPoly = false,
    }, {
        options = {
            {
                type = "client",
                action = function()
                    local pData = PlantsData[plant.id]
                    if pData then
                        pData.timeRemaining = math.ceil(Config.GrowthTime * (1 - (pData.growth/100)))
                        pData.label = strainData.label
                        pData.fertilized = pData.fertilized or 0
                        
                        SetNuiFocus(true, true)
                        SendNUIMessage({
                            action = 'openPlant',
                            plant = pData
                        })
                    end
                end,
                icon = "fas fa-seedling",
                label = "Inspect " .. label,
            }
        },
        distance = 3.0,
    })
end

-- Distance Check Loop
CreateThread(function()
    while true do
        Wait(1500) -- Check every 1.5 seconds
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        for id, plant in pairs(PlantsData) do
            if plant and plant.coords then
                local pCoords = plant.coords
                -- Handle both map {x=,y=,z=} and array [1,2,3] formats safely
                local x = pCoords.x or pCoords[1]
                local y = pCoords.y or pCoords[2]
                local z = pCoords.z or pCoords[3]
                
                if x and y and z then
                    local dist = #(coords - vector3(x, y, z))
                    
                    if dist < 50.0 then
                        if not spawnedPlants[id] then
                            SpawnPlantObject(plant)
                        end
                    else
                        if spawnedPlants[id] then
                            DespawnPlantObject(id)
                        end
                    end
                end
            end
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('plantAction', function(data, cb)
    local action = data.action
    local plantId = data.plantId
    
    if action == 'water' then
        -- Check if plant is already at 100% water
        local plant = PlantsData[plantId]
        if plant and plant.water >= 100 then
            lib.notify({ title = 'Error', description = 'Plant is already fully watered!', type = 'error' })
            cb({ success = false })
            return
        end
        
        local hasItem = RSGCore.Functions.HasItem(Config.WaterItem)
        if not hasItem then
            lib.notify({ title = 'Error', description = 'You need a full water bucket!', type = 'error' })
            return
        end
        
        -- Close UI immediately
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })

        -- Start animation BEFORE progress bar
        local ped = PlayerPedId()
        TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), -1, true, false, false, false)

        if lib.progressBar({
            duration = 4000,
            label = 'Watering...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
            },
            anim = false, -- We handle anim manually
        }) then
            ClearPedTasksImmediately(ped)
            
            RSGCore.Functions.TriggerCallback('rsg-weed:server:waterPlant', function(result)
                if result.success then
                    -- Optimistic update
                    if PlantsData[plantId] then
                        PlantsData[plantId].water = math.min(100, PlantsData[plantId].water + 50)
                    end
                    
                    if result.usesLeft then
                        lib.notify({ title = 'Watered', description = 'Uses remaining: ' .. result.usesLeft, type = 'success' })
                    end
                else
                    lib.notify({ title = 'Error', description = result.msg or 'Failed', type = 'error' })
                end
            end, plantId)
        else
            ClearPedTasksImmediately(ped)
            lib.notify({ title = 'Cancelled', description = 'Watering cancelled', type = 'error' })
        end
        
        cb({ success = true })
        
    elseif action == 'fertilize' then
        -- Check if plant is already fertilized or fully grown
        local plant = PlantsData[plantId]
        if plant then
            if plant.fertilized and plant.fertilized >= 1 then
                lib.notify({ title = 'Error', description = 'Plant is already fertilized!', type = 'error' })
                cb({ success = false })
                return
            end
            if plant.growth >= 99 then
                lib.notify({ title = 'Error', description = 'Plant is fully grown, no need to fertilize!', type = 'error' })
                cb({ success = false })
                return
            end
        end
        
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })

        -- Start animation BEFORE progress bar
        local ped = PlayerPedId()
        TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_FEED_CHICKEN'), -1, true, false, false, false)

        if lib.progressBar({
            duration = 4000,
            label = 'Fertilizing...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
            },
            anim = false,
        }) then
            ClearPedTasksImmediately(ped)
            
            RSGCore.Functions.TriggerCallback('rsg-weed:server:fertilizePlant', function(result)
                if result.success then
                    lib.notify({ title = 'Success', description = 'Fertilized! (+10% Growth)', type = 'success' })
                else
                    lib.notify({ title = 'Error', description = result.msg or 'Need Fertilizer!', type = 'error' })
                end
            end, plantId)
        else
            ClearPedTasksImmediately(ped)
            lib.notify({ title = 'Cancelled', description = 'Fertilizing cancelled', type = 'error' })
        end
        
    elseif action == 'destroy' then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        
        local ped = PlayerPedId()
        local plant = PlantsData[plantId]
        
        if not plant then
            lib.notify({ title = 'Error', description = 'Plant not found', type = 'error' })
            cb({ success = false })
            return
        end
        
        -- Get plant coords for fire effect
        local plantCoords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)
        
        -- Start animation
        TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), -1, true, false, false, false)
        
        if lib.progressBar({
            duration = 3000,
            label = 'Setting Fire...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
            },
            anim = false,
        }) then
            ClearPedTasksImmediately(ped)
            
            -- Create actual fire at plant location using native
            local fire = StartScriptFire(plantCoords.x, plantCoords.y, plantCoords.z, 10, false, false, false, 16)
            
            -- Let fire burn for 3 seconds
            Wait(3000)
            
            -- Remove fire
            RemoveScriptFire(fire)
            
            -- Now delete the plant
            TriggerServerEvent('rsg-weed:server:deletePlant', plantId, 'destroy')
            lib.notify({ title = 'Destroyed', description = 'Plant burned to ashes!', type = 'success' })
            cb({ success = true, message = 'Plant destroyed.' })
        else
            ClearPedTasksImmediately(ped)
            lib.notify({ title = 'Cancelled', description = 'Action cancelled', type = 'error' })
        end
        
    elseif action == 'harvest' then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        
        local plant = PlantsData[plantId]
        if plant and plant.growth >= 99 then
            -- Start animation BEFORE progress bar
            local ped = PlayerPedId()
            TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_FARMER_WEEDING'), -1, true, false, false, false)
            
            if lib.progressBar({
                duration = 4000,
                label = 'Harvesting...',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    combat = true,
                },
                anim = false,
            }) then
                ClearPedTasksImmediately(ped)
                TriggerServerEvent('rsg-weed:server:deletePlant', plantId, 'harvest')
                cb({ success = true, message = 'Harvested!' })
            else
                ClearPedTasksImmediately(ped)
                lib.notify({ title = 'Cancelled', description = 'Harvesting cancelled', type = 'error' })
            end
        else
            lib.notify({ title = 'Error', description = 'Plant not ready!', type = 'error' })
            cb({ success = false, message = 'Plant not ready!' })
        end
    end
end)


RegisterNetEvent('rsg-weed:client:spawnPlant', function(plant)
    PlantsData[plant.id] = plant
    -- Distance loop will handle spawning if close
end)

RegisterNetEvent('rsg-weed:client:updatePlant', function(plant)
    PlantsData[plant.id] = plant
    
    -- If physically spawned, check if model needs update (stage change)
    if spawnedPlants[plant.id] then
        local strainData = Config.Strains[plant.strain]
        local currentModel = GetEntityModel(spawnedPlants[plant.id].entity)
        local newModelHash = GetHashKey(strainData.props['stage' .. plant.stage])
        
        if currentModel ~= newModelHash then
            -- Respawn to update model
            DespawnPlantObject(plant.id)
            SpawnPlantObject(plant)
        end
    end
end)

RegisterNetEvent('rsg-weed:client:updatePlantsBatch', function(plantsList)
    for _, plant in pairs(plantsList) do
        PlantsData[plant.id] = plant
        
        -- If physically spawned, check if model needs update (stage change)
        if spawnedPlants[plant.id] then
            local strainData = Config.Strains[plant.strain]
            local currentModel = GetEntityModel(spawnedPlants[plant.id].entity)
            local newModelHash = GetHashKey(strainData.props['stage' .. plant.stage])
            
            if currentModel ~= newModelHash then
                -- Respawn to update model
                DespawnPlantObject(plant.id)
                SpawnPlantObject(plant)
            end
        end
    end
end)

RegisterNetEvent('rsg-weed:client:removePlant', function(plantId)
    PlantsData[plantId] = nil
    DespawnPlantObject(plantId)
end)

RegisterNetEvent('rsg-weed:client:cleanupPlants', function(validIds)
    -- Remove local plants that are not in validIds
    for id, _ in pairs(PlantsData) do
        if not validIds[id] then
            PlantsData[id] = nil
            DespawnPlantObject(id)
        end
    end
end)

RegisterNetEvent('rsg-weed:client:startPlanting', function(strain)
    if inPlanting then return end
    
    local ped = PlayerPedId()
    
    RSGCore.Functions.TriggerCallback('rsg-weed:server:hasShovel', function(hasShovel)
        if not hasShovel then
            lib.notify({ title = 'Error', description = 'You need a shovel to plant!', type = 'error' })
            return
        end
        
        local coords = GetEntityCoords(ped)
        local strainData = Config.Strains[strain]
        if not strainData then return end
        
        local modelName = strainData.props.stage3 -- Use largest stage for ghost preview
        local model = LoadPropModel(modelName)
        
        inPlanting = true
        
        local ghost = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
        SetEntityAlpha(ghost, 150, false)
        SetEntityCollision(ghost, false, false)
        local ghostHeading = GetEntityHeading(ped)

        CreateThread(function()
            while inPlanting do
                Wait(0)
                local pCoords = GetEntityCoords(ped)
                local forward = GetEntityForwardVector(ped)
                
                -- Place 1.5m in front
                local x, y, z = table.unpack(pCoords + forward * 1.5)
                local groundZ = GetGroundZ(x, y, z)
                
                SetEntityCoords(ghost, x, y, groundZ, 0, 0, 0, false)
                SetEntityHeading(ghost, ghostHeading)
                
                -- Draw placement help text
                DrawText3D(x, y, z + 1.0, "[WASD] Move | [Q/E] Rotate | [ENTER] Place | [BACKSPACE] Cancel")
                
                -- Rotate with Q/E
                if IsControlPressed(0, 0xDE794E3E) then -- Q
                    ghostHeading = ghostHeading + 1.0
                end
                if IsControlPressed(0, 0xCEFD9220) then -- E
                    ghostHeading = ghostHeading - 1.0
                end

                -- Enter/Confirm to place
                if IsControlJustPressed(0, 0xC7B5340A) then
                    local finalCoords = GetEntityCoords(ghost)
                    local heading = GetEntityHeading(ghost)
                    DeleteEntity(ghost)
                    inPlanting = false
                    
                    -- Start animation BEFORE progress bar
                    local ped = PlayerPedId()
                    TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_FARMER_WEEDING'), -1, true, false, false, false)
                    
                    if lib.progressBar({
                        duration = 4000,
                        label = 'Planting Seed...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            car = true,
                            combat = true,
                        },
                        anim = false,
                    }) then
                        ClearPedTasksImmediately(ped)
                        local coordsToSend = { x = finalCoords.x, y = finalCoords.y, z = finalCoords.z, w = heading }
                        TriggerServerEvent('rsg-weed:server:savePlant', coordsToSend, strain)
                        lib.notify({ title = 'Planted', description = 'Seed planted!', type = 'success' })
                    else
                        ClearPedTasksImmediately(ped)
                        lib.notify({ title = 'Cancelled', description = 'Planting cancelled', type = 'error' })
                    end
                    break
                end
                
                -- Backspace to cancel
                if IsControlJustPressed(0, 0x156F7119) then
                    DeleteEntity(ghost)
                    inPlanting = false
                    lib.notify({ title = 'Cancelled', description = 'Planting cancelled', type = 'error' })
                    break
                end
            end
        end)
    end)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for id, _ in pairs(spawnedPlants) do
            DespawnPlantObject(id)
        end
    end
end)

-- Handle using fullbucket from inventory
RegisterNetEvent('rsg-weed:client:useWaterBucket', function()
    lib.notify({ title = 'Water Bucket', description = 'Approach a plant and inspect it to water!', type = 'inform' })
end)

-- Bucket Filling Logic & Third Eye
CreateThread(function()
    -- Third Eye for Pumps
    if Config.Pumps then
        exports['rsg-target']:AddTargetModel(Config.Pumps, {
            options = {
                {
                    type = "client",
                    action = function()
                        local hasBucket = RSGCore.Functions.HasItem(Config.EmptyBucketItem)
                        if hasBucket then
                            TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), -1, true, false, false, false)
                            Wait(4000)
                            ClearPedTasksImmediately(PlayerPedId())
                            TriggerServerEvent('rsg-weed:server:fillBucket')
                        else
                            lib.notify({ title = 'Error', description = 'You need an empty bucket!', type = 'error' })
                        end
                    end,
                    icon = "fas fa-water",
                    label = "Fill Bucket",
                }
            },
            distance = 2.0,
        })
    end

    -- Natural Water Interaction
    while true do
        local sleep = 1000
        
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsEntityInWater(ped) then
                sleep = 0
                local coords = GetEntityCoords(ped)
                
                if not IsPedInAnyVehicle(ped, true) then
                    DrawText3D(coords.x, coords.y, coords.z + 1.0, "[ALT] Fill Bucket")
                    
                    if IsControlJustPressed(0, 0x8AAA0AD4) then -- LEFT ALT key
                        local hasBucket = RSGCore.Functions.HasItem(Config.EmptyBucketItem)
                        if hasBucket then
                            TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), -1, true, false, false, false)
                            Wait(4000)
                            ClearPedTasksImmediately(ped)
                            TriggerServerEvent('rsg-weed:server:fillBucket')
                        else
                            lib.notify({ title = 'Error', description = 'You need an empty bucket!', type = 'error' })
                        end
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)
