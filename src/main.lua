local ScreenManager  = require("utils.screenManager")
local MenuScreen     = require("screens.menuScreen")
local GameScreen     = require("screens.gameScreen")
local SettingsScreen = require("screens.settingsScreen")
local hexToRGB       = require("utils.hexToRGB")

function love.load()
    math.randomseed(os.time())
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setBackgroundColor(hexToRGB.convert("#092327"))
    ScreenManager.register("menu", MenuScreen)
    ScreenManager.register("game", GameScreen)
    ScreenManager.register("settings", SettingsScreen)
    ScreenManager.switch("menu")
end

function love.update(dt)
    ScreenManager.current():update(dt)
end

function love.draw()
    ScreenManager.current():draw()
end

function love.mousepressed(x, y, b)
    ScreenManager.current():mousepressed(x, y, b)
end

function love.keypressed(key)
    ScreenManager.current():keypressed(key)
end

function love.resize(w, h)
    local screen = ScreenManager.current()
    if screen.resize then
        screen:resize(w, h)
    end
end
