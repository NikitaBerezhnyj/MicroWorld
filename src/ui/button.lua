local Button = {}
Button.__index = Button

local hexToRGB = require("utils.hexToRGB")

function Button:new(text, x, y, width, height, action)
    local self = setmetatable({}, Button)
    self.text = text
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.action = action
    self.defaultColor = { hexToRGB.convert("#6db1bf") }
    self.hoverColor = { hexToRGB.convert("#52a1b2") }
    self.textColor = { hexToRGB.convert("#fffcfb") }
    return self
end

function Button:isMouseOver(mx, my)
    return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
end

function Button:draw()
    local mx, my = love.mouse.getPosition()

    if self:isMouseOver(mx, my) then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.defaultColor)
    end

    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)

    love.graphics.setColor(self.textColor)
    love.graphics.printf(self.text, self.x, self.y + self.height / 4, self.width, "center")
end

function Button:mousePressed(mx, my)
    if self:isMouseOver(mx, my) then
        self.action()
    end
end

return Button
