local Entity     = require("entities.entity")
local Creature   = setmetatable({}, { __index = Entity })
Creature.__index = Creature


Creature.STATE_IDLE     = "idle"
Creature.STATE_PURSUING = "pursuing"
Creature.STATE_FLEEING  = "fleeing"


local FEAR_THRESHOLD              = 1.2
local HUNGER_OVERRIDES_FEAR_RATIO = 0.85
local SOCIAL_SATIATION_VALUE      = 0.05
local SOCIAL_RECOVERY_TIME        = 20.0
local REPRODUCTION_COOLDOWN       = 18.0
local SEPARATION_IGNORE_TIME      = 3.0


Creature.DEFAULT_STAT_BOUNDS = {
    speed        = { min = 10, max = 150 },
    visionRadius = { min = 40, max = 220 },
    lifespan     = { min = 15, max = 150 },
    hunger       = { min = 0.05, max = 1.0 },
    social       = { min = 0.05, max = 1.0 },
    fear         = { min = 0.05, max = 1.0 },
}
Creature.MUTATION_CHANCE     = 0.2
Creature.MUTATION_STRENGTH   = 0.2
Creature.JUVENILE_REPRO_MIN  = 10
Creature.JUVENILE_REPRO_MAX  = 15


function Creature:new(x, y, imagePath, species, drivesConfig)
    local instance                = setmetatable(Entity:new(x, y, imagePath), self)
    instance.species              = species
    -- instance.foodSource           = self.FOOD_SOURCE or "food"
    local cfg                     = drivesConfig or {}
    instance.drives               = {
        hunger = math.random(cfg.hungerMin or 50, cfg.hungerMax or 80) / 100,
        social = math.random(cfg.socialMin or 20, cfg.socialMax or 60) / 100,
        fear   = math.random(cfg.fearMin or 30, cfg.fearMax or 80) / 100,
    }
    instance._baseSocial          = instance.drives.social
    instance.visionRadius         = math.random(cfg.visionMin or 80, cfg.visionMax or 150)
    instance.speed                = math.random(cfg.speedMin or 30, cfg.speedMax or 70)
    instance.lifespan             = math.random(cfg.lifespanMin or 50, cfg.lifespanMax or 100)
    instance.state                = Creature.STATE_IDLE
    instance.target               = nil
    instance.isChasing            = false
    instance.socialCooldown       = 0
    instance.reproductionCooldown = 0
    instance._separationIgnore    = {}
    return instance
end

function Creature:tryReproduce(partner)
    if self.reproductionCooldown > 0 or partner.reproductionCooldown > 0 then
        return false
    end
    self:_applySatiation()
    partner:_applySatiation()
    return true
end

function Creature:_applySatiation()
    self.drives.social        = SOCIAL_SATIATION_VALUE
    self.socialCooldown       = SOCIAL_RECOVERY_TIME
    self.reproductionCooldown = REPRODUCTION_COOLDOWN
end

function Creature:markSeparatedFrom(other)
    self._separationIgnore[other] = SEPARATION_IGNORE_TIME
end

function Creature:_isSeparating(other)
    return (self._separationIgnore[other] or 0) > 0
end

function Creature:separateFromPeer(other)
    local dx   = other.x - self.x
    local dy   = other.y - self.y
    local dist = self:distanceTo(other)
    if dist < 0.001 then
        local angle = math.random() * math.pi * 2
        dx, dy      = math.cos(angle), math.sin(angle)
        dist        = 1
    end
    local nx, ny   = dx / dist, dy / dist
    local pushDist = math.random(80, 140)
    self.targetX   = math.max(Entity.SIM_X_MIN, math.min(Entity.SIM_X_MAX, self.x - nx * pushDist))
    self.targetY   = math.max(Entity.SIM_Y_MIN, math.min(Entity.SIM_Y_MAX, self.y - ny * pushDist))
    self.target    = nil
    self.state     = Creature.STATE_IDLE
    self:markSeparatedFrom(other)
end

function Creature:_score(drive, distance)
    if distance <= 0 then return drive * 999 end
    return drive * (self.visionRadius / distance)
end

function Creature:_isAvailablePartner(other)
    return self.reproductionCooldown <= 0
        and other.reproductionCooldown <= 0
        and not self:_isSeparating(other)
end

