local RSGCore = exports['rsg-core']:GetCoreObject()

-- Initialize Locale
Lang = Locale:new({
    phrases = Locales[Config.Language] or Locales['en'],
    warnOnMissing = true
})

print('RSG-Weed Loaded')
