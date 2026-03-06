local Creature        = require("entities.creature")
local Herbivore       = setmetatable({}, { __index = Creature })
Herbivore.__index     = Herbivore

Herbivore.FOOD_SOURCE = "food"
Herbivore.STAT_BOUNDS = {
    speed        = { min = 40, max = 80 },
    visionRadius = { min = 140, max = 200 },
    lifespan     = { min = 15, max = 150 },
    hunger       = { min = 0.05, max = 1.0 },
    social       = { min = 0.05, max = 1.0 },
    fear         = { min = 0.05, max = 1.0 },
}

local DRIVES_CONFIG   = {
    hungerMin = 50,
    hungerMax = 85,
    socialMin = 30,
    socialMax = 70,
    fearMin = 50,
    fearMax = 90,
    visionMin = 80,
    visionMax = 140,
    speedMin = 30,
    speedMax = 65,
    lifespanMin = 40,
    lifespanMax = 90,
}

function Herbivore:new(x, y)
    local instance      = setmetatable(
        Creature:new(x, y, "assets/images/herbivore.png", "herbivore", DRIVES_CONFIG),
        self
    )
    instance.foodSource = "food"
    return instance
end

function Herbivore:update(dt, allObjects)
    return self:updateBehavior(dt, allObjects)
end

return Herbivore
