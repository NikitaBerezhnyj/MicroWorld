local Entity = require("entities.entity")
local Creature = setmetatable({}, { __index = Entity })
Creature.__index = Creature

function Creature:new(x, y, imagePath, species)
    local instance = setmetatable(Entity:new(x, y, imagePath), self)
    instance.species = species -- "herbivore" або "predator"
    instance.visionRadius = math.random(80, 150)
    instance.speed = math.random(20, 60)
    instance.lifespan = math.random(50, 100)
    instance.target = nil
    return instance
end

function Creature:findTarget()
    -- Пошук цілей в радіусі свого бачення
end

-- Тільки для травоїдних
-- function Creature:avoidPredators(predators)
--     if self.species == "herbivore" then
--         for _, predator in ipairs(predators) do
--             local dx, dy = predator.x - self.x, predator.y - self.y
--             local distance = math.sqrt(dx * dx + dy * dy)
--             if distance < self.visionRadius / 2 then
--                 -- Втікаємо у протилежному напрямку
--                 self.target = { x = self.x - dx, y = self.y - dy }
--                 break
--             end
--         end
--     end
-- end

-- Винести це в основний клас та через поліморфізм переписати в підкласах
-- function Creature:reproduce(partner)
--     if partner and self.species == partner.species then
--         local offspringSpecies = self.species
--         if self.species == "herbivore" and math.random() < 0.1 then
--             offspringSpecies = "predator"
--         elseif self.species == "predator" and math.random() < 0.1 then
--             offspringSpecies = "food"
--         end
--         return Creature:new(self.x, self.y, offspringSpecies)
--     end
-- end

return Creature
