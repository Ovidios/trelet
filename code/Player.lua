local Object = require "libraries/classic"

local Player = Object:extend()

function Player:new(x, y)
	self.is_player = true
	self.dead = false
	self.death_timer = 0
	self.death_message_shown = false
	self.coins = 0
	self.points = 0
	self.last_display_points = 0
	self.display_points = 0
	self.x = x
	self.y = y
	self.vel_x = 0
	self.vel_y = 0
	self.max_vel_x = 64
	self.max_vel_y = 256
	self.mirrored = false
	self.is_on_ground = false
	self.bump_move_filter = function(item, other)
		if other.type == "block" or other.type == "spikes" then
			return "slide"
		end
		if other.type == "coin" then
			return "cross"
		end
	end
	self.sprites = {
		default = love.graphics.newImage("graphics/player/default.png"),
		fall = love.graphics.newImage("graphics/player/fall.png"),
		jump = love.graphics.newImage("graphics/player/jump.png"),
		walk_1 = love.graphics.newImage("graphics/player/walk_1.png"),
		walk_2 = love.graphics.newImage("graphics/player/walk_2.png"),
		sleep = love.graphics.newImage("graphics/player/sleep.png"),
	}
	self.death_animation = {
		love.graphics.newImage("graphics/death_screen/1.png"),
		love.graphics.newImage("graphics/death_screen/2.png"),
		love.graphics.newImage("graphics/death_screen/3.png"),
		love.graphics.newImage("graphics/death_screen/4.png"),
		love.graphics.newImage("graphics/death_screen/5.png"),
		love.graphics.newImage("graphics/death_screen/6.png"),
		love.graphics.newImage("graphics/death_screen/7.png"),
		love.graphics.newImage("graphics/death_screen/8.png")
	}
	self.star_icon = love.graphics.newImage("graphics/star_symbol.png")
	
	self.current_sprite = "default"
	
	self.animation_timer = 0
	
	world:add(self, self.x, self.y, 12, 15)
end

function Player:update(dt)
	if self.dead then
		self.death_timer = math.min(self.death_timer + dt, 1)
		if self.death_timer == 1 and not self.death_message_shown then
			self.death_message_shown = true
			text:show_text("G A M E   O V E R .\n\n(press [enter] to try again)")
		end
	end
	self.animation_timer = self.animation_timer + dt
	self.is_on_ground = false

	-- apply gravity
	local gravity_mult = 1
	if love.keyboard.isDown("space") or love.keyboard.isDown("up") or love.keyboard.isDown("w") then
		gravity_mult = 0.45
	end
	self.vel_y = self.vel_y + 512 * dt * gravity_mult
	
	-- apply controls
	if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
		self.vel_x = self.vel_x + 512 * dt
	elseif self.vel_x > 0 then
		self.vel_x = math.max(self.vel_x - 512 * dt, 0)
	end
	if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
		self.vel_x = self.vel_x - 512 * dt
	elseif self.vel_x < 0 then
		self.vel_x = math.min(self.vel_x + 512 * dt, 0)
	end
	
	-- update sprites
	self.current_sprite = "default"
	if self.vel_x < 0 then self.mirrored = true end
	if self.vel_x > 0 then self.mirrored = false end
	if self.vel_x > 16 or self.vel_x < -16 then
		if self.current_sprite == "fall" or self.current_sprite == "jump" then
			self.animation_timer = 0
		end
		-- do the walk!
		local frames = {"default", "walk_1", "walk_2", "walk_1"}
		local f = math.floor(self.animation_timer*12)%#frames + 1
		self.current_sprite = frames[f]
	end
	if self.vel_y > 16 then self.current_sprite = "fall" end
	if self.vel_y < -16 then self.current_sprite = "jump" end
	
	-- keep within max velocity
	self.vel_x = math.max(math.min(self.vel_x, self.max_vel_x), -self.max_vel_x)
	self.vel_y = math.max(math.min(self.vel_y, self.max_vel_y), -self.max_vel_y)
	
	-- move
	if not self.dead then
		local gx, gy = self.x + self.vel_x * dt, self.y + self.vel_y * dt
		local ax, ay, cols = world:move(self, gx, gy, self.bump_move_filter)
		self.x, self.y = ax, ay
		
		for i, c in ipairs(cols) do
			if c.other.type == "spikes" then
				self.dead = true
				self.points = 0
			end
			if c.other.type == "coin" then
				c.other.type = "air"
				c.other.letter = " "
				c.other.immovable = false
				sounds.coin:stop()
				sounds.coin:play()
				self.points = self.points + 100
				self.coins = self.coins + 1
			end
		end
		
		-- reset y-velocity
		if ay < gy then
			self.is_on_ground = true
			if self.vel_y > 16 then sounds.land:stop() sounds.land:play() end
		end
		if ay ~= gy then self.vel_y = 0 end
	end
	
	-- update display points
	self.display_points = (self.display_points + self.points * dt)/(1+dt)
	if math.floor(self.display_points) > math.floor(self.last_display_points) then
		sounds.points:stop()
		sounds.points:play()
	end
	self.last_display_points = self.display_points
end

function Player:jump()
	if player.is_on_ground then
		self.vel_y = -128
	end
end

function Player:reset()
	end_reached = 0
	end_timer = 0
	restart_timer = 0
	self.dead = false
	self.death_timer = 0
	self.death_message_shown = false
	self.points = 0
	self.coins = 0
	map:reset_used_words()
	map:remove_bump_objects()
	map:load_from_file("level.txt")
	self:set_position(map.player_spawn_x, map.player_spawn_y)
	events:reset()
	events:load_from_file("level_events.lua")
	inventory:reset()
	
	music.default:seek(0)
	music.edit:seek(0)
	music.magic:seek(0)
end

function Player:give_points(pts)
	self.points = self.points + pts
end

function Player:set_position(x, y)
	world:update(self, x, y, 12, 15)
	self.x = x
	self.y = y
end

function Player:draw()
	love.graphics.setColor(1,1,1)
	if self.mirrored then
		love.graphics.draw(self.sprites[self.current_sprite], math.floor(self.x) + 14, math.floor(self.y), 0, -1, 1)
	else
		love.graphics.draw(self.sprites[self.current_sprite], math.floor(self.x) - 2, math.floor(self.y))
	end
end

function Player:draw_points_display()
	-- points
	love.graphics.setColor(1,1,1)
	love.graphics.setFont(font_points)
	love.graphics.print("p " .. math.floor(self.display_points), 4, 245)
	
	-- star coins
	for i = 1, self.coins, 1 do
		local x = 256 - i * 16
		love.graphics.draw(self.star_icon, x, 240)
	end
	
	-- death animation
	if self.dead then
		local f = math.max(math.ceil(self.death_timer*#self.death_animation), 1)
		love.graphics.draw(self.death_animation[f])
	end
end

return Player