Config = {}

Config.Debug = false
Config.Language = 'en'

-- Growth Settings
Config.GrowthTime = 25 -- Minutes to fully grown
Config.WaterRate = 10.0 -- Water loss per minute (100 / 10 = 10 mins per water, 3 times per 30min stage)
Config.HarvestAmount = { min = 2, max = 5 }

-- 3 Strains Definition (stage1 = small seedling, stage2 = mature plant)
Config.Strains = {
    kalka = {
        label = 'Guarma Gold',
        props = { stage1 = 's_inv_bloodflower01x', stage2 = 'prop_weed_02', stage3 = 'prop_weed_01' },
        items = { seed = 'seed_kalka', leaf = 'leaf_kalka', washed = 'washed_kalka', dried = 'dried_kalka', trimmed = 'trimmed_kalka', joint = 'joint_kalka' }
    },
    purp = {
        label = 'Ambarino Frost',
        props = { stage1 = 's_inv_bloodflower01x', stage2 = 'prop_weed_04', stage3 = 'prop_weed_03' },
        items = { seed = 'seed_purp', leaf = 'leaf_purp', washed = 'washed_purp', dried = 'dried_purp', trimmed = 'trimmed_purp', joint = 'joint_purp' }
    },
    tex = {
        label = 'New Austin Haze',
        props = { stage1 = 's_inv_bloodflower01x', stage2 = 'prop_weed_06', stage3 = 'prop_weed_05' },
        items = { seed = 'seed_tex', leaf = 'leaf_tex', washed = 'washed_tex', dried = 'dried_tex', trimmed = 'trimmed_tex', joint = 'joint_tex' }
    }
}

-- Processing Props
Config.ProcessingProps = {
    wash = 'p_bucket04x', -- Water Bucket
    dry = 'p_hangracklrg01x',   -- Hanging Rack
    trim = 'p_hangracklrg01x'   -- Hanging Rack
}

-- Processing Time (ms)
Config.ProcessTime = {
    wash = 5000,
    dry = 10000,
    trim = 5000,
    roll = 5000
}


-- Tools
Config.ShovelItem = 'shovel'
Config.WaterItem = 'fullbucket' -- Reusable bucket
Config.EmptyBucketItem = 'bucket' -- Returns this after use
Config.BucketUses = 10 -- Number of uses per bucket
Config.FertilizerItem = 'fertilizer' -- Adds growth speed or instant growth

-- Water Pumps Models for Third Eye
Config.Pumps = {
    'p_waterpump01x_opt2'
}

-- Water Types (Rivers/Lakes) 
Config.WaterTypes = {
    [1] =  {["name"] = "Sea of Coronado",       ["waterhash"] = -247856387, ["watertype"] = "lake"},
    [2] =  {["name"] = "San Luis River",        ["waterhash"] = -1504425495, ["watertype"] = "river"},
    [3] =  {["name"] = "Lake Don Julio",        ["waterhash"] = -1369817450, ["watertype"] = "lake"},
    [4] =  {["name"] = "Flat Iron Lake",        ["waterhash"] = -1356490953, ["watertype"] = "lake"},
    [5] =  {["name"] = "Upper Montana River",   ["waterhash"] = -1781130443, ["watertype"] = "river"},
    [6] =  {["name"] = "Owanjila",              ["waterhash"] = -1300497193, ["watertype"] = "river"},
    [7] =  {["name"] = "HawkEye Creek",         ["waterhash"] = -1276586360, ["watertype"] = "river"},
    [8] =  {["name"] = "Little Creek River",    ["waterhash"] = -1410384421, ["watertype"] = "river"},
    [9] =  {["name"] = "Dakota River",          ["waterhash"] = 370072007, ["watertype"] = "river"},
    [10] =  {["name"] = "Beartooth Beck",       ["waterhash"] = 650214731, ["watertype"] = "river"},
    [11] =  {["name"] = "Lake Isabella",        ["waterhash"] = 592454541, ["watertype"] = "lake"},
    [12] =  {["name"] = "Cattail Pond",         ["waterhash"] = -804804953, ["watertype"] = "lake"},
    [13] =  {["name"] = "Deadboot Creek",       ["waterhash"] = 1245451421, ["watertype"] = "river"},
    [14] =  {["name"] = "Spider Gorge",         ["waterhash"] = -218679770, ["watertype"] = "river"},
    [15] =  {["name"] = "O'Creagh's Run",       ["waterhash"] = -1817904483, ["watertype"] = "lake"},
    [16] =  {["name"] = "Moonstone Pond",       ["waterhash"] = -811730579, ["watertype"] = "lake"},
    [17] =  {["name"] = "Roanoke Valley",       ["waterhash"] = -1229593481, ["watertype"] = "river"},
    [18] =  {["name"] = "Elysian Pool",         ["waterhash"] = -105598602, ["watertype"] = "lake"},
    [19] =  {["name"] = "Lannahechee River",    ["waterhash"] = -2040708515, ["watertype"] = "river"},
    [20] =  {["name"] = "Dakota River",         ["waterhash"] = 370072007, ["watertype"] = "river"},
    [21] =  {["name"] = "Random1",              ["waterhash"] = 231313522, ["watertype"] = "river"},
    [22] =  {["name"] = "Random2",              ["waterhash"] = 2005774838, ["watertype"] = "river"},
    [23] =  {["name"] = "Random3",              ["waterhash"] = -1287619521, ["watertype"] = "river"},
    [24] =  {["name"] = "Random4",              ["waterhash"] = -1308233316, ["watertype"] = "river"},
    [25] =  {["name"] = "Random5",              ["waterhash"] = -196675805, ["watertype"] = "river"},
}


