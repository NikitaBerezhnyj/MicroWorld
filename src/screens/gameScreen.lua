local ScreenManager    = require("utils.screenManager")
local Viewport         = require("utils.viewport")
local Header           = require("ui.header")
local Button           = require("ui.button")
local Dropdown         = require("ui.dropdown")
local Settings         = require("utils.settings")

local Food             = require("entities.food")
local Herbivore        = require("entities.herbivore")
local Predator         = require("entities.predator")
local ParticleSystem   = require("systems.particleSystem")

local PhysicsSystem    = require("systems.physicsSystem")

local GameScreen       = {}

-- ── Константи симуляції ─────────────────────────────────────────────────────
local SIM_W            = Viewport.baseWidth
local SIM_H            = Viewport.baseHeight
local MARGIN           = 50
local MAX_HERBIVORES   = 20
local MAX_PREDATORS    = 20

-- ── Локальний стан ──────────────────────────────────────────────────────────
local isPaused         = false
local isSettingsOpen   = false
local isDebug          = false

local allObjects       = {}
local foodObjects      = {}
local herbivoreObjects = {}
local predatorObjects  = {}
local particleSystems  = {}

local pauseHeader, pauseButtons
local settingsHeader, settingsDropdown, settingsBackButton

-- ─── Helpers ────────────────────────────────────────────────────────────────
local function randX() return math.random(MARGIN, SIM_W - MARGIN) end
local function randY() return math.random(MARGIN, SIM_H - MARGIN) end

local function spawnFood()
    foodObjects     = {}
    allObjects.food = foodObjects

    for _ = 1, math.random(3, 10) do
        local x, y, valid
        repeat
            valid = true
            x, y  = randX(), randY()
            for _, f in ipairs(foodObjects) do
                if math.sqrt((x - f.x) ^ 2 + (y - f.y) ^ 2) < 10 then
                    valid = false
                    break
                end
            end
        until valid

        table.insert(foodObjects, Food:new(x, y))
    end
end

local function spawnHerbivores()
    herbivoreObjects      = {}
    allObjects.herbivores = herbivoreObjects

    for _ = 1, math.random(2, 5) do
        table.insert(herbivoreObjects, Herbivore:new(randX(), randY()))
    end
end

local function spawnPredators()
    predatorObjects      = {}
    allObjects.predators = predatorObjects
    for _ = 1, math.random(1, 3) do
        table.insert(predatorObjects, Predator:new(randX(), randY()))
    end
end

-- ─── Layout Builders ────────────────────────────────────────────────────────
local function buildPauseLayout()
    local W, H = love.graphics.getDimensions()
    local bw, bh = 250, 50
    local cx = W / 2 - bw / 2
    local cy = H / 2

    pauseHeader = Header:new("Pause", 0, cy - 130, "h2")

    pauseButtons = {
        Button:new("Continue", cx, cy - 50, bw, bh, function()
            isPaused = false
        end),
        Button:new("Settings", cx, cy + 20, bw, bh, function()
            isSettingsOpen = true
        end),
        Button:new("Save", cx, cy + 90, bw, bh, function()
            print("Save data")
        end),
        Button:new("Back to Menu", cx, cy + 160, bw, bh, function()
            ScreenManager.switch("menu")
        end),
    }
end

local function buildSettingsLayout()
    local W, H = love.graphics.getDimensions()
    local bw = 250
    local cx = W / 2 - bw / 2

    settingsHeader = Header:new("Settings", 0, H * 0.15, "h2")

    settingsDropdown = Dropdown:new(
        cx, H * 0.40, bw, 50,
        Settings.presets,
        Settings.currentPreset,
        function(i)
            Settings.setPreset(i)
            Settings.apply()
        end
    )

    settingsBackButton = Button:new("Back", cx, H * 0.58, bw, 50, function()
        isSettingsOpen = false
    end)
end

-- ─── load / unload ──────────────────────────────────────────────────────────
function GameScreen:load()
    isPaused         = false
    isSettingsOpen   = false

    allObjects       = { food = {}, herbivores = {}, predators = {} }
    foodObjects      = {}
    herbivoreObjects = {}
    predatorObjects  = {}
    particleSystems  = {}

    spawnFood()
    spawnHerbivores()
    spawnPredators()

    buildPauseLayout()
    buildSettingsLayout()
end

function GameScreen:unload()
    foodObjects      = {}
    herbivoreObjects = {}
    predatorObjects  = {}
    particleSystems  = {}
    allObjects       = {}
end

function GameScreen:resize(w, h)
    buildPauseLayout()
    buildSettingsLayout()
end

