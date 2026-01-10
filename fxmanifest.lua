game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

fx_version 'cerulean'
lua54 'yes'

author 'Devchacha'
description 'Advanced Weed Farming System'
version '1.0.0'

shared_scripts {
    '@rsg-core/shared/locale.lua',
    '@ox_lib/init.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/img/*',
    'html/script.js',
    'locales/*.lua'
}

ui_page 'html/index.html'

dependencies {
    'rsg-core',
    'ox_lib',
    'oxmysql',
    'rsg-target'
}

-- Stream custom props
this_is_a_map 'yes'
data_file 'DLC_ITYP_REQUEST' 'stream/prop_weed_ytyp.ytyp'
