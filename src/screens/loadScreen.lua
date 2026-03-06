-- screens/loadScreen.lua
-- Відкривається через push() поверх меню або гри.
-- Отримує params.mode ("load"|"save") та params.onSave (callback).
-- Закривається через pop() — стан екрану під ним не змінюється.

local ScreenManager  = require("utils.screenManager")
local DataSystem     = require("systems.dataSystem")
local Header         = require("ui.header")
local Button         = require("ui.button")

local LoadScreen     = {}

-- локальний стан екрану
local mode           = "load"
local onSaveCallback = nil
local slots          = {}
local slotButtons    = {}
local backButton     = nil
local titleHeader    = nil
local confirmSlot    = nil
local confirmButtons = {}

local SLOT_W         = 480
local SLOT_H         = 80
local GAP            = 20

local function buildLayout()
    local W, H   = love.graphics.getDimensions()
    local cx     = W / 2
    local label  = (mode == "save") and "Зберегти гру" or "Завантажити гру"
    titleHeader  = Header:new(label, 0, H * 0.10, "h2")

    local totalH = 3 * SLOT_H + 2 * GAP
    local startY = H / 2 - totalH / 2

    slots        = DataSystem.getSlots()
    slotButtons  = {}

    for i = 1, 3 do
        local s = slots[i]
        local x = cx - SLOT_W / 2
        local y = startY + (i - 1) * (SLOT_H + GAP)
        local lbl

        if s.exists then
            lbl = string.format("Слот %d  |  %s  |  🌿%d  🐾%d  🍎%d",
                i, s.timestamp or "???",
                s.herbivores or 0, s.predators or 0, s.food or 0)
        else
            lbl = string.format("Слот %d  —  (порожньо)", i)
        end

        local idx = i
        slotButtons[i] = Button:new(lbl, x, y, SLOT_W, SLOT_H, function()
            if mode == "save" then
                if s.exists then
                    confirmSlot = idx
                else
                    if onSaveCallback then onSaveCallback(idx) end
                    ScreenManager.pop()
                end
            else
                if s.exists then
                    -- повністю замінюємо стек: menu → game з завантаженим слотом
                    ScreenManager.switch("game", { loadSlot = idx })
                end
            end
        end)
    end

    backButton = Button:new("← Назад",
        cx - SLOT_W / 2,
        startY + 3 * (SLOT_H + GAP) + 10,
        SLOT_W, 50,
        function()
            ScreenManager.pop()
        end)

    local cw = 180
    confirmButtons = {
        Button:new("Перезаписати", cx - cw - 10, H / 2 - 25, cw, 50, function()
            if onSaveCallback and confirmSlot then
                onSaveCallback(confirmSlot)
            end
            confirmSlot = nil
            ScreenManager.pop()
        end),
        Button:new("Скасувати", cx + 10, H / 2 - 25, cw, 50, function()
            confirmSlot = nil
        end),
    }
end

-- ── Screen lifecycle ─────────────────────────────────────────────────────────

-- params: { mode = "load"|"save", onSave = function(slot) }
function LoadScreen:load(params)
    params         = params or {}
    mode           = params.mode or "load"
    onSaveCallback = params.onSave or nil
    confirmSlot    = nil
    buildLayout()
end

function LoadScreen:unload()
    -- нічого не потрібно очищати
end

function LoadScreen:resize(w, h)
    buildLayout()
end

function LoadScreen:update(dt) end

function LoadScreen:draw()
    local W, H = love.graphics.getDimensions()

    -- Напівпрозорий оверлей поверх того що є під нами
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, W, H)
    love.graphics.setColor(1, 1, 1, 1)

    titleHeader:draw()

    if confirmSlot then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(
            string.format("Перезаписати слот %d?", confirmSlot),
            0, H / 2 - 70, W, "center")
        for _, btn in ipairs(confirmButtons) do btn:draw() end
        return
    end

    for i, btn in ipairs(slotButtons) do
        if mode == "load" and not slots[i].exists then
            love.graphics.setColor(1, 1, 1, 0.35)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        btn:draw()
    end
    love.graphics.setColor(1, 1, 1, 1)
    backButton:draw()
end

function LoadScreen:mousepressed(x, y, b)
    if confirmSlot then
        for _, btn in ipairs(confirmButtons) do btn:mousePressed(x, y) end
        return
    end
    for _, btn in ipairs(slotButtons) do btn:mousePressed(x, y) end
    backButton:mousePressed(x, y)
end

function LoadScreen:keypressed(key)
    if key == "escape" then
        if confirmSlot then
            confirmSlot = nil
        else
            ScreenManager.pop()
        end
    end
end

return LoadScreen
