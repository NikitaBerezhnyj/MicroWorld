local Header = require("ui.header")
local Button = require("ui.button")

local hexToRGB = require("utils.hexToRGB")

local Food = require("entities.food")
-- local Herbivore = require("entities.herbivore")
-- local Predator = require("entities.predator")

local ParticleSystem = require("systems.particleSystem")

local isGameStarted = false
local isPaused = false

local gameTitle, pauseHeader
local mainMenuButtons = {}
local mainMenuCharacters = {}
local pauseButtons = {}

-- local allObjects = { food = {}, herbivores = {}, predators = {} }
local foodObjects = {}
-- local herbivoreObjects = {}
-- local predatorObjects = {}

local particleSystems = {}

function love.load()
    math.randomseed(os.time())
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setBackgroundColor(hexToRGB.convert("#092327"))

    for i = 1, math.random(5, 15) do
        local imageUrls = {
            "assets/images/food.png",
            "assets/images/predator.png",
            "assets/images/herbivore.png"
        }
        local imageUrl = imageUrls[math.random(1, 3)]

        local x, y
        local isValidPosition = false

        while not isValidPosition do
            x = math.random() < 0.5 and math.random(50, 200) or math.random(600, 750)
            y = math.random() < 0.5 and math.random(50, 200) or math.random(400, 550)

            isValidPosition = true
            for _, existing in ipairs(mainMenuCharacters) do
                local dx = existing.x - x
                local dy = existing.y - y
                local distance = math.sqrt(dx * dx + dy * dy)

                if distance < 100 then
                    isValidPosition = false
                    break
                end
            end
        end

        local card = {
            imageUrl = imageUrl,
            x = x,
            y = y,
            rotate = math.random(0, 360),
            size = math.random(15, 50),
            opacity = math.random(50, 100) / 100
        }

        table.insert(mainMenuCharacters, card)
    end

    gameTitle = Header:new("MicroWorld", 0, 200, "h1")

    table.insert(mainMenuButtons, Button:new("Start Game", 275, 300, 250, 50, function() isGameStarted = true end))
    table.insert(mainMenuButtons,
        Button:new("Load", 275, 370, 250, 50, function()
            print("Load data")
            isGameStarted = true
        end))
    table.insert(mainMenuButtons, Button:new("Exit", 275, 440, 250, 50, love.event.quit))

    pauseHeader = Header:new("Pause", 0, 200, "h2")

    table.insert(pauseButtons, Button:new("Continue", 275, 300, 250, 50, function() isPaused = false end))
    table.insert(pauseButtons, Button:new("Save", 275, 370, 250, 50, function() print("Save data") end))
    table.insert(pauseButtons, Button:new("Back to Menu", 275, 440, 250, 50, function()
        isGameStarted = false
        isPaused = false
    end))
end

function love.update(dt)
    if isGameStarted and not isPaused then
        if #foodObjects == 0 then
            local numFoodObjects = math.random(1, 10)

            for i = 1, numFoodObjects do
                local x, y
                local isValidPosition = false

                while not isValidPosition do
                    x = math.random(50, 750)
                    y = math.random(50, 550)
                    isValidPosition = true

                    for _, food in ipairs(foodObjects) do
                        local dx = x - food.x
                        local dy = y - food.y
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < 10 then
                            isValidPosition = false
                            break
                        end
                    end
                end

                table.insert(foodObjects, Food:new(x, y))
            end
        end

        for i = #foodObjects, 1, -1 do
            local food = foodObjects[i]
            if not food:update(dt) then
                table.insert(particleSystems, ParticleSystem:new(food.x, food.y))
                table.remove(foodObjects, i)
            end
        end

        for i = 1, #foodObjects do
            for j = i + 1, #foodObjects do
                local food1 = foodObjects[i]
                local food2 = foodObjects[j]
                if food1:checkCollision(food2) then
                    print("Food collision detected")
                    food1:separate(food2)
                    food2:separate(food1)
                end
            end
            -- Приклад стикання з хижаком
            -- for j = i + 1, #predatorObjects do
            --     local food = foodObjects[i]
            --     local predator = predatorObjects[j]
            --     if food:checkCollision(predator) then
            --         local dx = predator.x - food.x
            --         local dy = predator.y - food.y
            --         local distance = math.sqrt(dx * dx + dy * dy)

            --         local nx, ny = dx / distance, dy / distance

            --         local distance1 = math.random(50, 150)
            --         local distance2 = math.random(50, 150)

            --         food.targetX = math.max(50, math.min(750, food.x - nx * distance1))
            --         food.targetY = math.max(50, math.min(550, food.y - ny * distance1))

            --         predator.targetX = math.max(50, math.min(750, predator.x + nx * distance2))
            --         predator.targetY = math.max(50, math.min(550, predator.y + ny * distance2))
            --     end
            -- end
        end

        for i = #particleSystems, 1, -1 do
            particleSystems[i]:update(dt)
            if not particleSystems[i].active then
                table.remove(particleSystems, i)
            end
        end

        --
        -- allObjects = {}

        -- for _, obj in ipairs(foodObjects) do
        --     table.insert(allObjects.food, obj)
        -- end
        -- for _, obj in ipairs(herbivoreObjects) do
        --     table.insert(allObjects.herbivores, obj)
        -- end
        -- for _, obj in ipairs(predatorObjects) do
        --     table.insert(allObjects.predators, obj)
        -- end
    end
end

function love.draw()
    if not isGameStarted then
        for _, character in ipairs(mainMenuCharacters) do
            love.graphics.setColor(1, 1, 1, character.opacity)
            local img = love.graphics.newImage(character.imageUrl)
            love.graphics.draw(img, character.x, character.y, math.rad(character.rotate), character.size / img:getWidth(),
                character.size / img:getHeight())
        end
        gameTitle:draw()
        for _, button in ipairs(mainMenuButtons) do
            button:draw()
        end
    elseif isPaused then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        pauseHeader:draw()
        for _, button in ipairs(pauseButtons) do
            button:draw()
        end
    else
        for _, food in ipairs(foodObjects) do
            food:draw()
        end
    end

    for _, ps in ipairs(particleSystems) do
        ps:draw()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if not isGameStarted then
        for _, btn in ipairs(mainMenuButtons) do
            btn:mousePressed(x, y)
        end
    elseif isPaused then
        for _, btn in ipairs(pauseButtons) do
            btn:mousePressed(x, y)
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        if isGameStarted then
            isPaused = not isPaused
        end
    end
    -- !!! Тільки для тестування !!!
    -- Видалити коли будемо наближатись до релізу
    if key == "r" then
        if isGameStarted then
            foodObjects = {}

            local numFoodObjects = math.random(1, 10)

            for i = 1, numFoodObjects do
                local x, y
                local isValidPosition = false

                while not isValidPosition do
                    x = math.random(50, 750)
                    y = math.random(50, 550)
                    isValidPosition = true

                    for _, food in ipairs(foodObjects) do
                        local dx = x - food.x
                        local dy = y - food.y
                        local distance = math.sqrt(dx * dx + dy * dy)

                        if distance < 10 then
                            isValidPosition = false
                            break
                        end
                    end
                end

                table.insert(foodObjects, Food:new(x, y))
            end
        end
    end
end
