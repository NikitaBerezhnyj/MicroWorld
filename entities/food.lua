local Entity = require("entities.entity")
local Food = setmetatable({}, { __index = Entity })
Food.__index = Food

function Food:new(x, y)
    local instance = setmetatable(Entity:new(x, y, "assets/images/food.png"), self)

    instance.speed = 0
    instance.moving = math.random() > 0.5
    if instance.moving then
        instance.speed = math.random(20, 100)
        instance.targetX, instance.targetY = math.random(50, 750), math.random(50, 550)
    end

    return instance
end

return Food