-- Seed Vendor
Config.SeedVendor = {
    model = 'u_m_m_valgenstoreowner_01', -- Same model as Moonshiner (proven to work)
    coords = vector4(1443.7, 263.3, 90.6, 180.0), -- User specified location (Rotated 180)
    blip = { label = 'Gardening Supplies', sprite = 'blip_shop_shady', scale = 0.8 }
}

-- Processing Props (Placeable items)
Config.PlaceableProps = {
    ['wash_barrel'] = { model = 'p_bucket04x', label = 'Wash Bucket' },
    ['processing_table'] = { model = 'p_hangracklrg01x', label = 'Processing Rack' }
}

-- Selling System (Dynamic)
Config.Selling = {
    command = 'sellweed',
    model = 's_drugpackage_02x', -- Drug package (hash: 1180245127)
    -- Cities where selling is allowed
    allowedCities = {
        {name = "Valentine", coords = vector3(-281.0, 793.0, 118.0), radius = 150.0},
        {name = "Rhodes", coords = vector3(1225.0, -1305.0, 76.0), radius = 120.0},
        {name = "Saint Denis", coords = vector3(2632.0, -1312.0, 52.0), radius = 200.0},
        {name = "Blackwater", coords = vector3(-813.0, -1324.0, 43.0), radius = 130.0}
    },
    buyerPrices = {
        ['joint'] = {min = 25, max = 35}
    },
    purchaseAmounts = {1, 5, 10},
    timeBetweenBuyers = {min = 10000, max = 30000},
    maxBuyersPerSession = 10,
    cooldownTime = 300000 -- 5 mins
}

-- Smoking System
Config.Smoking = {
    -- Joint settings
    jointDuration = 8000, -- Animation duration in ms
    jointHealthBoost = 10, -- Health restored
    jointStaminaBoost = 20, -- Stamina restored
    
    -- Pipe settings
    pipePuffs = 10, -- Number of puffs per loaded pipe
    pipePuffDuration = 3000, -- Animation duration per puff
    pipeHealthBoost = 5, -- Health per puff
    pipeStaminaBoost = 10, -- Stamina per puff
    
    -- Visual Effects
    enableHighEffect = true, -- Enable screen blur/drunk effect
    highDuration = 60000, -- Effect duration in ms (1 minute)
    highIntensity = 0.3, -- 0.0 to 1.0
    
    -- Key bindings (RedM control hashes)
    dropKey = 0x3B24C470, -- B key - Drop/Stop smoking
    smokeKey = 0x07B8BEAF, -- E key - Take a puff
    changeKey = 0xD51B784F, -- X key - Change stance
    
    -- Requirements
    requireMatches = true -- Require matches to light joints/pipes
}

-- Law Enforcement Alerts
Config.PoliceAlerts = {
    enabled = true,
    chance = 50, -- % chance to alert police (1-100)
    cooldown = 600000, -- 10 Minutes cooldown between alerts (to prevent spam)
    jobs = { 'police', 'sheriff', 'marshal' }, -- Jobs to notify
    blip = {
        enabled = true,
        time = 60000, -- Blip duration on map (ms)
        radius = 50.0, -- Radius blip size
        sprite = 'blip_ambient_herding', -- Generic blip usually used for activity
        color = 'BLIP_MODIFIER_MP_COLOR_8' -- Red
    }
}

