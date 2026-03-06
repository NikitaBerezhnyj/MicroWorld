local Entity                  = {}
Entity.__index                = Entity

Entity.MIN_COLLISION_RADIUS   = 10
Entity.LIFESPAN_SCALE_DIVISOR = 100

Entity.SIM_X_MIN              = 50
Entity.SIM_X_MAX              = 750
Entity.SIM_Y_MIN              = 50
Entity.SIM_Y_MAX              = 550

function Entity:new(x, y, imagePath, lifespan, speed)
    local instance    = setmetatable({}, self)
    instance.x        = x
    instance.y        = y
    instance.lifespan = lifespan or math.random(10, 30)
    instance.speed    = speed or math.random(20, 100)
    instance.image    = imagePath and love.graphics.newImage(imagePath) or nil
    instance.scale    = 1
    instance.targetX  = x
    instance.targetY  = y
    return instance
end

function Entity:getRadius()
    local visualRadius = self.image
        and (self.image:getWidth() * self.scale) / 2
        or 0
    return math.max(visualRadius, self.MIN_COLLISION_RADIUS)
end

function Entity:distanceTo(other)
    local dx = other.x - self.x
    local dy = other.y - self.y
    return math.sqrt(dx * dx + dy * dy)
end

function Entity:checkCollision(other)
    return self:distanceTo(other) < (self:getRadius() + other:getRadius())
end

function Entity:clampToBounds()
    self.x = math.max(Entity.SIM_X_MIN, math.min(Entity.SIM_X_MAX, self.x))
    self.y = math.max(Entity.SIM_Y_MIN, math.min(Entity.SIM_Y_MAX, self.y))
end

function Entity:randomTarget()
    self.targetX = math.random(Entity.SIM_X_MIN, Entity.SIM_X_MAX)
    self.targetY = math.random(Entity.SIM_Y_MIN, Entity.SIM_Y_MAX)
end

function Entity:move(dt, targetObject)
    local tx, ty
    if targetObject then
        tx, ty = targetObject.x, targetObject.y
    else
        tx, ty = self.targetX, self.targetY
    end
    local dx, dy   = tx - self.x, ty - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance > 1 then
        local nx, ny = dx / distance, dy / distance
        local mult   = self.speedMultiplier or 1.0
        self.x       = self.x + nx * self.speed * mult * dt
        self.y       = self.y + ny * self.speed * mult * dt
    else
        if not targetObject then
            self:randomTarget()
        end
    end
end

function Entity:separate(other)
    local dx       = other.x - self.x
    local dy       = other.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance > 0 then
        local nx, ny         = dx / distance, dy / distance
        local separationDist = math.random(50, 150)
        self.targetX         = math.max(Entity.SIM_X_MIN, math.min(Entity.SIM_X_MAX, self.x - nx * separationDist))
        self.targetY         = math.max(Entity.SIM_Y_MIN, math.min(Entity.SIM_Y_MAX, self.y - ny * separationDist))
        other.targetX        = math.max(Entity.SIM_X_MIN, math.min(Entity.SIM_X_MAX, other.x + nx * separationDist))
        other.targetY        = math.max(Entity.SIM_Y_MIN, math.min(Entity.SIM_Y_MAX, other.y + ny * separationDist))
    end
end

function Entity:update(dt)
    self.lifespan = self.lifespan - dt
    if self.lifespan <= 0 then return false end
    self:move(dt)
    return true
end

function Entity:draw()
    if self.image then
        local minScaleFromCollision = (self.MIN_COLLISION_RADIUS * 2) / self.image:getWidth()
        self.scale = math.max(
            self.lifespan / self.LIFESPAN_SCALE_DIVISOR,
            minScaleFromCollision
        )
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(
            self.image,
            self.x, self.y,
            0,
            self.scale, self.scale,
            self.image:getWidth() / 2,
            self.image:getHeight() / 2
        )
    end
end

return Entity
