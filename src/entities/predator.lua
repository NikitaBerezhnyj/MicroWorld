local Creature       = require("entities.creature")
local Predator       = setmetatable({}, { __index = Creature })
Predator.__index     = Predator

Predator.FOOD_SOURCE = "herbivores"
Predator.STAT_BOUNDS = {
    speed        = { min = 30, max = 60 },
    visionRadius = { min = 90, max = 140 },
    lifespan     = { min = 20, max = 120 },
    hunger       = { min = 0.05, max = 1.0 },
    social       = { min = 0.05, max = 1.0 },
    fear         = { min = 0.0, max = 0.0 },
}

local DRIVES_CONFIG  = {
    hungerMin = 60,
    hungerMax = 95,
    socialMin = 10,
    socialMax = 40,
    fearMin = 0,
    fearMax = 0,
    visionMin = 100,
    visionMax = 180,
    speedMin = 40,
    speedMax = 80,
    lifespanMin = 30,
    lifespanMax = 70,
}

function Predator:new(x, y)
    local instance       = setmetatable(
        Creature:new(x, y, "assets/images/predator.png", "predator", DRIVES_CONFIG),
        self
    )
    instance.foodSource  = "herbivores"
    instance.drives.fear = 0
    instance._baseSocial = instance.drives.social
    return instance
end

function Predator:update(dt, allObjects)
    return self:updateBehavior(dt, allObjects)
end

return Predator
