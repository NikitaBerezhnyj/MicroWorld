local Entity = {}
Entity.__index = Entity

function Entity:new(x, y, imagePath, lifespan, speed)
    local instance = setmetatable({}, self)
    instance.x = x
    instance.y = y
    instance.lifespan = lifespan or math.random(10, 30)
    instance.speed = speed or math.random(20, 100)
    instance.image = imagePath and love.graphics.newImage(imagePath) or nil
    instance.scale = 1
    instance.targetX = x
    instance.targetY = y
    return instance
end

function Entity:getRadius()
    if self.image then
        return (self.image:getWidth() * self.scale) / 2
    end
    return 0
end

function Entity:checkCollision(otherEntity)
    local dx = self.x - otherEntity.x
    local dy = self.y - otherEntity.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (self:getRadius() + otherEntity:getRadius())
end

function Entity:move(dt)
    local dx, dy = self.targetX - self.x, self.targetY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance > 1 then
        local nx, ny = dx / distance, dy / distance
        self.x = self.x + nx * self.speed * dt
        self.y = self.y + ny * self.speed * dt
    else
        self.targetX, self.targetY = math.random(50, 750), math.random(50, 550)
    end
end

function Entity:separate(other)
    local dx = other.x - self.x
    local dy = other.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance > 0 then
        local nx, ny = dx / distance, dy / distance

        local separationDistance = math.random(50, 150)

        self.targetX = math.max(50, math.min(750, self.x - nx * separationDistance))
        self.targetY = math.max(50, math.min(550, self.y - ny * separationDistance))

        other.targetX = math.max(50, math.min(750, other.x + nx * separationDistance))
        other.targetY = math.max(50, math.min(550, other.y + ny * separationDistance))
    end
end

function Entity:update(dt)
    self.lifespan = self.lifespan - dt
    if self.lifespan <= 0 then
        return false
    end
    self:move(dt)
    return true
end

function Entity:draw()
    if self.image then
        self.scale = math.max(self.lifespan / 25, 2 / self.image:getWidth())
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.image, self.x, self.y, 0, self.scale, self.scale, self.image:getWidth() / 2,
            self.image:getHeight() / 2)
    end
end

return Entity
