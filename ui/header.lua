local Header = {}
Header.__index = Header

local hexToRGB = require("utils.hexToRGB")

local defaultFontPath = "assets/fonts/FreePixel.ttf"
local defaultFont = love.graphics.newFont(defaultFontPath, 24)

local fontSizes = {
    h1 = 62,
    h2 = 52,
    h3 = 42,
    h4 = 32,
    h5 = 24,
    h6 = 18
}

function Header:new(text, x, y, type)
    local self = setmetatable({}, Header)
    self.text = text
    self.x = x
    self.y = y
    self.fontSize = fontSizes[type]
    self.color = { hexToRGB.convert("#fffcfb") }
    self.font = love.graphics.newFont(defaultFontPath, self.fontSize)
    return self
end

function Header:draw()
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.color)
    love.graphics.printf(self.text, self.x, self.y, love.graphics.getWidth(), "center")
    love.graphics.setFont(defaultFont)
end

return Header
