local ScreenManager    = require("utils.screenManager")
local Viewport         = require("utils.viewport")
local Header           = require("ui.header")
local Button           = require("ui.button")
local Food             = require("entities.food")
local Herbivore        = require("entities.herbivore")
local Predator         = require("entities.predator")
local ParticleSystem   = require("systems.particleSystem")
local PhysicsSystem    = require("systems.physicsSystem")
local DataSystem       = require("systems.dataSystem")
local GameScreen       = {}

local SIM_W            = Viewport.baseWidth
local SIM_H            = Viewport.baseHeight
local MARGIN           = 50
local MAX_HERBIVORES   = 20
local MAX_PREDATORS    = 20

local isPaused         = false
local isDebug          = false
local allObjects       = {}
local foodObjects      = {}
local herbivoreObjects = {}
local predatorObjects  = {}
local particleSystems  = {}
local pauseHeader, pauseButtons

local function randX()
    return math.random(MARGIN, SIM_W - MARGIN)
end

local function randY()
    return math.random(MARGIN, SIM_H - MARGIN)
end

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

        Button:new("Save", cx, cy + 20, bw, bh, function()
            ScreenManager.push("load", {
                mode   = "save",
                onSave = function(slot)
                    DataSystem.save(slot, foodObjects, herbivoreObjects, predatorObjects)
                end,
            })
        end),

        Button:new("Settings", cx, cy + 90, bw, bh, function()
            ScreenManager.push("settings", {
                onClose = function()
                    isPaused = true
                end
            })
        end),

        Button:new("Back to Menu", cx, cy + 160, bw, bh, function()
            ScreenManager.switch("menu")
        end),
    }
end

function GameScreen:load(params)
    isPaused         = false
    allObjects       = { food = {}, herbivores = {}, predators = {} }
    foodObjects      = {}
    herbivoreObjects = {}
    predatorObjects  = {}
    particleSystems  = {}

    if params and params.loadSlot then
        local saveData = DataSystem.load(params.loadSlot)
        if saveData then
            foodObjects, herbivoreObjects, predatorObjects =
                DataSystem.restore(saveData, Food, Herbivore, Predator)
        else
            spawnFood(); spawnHerbivores(); spawnPredators()
        end
    else
        spawnFood(); spawnHerbivores(); spawnPredators()
    end

    allObjects.food       = foodObjects
    allObjects.herbivores = herbivoreObjects
    allObjects.predators  = predatorObjects

    buildPauseLayout()
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
end

function GameScreen:update(dt)
    if isPaused then return end

    if #foodObjects == 0 then
        spawnFood()
    end

    for i = #foodObjects, 1, -1 do
        if not foodObjects[i]:update(dt) then
            table.insert(particleSystems, ParticleSystem:new(foodObjects[i].x, foodObjects[i].y))
            table.remove(foodObjects, i)
        end
    end

    for i = 1, #foodObjects do
        for j = i + 1, #foodObjects do
            if foodObjects[i]:checkCollision(foodObjects[j]) then
                foodObjects[i]:separate(foodObjects[j])
            end
        end
    end

    for i = #herbivoreObjects, 1, -1 do
        if not herbivoreObjects[i]:update(dt, allObjects) then
            table.insert(particleSystems, ParticleSystem:new(herbivoreObjects[i].x, herbivoreObjects[i].y))
            table.remove(herbivoreObjects, i)
        end
    end

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
                        table.insert(newborns, Herbivore:newFromParents(h1, h2, bx, by))
                    end
                end
                if h1.target == h2 then
                    h1.target = nil; h1.targetX = randX(); h1.targetY = randY(); h1.state = "idle"
                end
                if h2.target == h1 then
                    h2.target = nil; h2.targetX = randX(); h2.targetY = randY(); h2.state = "idle"
                end
            end
        end
    end

    for _, nb in ipairs(newborns) do
        table.insert(herbivoreObjects, nb)
    end

    for hi = #herbivoreObjects, 1, -1 do
        local herb = herbivoreObjects[hi]
        for fi = #foodObjects, 1, -1 do
            if herb:checkCollision(foodObjects[fi]) then
                herb.lifespan = herb.lifespan + math.random(5, 15)
                table.insert(particleSystems, ParticleSystem:new(foodObjects[fi].x, foodObjects[fi].y))
                table.remove(foodObjects, fi)
            end
        end
    end

    for i = #predatorObjects, 1, -1 do
        if not predatorObjects[i]:update(dt, allObjects) then
            table.insert(particleSystems, ParticleSystem:new(predatorObjects[i].x, predatorObjects[i].y))
            table.remove(predatorObjects, i)
        end
    end

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

    for pi = #predatorObjects, 1, -1 do
        local pred = predatorObjects[pi]
        for hi = #herbivoreObjects, 1, -1 do
            if pred:checkCollision(herbivoreObjects[hi]) then
                pred.lifespan = pred.lifespan + math.random(8, 20)
                table.insert(particleSystems, ParticleSystem:new(herbivoreObjects[hi].x, herbivoreObjects[hi].y))
                table.remove(herbivoreObjects, hi)
            end
        end
    end

    PhysicsSystem.resolve({ herbivoreObjects, foodObjects, predatorObjects })

    for i = #particleSystems, 1, -1 do
        particleSystems[i]:update(dt)
        if not particleSystems[i].active then table.remove(particleSystems, i) end
    end

    allObjects.food       = foodObjects
    allObjects.herbivores = herbivoreObjects
    allObjects.predators  = predatorObjects
end

function GameScreen:draw()
    Viewport.apply()
    for _, f in ipairs(foodObjects) do f:draw() end
    for _, h in ipairs(herbivoreObjects) do h:draw(isDebug) end
    for _, ps in ipairs(particleSystems) do ps:draw() end
    for _, p in ipairs(predatorObjects) do p:draw(isDebug) end
    Viewport.release()
    if isPaused then
        local W, H = love.graphics.getDimensions()
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, W, H)

        pauseHeader:draw()
        for _, btn in ipairs(pauseButtons) do btn:draw() end
    end
end

function GameScreen:mousepressed(x, y, b)
    if not isPaused then return end
    for _, btn in ipairs(pauseButtons) do btn:mousePressed(x, y) end
end

function GameScreen:keypressed(key)
    if key == "escape" then
        isPaused = not isPaused
    end

    if key == "r" and not isPaused then
        spawnFood(); spawnHerbivores(); spawnPredators()
    end

    if key == "d" then
        isDebug = not isDebug
    end
end

return GameScreen
