local ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

function ParticleSystem:new(x, y)
    local instance = setmetatable({}, self)
    instance.particles = love.graphics.newParticleSystem(love.graphics.newImage("assets/images/particle.png"), 100)
    instance.particles:setParticleLifetime(0.25, 1.5)
    instance.particles:setEmissionRate(0)
    instance.particles:setSizeVariation(1)
    instance.particles:setLinearAcceleration(-50, -50, 50, 50)
    instance.particles:setColors(1, 1, 1, 1, 1, 1, 1, 0)
    instance.particles:setSizes(0.1, 0.5)
    instance.particles:emit(30)
    instance.x = x
    instance.y = y
    instance.active = true
    instance.lifespan = 1.5
    return instance
end

function ParticleSystem:update(dt)
    if self.active then
        self.particles:update(dt)
        self.lifespan = self.lifespan - dt
        if self.lifespan <= 0 then
            self.active = false
        end
    end
end

function ParticleSystem:draw()
    if self.active then
        love.graphics.draw(self.particles, self.x, self.y)
    end
end

return ParticleSystem
