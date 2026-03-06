local ScreenManager  = require("utils.screenManager")
local Settings       = require("utils.settings")
local Header         = require("ui.header")
local Button         = require("ui.button")
local Dropdown       = require("ui.dropdown")
local SettingsScreen = {}
local title, dropdown, backButton

local function buildLayout()
    local W, H = love.graphics.getDimensions()
    local bw   = 250
    local cx   = W / 2 - bw / 2

    title      = Header:new("Settings", 0, H * 0.15, "h2")

    dropdown   = Dropdown:new(
        cx, H * 0.40, bw, 50,
        Settings.presets,
        Settings.currentPreset,
        function(i, preset)
            Settings.setPreset(i)
            Settings.apply()
        end
    )

    backButton = Button:new("Back", cx, H * 0.58, bw, 50, function()
        ScreenManager.switch("menu")
    end)
end

function SettingsScreen:load()
    buildLayout()
end

function SettingsScreen:resize(w, h)
    buildLayout()
end

function SettingsScreen:update(dt) end

function SettingsScreen:draw()
    local W, H = love.graphics.getDimensions()

    title:draw()

    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("Resolution", 0, H * 0.34, W, "center")

    dropdown:draw()
    backButton:draw()

    if dropdown.isOpen then
        dropdown:drawList()
    end
end

function SettingsScreen:mousepressed(x, y, b)
    dropdown:mousepressed(x, y)
    backButton:mousePressed(x, y)
end

function SettingsScreen:keypressed(key)
    if key == "escape" then
        ScreenManager.switch("menu")
    end
end

return SettingsScreen
