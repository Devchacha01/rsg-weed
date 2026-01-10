-- Copy these into your shared/items.lua or ensure your framework loads this file
local Items = {
    -- TOOLS
    ['shovel'] = {
        ['name'] = 'shovel',
        ['label'] = 'Shovel',
        ['weight'] = 2000,
        ['type'] = 'item',
        ['image'] = 'shovel.png',
        ['unique'] = false,
        ['useable'] = false,
        ['shouldClose'] = false,
        ['combinable'] = nil,
        ['description'] = 'A sturdy shovel for planting.'
    },
    ['fertilizer'] = {
        ['name'] = 'fertilizer',
        ['label'] = 'Fertilizer',
        ['weight'] = 500,
        ['type'] = 'item',
        ['image'] = 'fertilizer.png',
        ['unique'] = false,
        ['useable'] = false,
        ['shouldClose'] = false,
        ['combinable'] = nil,
        ['description'] = 'Nutrient-rich fertilizer for plants.'
    },
    
    -- PROPS
    ['wash_barrel'] = {
        ['name'] = 'wash_barrel',
        ['label'] = 'Wash Bucket',
        ['weight'] = 5000,
        ['type'] = 'item',
        ['image'] = 'wash_barrel.png',
        ['unique'] = false,
        ['useable'] = true,
        ['shouldClose'] = true,
        ['combinable'] = nil,
        ['description'] = 'A barrel for washing herbs.'
    },
    ['processing_table'] = {
        ['name'] = 'processing_table',
        ['label'] = 'Processing Rack',
        ['weight'] = 5000,
        ['type'] = 'item',
        ['image'] = 'processing_table.png',
        ['unique'] = false,
        ['useable'] = true,
        ['shouldClose'] = true,
        ['combinable'] = nil,
        ['description'] = 'A table for drying and trimming.'
    },

    -- SEEDS
    ['seed_kalka'] = { ['name'] = 'seed_kalka', ['label'] = 'Guarma Gold Seed', ['weight'] = 1, ['type'] = 'item', ['image'] = 'seed_kalka.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Seed for Guarma Gold strain.' },
    ['seed_purp'] = { ['name'] = 'seed_purp', ['label'] = 'Ambarino Frost Seed', ['weight'] = 1, ['type'] = 'item', ['image'] = 'seed_purp.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Seed for Ambarino Frost strain.' },
    ['seed_tex'] = { ['name'] = 'seed_tex', ['label'] = 'New Austin Haze Seed', ['weight'] = 1, ['type'] = 'item', ['image'] = 'seed_tex.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Seed for New Austin Haze strain.' },

    -- RAW LEAVES
    ['leaf_kalka'] = { ['name'] = 'leaf_kalka', ['label'] = 'Guarma Gold Leaf', ['weight'] = 5, ['type'] = 'item', ['image'] = 'leaf_kalka.png', ['unique'] = false, ['useable'] = false,  ['description'] = 'Freshly harvested Guarma Gold leaves.' },
    ['leaf_purp'] = { ['name'] = 'leaf_purp', ['label'] = 'Ambarino Frost Leaf', ['weight'] = 5, ['type'] = 'item', ['image'] = 'leaf_purp.png', ['unique'] = false, ['useable'] = false, ['description'] = 'Freshly harvested Ambarino Frost leaves.' },
    ['leaf_tex'] = { ['name'] = 'leaf_tex', ['label'] = 'New Austin Haze Leaf', ['weight'] = 5, ['type'] = 'item', ['image'] = 'leaf_tex.png', ['unique'] = false, ['useable'] = false, ['description'] = 'Freshly harvested New Austin Haze leaves.' },

    -- WASHED
    ['washed_kalka'] = { ['name'] = 'washed_kalka', ['label'] = 'Washed Guarma Gold', ['weight'] = 5, ['type'] = 'item', ['image'] = 'washed_kalka.png', ['unique'] = false, ['useable'] = false, ['description'] = 'Cleaned Guarma Gold leaves.' },
    ['washed_purp'] = { ['name'] = 'washed_purp', ['label'] = 'Washed Ambarino Frost', ['weight'] = 5, ['type'] = 'item', ['image'] = 'washed_purp.png', ['unique'] = false, ['useable'] = false, ['description'] = 'Cleaned Ambarino Frost leaves.' },
    ['washed_tex'] = { ['name'] = 'washed_tex', ['label'] = 'Washed New Austin Haze', ['weight'] = 5, ['type'] = 'item', ['image'] = 'washed_tex.png', ['unique'] = false, ['useable'] = false, ['description'] = 'Cleaned New Austin Haze leaves.' },

    -- DRIED
    ['dried_kalka'] = { ['name'] = 'dried_kalka', ['label'] = 'Dried Guarma Gold', ['weight'] = 3, ['type'] = 'item', ['image'] = 'dried_kalka.png', ['unique'] = false, ['useable'] = false, ['description'] = 'Dried Guarma Gold buds.' },
    ['dried_purp'] = { ['name'] = 'dried_purp', ['label'] = 'Dried Ambarino Frost', ['weight'] = 3, ['type'] = 'item', ['image'] = 'dried_purp.png', ['unique'] = false, ['useable'] = false, ['description'] = 'Dried Ambarino Frost buds.' },
    ['dried_tex'] = { ['name'] = 'dried_tex', ['label'] = 'Dried New Austin Haze', ['weight'] = 3, ['type'] = 'item', ['image'] = 'dried_tex.png', ['unique'] = false, ['useable'] = false, ['description'] = 'Dried New Austin Haze buds.' },

    -- TRIMMED
    ['trimmed_kalka'] = { ['name'] = 'trimmed_kalka', ['label'] = 'Guarma Gold Bud', ['weight'] = 2, ['type'] = 'item', ['image'] = 'trimmed_kalka.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['description'] = 'Processed Guarma Gold weed, ready to roll.' },
    ['trimmed_purp'] = { ['name'] = 'trimmed_purp', ['label'] = 'Ambarino Frost Bud', ['weight'] = 2, ['type'] = 'item', ['image'] = 'trimmed_purp.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['description'] = 'Processed Ambarino Frost weed, ready to roll.' },
    ['trimmed_tex'] = { ['name'] = 'trimmed_tex', ['label'] = 'New Austin Haze Bud', ['weight'] = 2, ['type'] = 'item', ['image'] = 'trimmed_tex.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['description'] = 'Processed New Austin Haze weed, ready to roll.' },

    -- JOINTS
    ['joint_kalka'] = { ['name'] = 'joint_kalka', ['label'] = 'Guarma Gold Joint', ['weight'] = 1, ['type'] = 'item', ['image'] = 'joint_kalka.png', ['unique'] = false, ['useable'] = true, ['description'] = 'A rolled Guarma Gold joint.' },
    ['joint_purp'] = { ['name'] = 'joint_purp', ['label'] = 'Ambarino Frost Joint', ['weight'] = 1, ['type'] = 'item', ['image'] = 'joint_purp.png', ['unique'] = false, ['useable'] = true, ['description'] = 'A rolled Ambarino Frost joint.' },
    ['joint_tex'] = { ['name'] = 'joint_tex', ['label'] = 'New Austin Haze Joint', ['weight'] = 1, ['type'] = 'item', ['image'] = 'joint_tex.png', ['unique'] = false, ['useable'] = true, ['description'] = 'A rolled New Austin Haze joint.' },
    
    -- MISC
    ['rolling_paper'] = { ['name'] = 'rolling_paper', ['label'] = 'Rolling Paper', ['weight'] = 1, ['type'] = 'item', ['image'] = 'rolling_paper.png', ['unique'] = false, ['useable'] = true, ['description'] = 'Paper for rolling joints.' },

    -- BUCKETS
    ['bucket'] = { ['name'] = 'bucket', ['label'] = 'Empty Bucket', ['weight'] = 2000, ['type'] = 'item', ['image'] = 'bucket.png', ['unique'] = false, ['useable'] = false, ['description'] = 'An empty bucket.' },
    ['fullbucket'] = { ['name'] = 'fullbucket', ['label'] = 'Water Bucket', ['weight'] = 5000, ['type'] = 'item', ['image'] = 'fullbucket.png', ['unique'] = false, ['useable'] = true, ['description'] = 'A bucket full of water.' },

    -- SMOKING PIPE
    ['smoking_pipe'] = { ['name'] = 'smoking_pipe', ['label'] = 'Smoking Pipe', ['weight'] = 200, ['type'] = 'item', ['image'] = 'smoking_pipe.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['description'] = 'A pipe for smoking herbs.' },

    -- LOADED PIPES (with strain)
    ['loaded_pipe_kalka'] = { ['name'] = 'loaded_pipe_kalka', ['label'] = 'Pipe (Guarma Gold)', ['weight'] = 250, ['type'] = 'item', ['image'] = 'smoking_pipe.png', ['unique'] = true, ['useable'] = true, ['shouldClose'] = true, ['description'] = 'A pipe loaded with Guarma Gold bud.' },
    ['loaded_pipe_purp'] = { ['name'] = 'loaded_pipe_purp', ['label'] = 'Pipe (Ambarino Frost)', ['weight'] = 250, ['type'] = 'item', ['image'] = 'smoking_pipe.png', ['unique'] = true, ['useable'] = true, ['shouldClose'] = true, ['description'] = 'A pipe loaded with Ambarino Frost bud.' },
    ['loaded_pipe_tex'] = { ['name'] = 'loaded_pipe_tex', ['label'] = 'Pipe (New Austin Haze)', ['weight'] = 250, ['type'] = 'item', ['image'] = 'smoking_pipe.png', ['unique'] = true, ['useable'] = true, ['shouldClose'] = true, ['description'] = 'A pipe loaded with New Austin Haze bud.' },

    -- MATCHES (20 uses per box)
    ['matches'] = { ['name'] = 'matches', ['label'] = 'Match Box', ['weight'] = 50, ['type'] = 'item', ['image'] = 'matches.png', ['unique'] = true, ['useable'] = false, ['shouldClose'] = false, ['description'] = 'A box of safety matches. (20 uses)' },
}
return Items