-- ─── update ─────────────────────────────────────────────────────────────────
function GameScreen:update(dt)
    if isPaused then return end

    if #foodObjects == 0 then spawnFood() end

    -- FOOD UPDATE
    for i = #foodObjects, 1, -1 do
        if not foodObjects[i]:update(dt) then
            table.insert(particleSystems,
                ParticleSystem:new(foodObjects[i].x, foodObjects[i].y))
            table.remove(foodObjects, i)
        end
    end

    -- FOOD ↔ FOOD COLLISION
    for i = 1, #foodObjects do
        for j = i + 1, #foodObjects do
            local f1, f2 = foodObjects[i], foodObjects[j]
            if f1:checkCollision(f2) then
                f1:separate(f2)
            end
        end
    end

    -- HERBIVORE UPDATE
    for i = #herbivoreObjects, 1, -1 do
        if not herbivoreObjects[i]:update(dt, allObjects) then
            table.insert(particleSystems,
                ParticleSystem:new(herbivoreObjects[i].x, herbivoreObjects[i].y))
            table.remove(herbivoreObjects, i)
        end
    end

    -- HERBIVORE ↔ HERBIVORE COLLISION
    local newborns = {}

    for i = 1, #herbivoreObjects do
        for j = i + 1, #herbivoreObjects do
            local h1, h2 = herbivoreObjects[i], herbivoreObjects[j]

            if h1:checkCollision(h2) then
                h1:separateFromPeer(h2)
                h2:separateFromPeer(h1)

                if #herbivoreObjects + #newborns < MAX_HERBIVORES then
                    if h1:tryReproduce(h2) then
                        local bx = (h1.x + h2.x) / 2
                        local by = (h1.y + h2.y) / 2
                        table.insert(newborns,
                            Herbivore:newFromParents(h1, h2, bx, by))
                    end
                end

                if h1.target == h2 then
                    h1.target = nil
                    h1.targetX = randX()
                    h1.targetY = randY()
                    h1.state = "idle"
                end

                if h2.target == h1 then
                    h2.target = nil
                    h2.targetX = randX()
                    h2.targetY = randY()
                    h2.state = "idle"
                end
            end
        end
    end

    for _, nb in ipairs(newborns) do
        table.insert(herbivoreObjects, nb)
    end

    -- HERBIVORE ↔ FOOD
    for hi = #herbivoreObjects, 1, -1 do
        local herb = herbivoreObjects[hi]

        for fi = #foodObjects, 1, -1 do
            if herb:checkCollision(foodObjects[fi]) then
                herb.lifespan = herb.lifespan + math.random(5, 15)

                table.insert(particleSystems,
                    ParticleSystem:new(foodObjects[fi].x, foodObjects[fi].y))

                table.remove(foodObjects, fi)
            end
        end
    end

    -- PREDATOR UPDATE
    for i = #predatorObjects, 1, -1 do
        if not predatorObjects[i]:update(dt, allObjects) then
            table.insert(particleSystems,
                ParticleSystem:new(predatorObjects[i].x, predatorObjects[i].y))
            table.remove(predatorObjects, i)
        end
    end

    -- PREDATOR ↔ PREDATOR COLLISION
    local predNewborns = {}
    for i = 1, #predatorObjects do
        for j = i + 1, #predatorObjects do
            local p1, p2 = predatorObjects[i], predatorObjects[j]
            if p1:checkCollision(p2) then
                p1:separateFromPeer(p2)
                p2:separateFromPeer(p1)
                if #predatorObjects + #predNewborns < MAX_PREDATORS then
                    if p1:tryReproduce(p2) then
                        local bx = (p1.x + p2.x) / 2
                        local by = (p1.y + p2.y) / 2
                        table.insert(predNewborns, Predator:newFromParents(p1, p2, bx, by))
                    end
                end
            end
        end
    end
    for _, nb in ipairs(predNewborns) do
        table.insert(predatorObjects, nb)
    end

    -- PREDATOR ↔ HERBIVORE (хижак їсть травоїдного)
    for pi = #predatorObjects, 1, -1 do
        local pred = predatorObjects[pi]
        for hi = #herbivoreObjects, 1, -1 do
            if pred:checkCollision(herbivoreObjects[hi]) then
                pred.lifespan = pred.lifespan + math.random(8, 20)
                table.insert(particleSystems,
                    ParticleSystem:new(herbivoreObjects[hi].x, herbivoreObjects[hi].y))
                table.remove(herbivoreObjects, hi)
            end
        end
    end

    -- PHYSICS — розширити щоб включав predatorObjects
    PhysicsSystem.resolve({ herbivoreObjects, foodObjects, predatorObjects })

    -- PARTICLES
    for i = #particleSystems, 1, -1 do
        particleSystems[i]:update(dt)
        if not particleSystems[i].active then
            table.remove(particleSystems, i)
        end
    end

    allObjects.food       = foodObjects
    allObjects.herbivores = herbivoreObjects
    allObjects.predators  = predatorObjects
end

-- ─── draw ───────────────────────────────────────────────────────────────────
function GameScreen:draw()
    Viewport.apply()
    for _, f in ipairs(foodObjects) do f:draw() end
    -- for _, h in ipairs(herbivoreObjects) do h:draw() end
    for _, h in ipairs(herbivoreObjects) do
        h:draw(isDebug)
    end

    for _, ps in ipairs(particleSystems) do
        ps:draw()
    end

    for _, p in ipairs(predatorObjects) do
        p:draw(isDebug)
    end

    Viewport.release()

    if isPaused then
        local W, H = love.graphics.getDimensions()

        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, W, H)

        if isSettingsOpen then
            settingsHeader:draw()

            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.printf("Resolution", 0, H * 0.34, W, "center")

            settingsDropdown:draw()
            settingsBackButton:draw()

            if settingsDropdown.isOpen then
                settingsDropdown:drawList()
            end
        else
            pauseHeader:draw()
            for _, btn in ipairs(pauseButtons) do
                btn:draw()
            end
        end
    end
end

-- ─── input ──────────────────────────────────────────────────────────────────
function GameScreen:mousepressed(x, y, b)
    if not isPaused then return end

    if isSettingsOpen then
        settingsDropdown:mousepressed(x, y)
        settingsBackButton:mousePressed(x, y)
    else
        for _, btn in ipairs(pauseButtons) do
            btn:mousePressed(x, y)
        end
    end
end

function GameScreen:keypressed(key)
    if key == "escape" then
        if isSettingsOpen then
            isSettingsOpen = false
        else
            isPaused = not isPaused
        end
    end

    if key == "r" and not isPaused then
        spawnFood()
        spawnHerbivores()
        spawnPredators()
    end

    if key == "d" then
        isDebug = not isDebug
    end
end

return GameScreen
