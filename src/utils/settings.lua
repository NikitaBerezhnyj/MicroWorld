local Settings         = {}

Settings.presets       = {
    { label = "1024 × 768",  width = 1024,     height = 768 },
    { label = "1280 × 720",  width = 1280,     height = 720 },
    { label = "1200 × 720",  width = 1200,     height = 720 },
    { label = "1920 × 1080", width = 1920,     height = 1080 },
    { label = "Fullscreen",  fullscreen = true }
}

Settings.currentPreset = 3
Settings.fullscreen    = false

function Settings.getCurrent()
    return Settings.presets[Settings.currentPreset]
end

function Settings.apply()
    local p = Settings.getCurrent()
    if p.fullscreen then
        Settings.fullscreen = true
        love.window.setMode(0, 0, {
            fullscreen     = true,
            fullscreentype = "desktop",
            resizable      = false,
        })
    else
        Settings.fullscreen = false
        love.window.setMode(p.width, p.height, {
            fullscreen = false,
            resizable  = false,
            centered   = true,
        })
    end

    local w, h = love.graphics.getDimensions()
    if love.resize then love.resize(w, h) end
end

function Settings.setPreset(index)
    Settings.currentPreset = index
end

return Settings
