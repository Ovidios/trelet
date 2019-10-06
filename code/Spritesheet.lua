local Object = require "libraries/classic"

local Spritesheet = Object:extend()

function Spritesheet:new(filename, s_w, s_h, n_x, n_y)
	self.image = love.graphics.newImage(filename)
	self.quads = {}
	
	-- generate quads for image
	local im_width, im_height = self.image:getDimensions()
	for y = 1, n_y, 1 do
		self.quads[y] = {}
		for x = 1, n_x, 1 do
			table.insert(
				self.quads[y],
				love.graphics.newQuad((x-1)*s_w, (y-1)*s_h, s_w, s_h, im_width, im_height)
			)
		end
	end
end

function Spritesheet:get_quad(x, y)
	return self.quads[y][x]
end

function Spritesheet:get_quad_4b(a, b, c, d)
	local lookup = {
		["t1111"] = {1, 1},
		["t0111"] = {2, 1},
		["t1011"] = {3, 1},
		["t0011"] = {4, 1},
		["t1101"] = {1, 2},
		["t0101"] = {2, 2},
		["t1001"] = {3, 2},
		["t0001"] = {4, 2},
		["t1110"] = {1, 3},
		["t0110"] = {2, 3},
		["t1010"] = {3, 3},
		["t0010"] = {4, 3},
		["t1100"] = {1, 4},
		["t0100"] = {2, 4},
		["t1000"] = {3, 4},
		["t0000"] = {4, 4}
	}
	local str = "t" .. a .. b .. c .. d
	local qx, qy = unpack(lookup[str])
	return self:get_quad(qx, qy)
end

function Spritesheet:draw(qx, qy, x, y)
	local quad = self:get_quad(qx, qy)
	
	love.graphics.draw(self.image, quad, x, y)
end

return Spritesheet