function Creature:decideAction(allObjects)
    local food                       = allObjects[self.foodSource or "food"] or {}
    local partners                   = allObjects[self.species .. "s"] or {}
    local predators                  = allObjects.predators or {}

    local scariest, highestFearScore = nil, 0
    for _, pred in ipairs(predators) do
        local dist = self:distanceTo(pred)
        if dist <= self.visionRadius then
            local fs = self:_score(self.drives.fear, dist)
            if fs > highestFearScore then
                highestFearScore, scariest = fs, pred
            end
        end
    end

    if highestFearScore > FEAR_THRESHOLD then
        local bestFood, bestFoodDist = nil, math.huge
        for _, f in ipairs(food) do
            local d = self:distanceTo(f)
            if d <= self.visionRadius and d < bestFoodDist then
                bestFood, bestFoodDist = f, d
            end
        end
        if bestFood and (self.drives.hunger / self.drives.fear) > HUNGER_OVERRIDES_FEAR_RATIO then
            return Creature.STATE_PURSUING, bestFood
        end

        local dx   = self.x - scariest.x
        local dy   = self.y - scariest.y
        local dist = self:distanceTo(scariest)
        if dist > 0 then
            local nx, ny = dx / dist, dy / dist

            local wallMargin = 50
            local function wallForce(pos, minB, maxB)
                local forceMin = math.max(0, (minB + wallMargin - pos) / wallMargin)
                local forceMax = math.max(0, (pos - (maxB - wallMargin)) / wallMargin)
                return forceMax - forceMin
            end

            nx = nx + wallForce(self.x, Entity.SIM_X_MIN, Entity.SIM_X_MAX)
            ny = ny + wallForce(self.y, Entity.SIM_Y_MIN, Entity.SIM_Y_MAX)

            local len = math.sqrt(nx * nx + ny * ny)
            if len > 0 then nx, ny = nx / len, ny / len end

            local fleeX = self.x + nx * self.visionRadius
            local fleeY = self.y + ny * self.visionRadius

            fleeX = math.max(Entity.SIM_X_MIN, math.min(Entity.SIM_X_MAX, fleeX))
            fleeY = math.max(Entity.SIM_Y_MIN, math.min(Entity.SIM_Y_MAX, fleeY))

            return Creature.STATE_FLEEING, { x = fleeX, y = fleeY }
        end
    end

    local bestFood, bestFoodScore       = nil, 0
    local bestPartner, bestPartnerScore = nil, 0

    for _, f in ipairs(food) do
        local dist = self:distanceTo(f)
        if dist <= self.visionRadius then
            local s = self:_score(self.drives.hunger, dist)
            if s > bestFoodScore then bestFood, bestFoodScore = f, s end
        end
    end

    for _, p in ipairs(partners) do
        if p ~= self and self:_isAvailablePartner(p) then
            local dist = self:distanceTo(p)
            if dist <= self.visionRadius then
                local s = self:_score(self.drives.social, dist)
                if s > bestPartnerScore then bestPartner, bestPartnerScore = p, s end
            end
        end
    end

    if bestFoodScore == 0 and bestPartnerScore == 0 then
        return Creature.STATE_IDLE, nil
    end
    if bestFoodScore >= bestPartnerScore then
        return Creature.STATE_PURSUING, bestFood
    else
        return Creature.STATE_PURSUING, bestPartner
    end
end

function Creature:updateBehavior(dt, allObjects)
    self.lifespan = self.lifespan - dt
    if self.lifespan <= 0 then return false end

    if self.reproductionCooldown > 0 then
        self.reproductionCooldown = self.reproductionCooldown - dt
    end

    if self.socialCooldown > 0 then
        self.socialCooldown = self.socialCooldown - dt
        if self.socialCooldown <= 0 then
            self.socialCooldown = 0
            self.drives.social  = self._baseSocial
        end
    end

    for partner, remaining in pairs(self._separationIgnore) do
        local t = remaining - dt
        if t <= 0 then
            self._separationIgnore[partner] = nil
        else
            self._separationIgnore[partner] = t
        end
    end

    local newState, newTarget = self:decideAction(allObjects)
    self.state                = newState
    self.target               = newTarget
    self.isChasing            = (newState == Creature.STATE_PURSUING)
    self.speedMultiplier      = (self.state == Creature.STATE_FLEEING) and 1.4 or 1.0
    self:move(dt, self.target)

    return true
end

local function clamp(value, minVal, maxVal)
    return math.max(minVal, math.min(maxVal, value))
end

function Creature:inheritStats(parent1, parent2)
    local bounds = self.STAT_BOUNDS or Creature.DEFAULT_STAT_BOUNDS
    local stats  = {
        speed        = (parent1.speed + parent2.speed) / 2,
        visionRadius = (parent1.visionRadius + parent2.visionRadius) / 2,
        lifespan     = (parent1.lifespan + parent2.lifespan) / 2,
        hunger       = (parent1.drives.hunger + parent2.drives.hunger) / 2,
        social       = (parent1.drives.social + parent2.drives.social) / 2,
        fear         = (parent1.drives.fear + parent2.drives.fear) / 2,
    }
    if math.random() < self.MUTATION_CHANCE then
        local keys   = { "speed", "visionRadius", "lifespan", "hunger", "social", "fear" }
        local key    = keys[math.random(#keys)]
        local factor = 1.0 + (math.random() * 2 - 1) * self.MUTATION_STRENGTH
        stats[key]   = stats[key] * factor
        print(string.format("[Mutation] %s: %.2f → %.2f (x%.2f)",
            key, stats[key] / factor, stats[key], factor))
    end
    for key, b in pairs(bounds) do
        if stats[key] then
            stats[key] = clamp(stats[key], b.min, b.max)
        end
    end
    return stats
end

function Creature:newFromParents(parent1, parent2, x, y)
    local instance                = self:new(x, y)
    local stats                   = instance:inheritStats(parent1, parent2)
    instance.speed                = stats.speed
    instance.visionRadius         = stats.visionRadius
    instance.lifespan             = stats.lifespan
    instance.drives.hunger        = stats.hunger
    instance.drives.social        = stats.social
    instance.drives.fear          = stats.fear
    instance._baseSocial          = stats.social
    instance.reproductionCooldown = math.random(
        self.JUVENILE_REPRO_MIN,
        self.JUVENILE_REPRO_MAX
    )
    return instance
end

function Creature:draw(debugMode)
    Entity.draw(self)
    if not debugMode then return end

    local color = ({
        idle     = { 0.5, 0.5, 1 },
        pursuing = { 0, 1, 0 },
        fleeing  = { 1, 0, 0 },
    })[self.state] or { 1, 1, 1 }

    love.graphics.setColor(color[1], color[2], color[3], 0.15)
    love.graphics.circle("fill", self.x, self.y, self.visionRadius)
    love.graphics.setColor(color[1], color[2], color[3], 0.6)
    love.graphics.circle("line", self.x, self.y, self.visionRadius)
    love.graphics.setColor(1, 1, 1)
end

return Creature
