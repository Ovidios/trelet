local Spritesheet = require "code/Spritesheet"
local Object = require "libraries/classic"

local Map = Object:extend()

function Map:new(width, height)
	self.width = width
	self.height = height
	self.tiles = {}
	self.objects = {}
	
	self.used_words = {}
	
	self.player_spawn_x = 0
	self.player_spawn_y = 0
	
	self.scroll_x = 0
	self.scroll_y = 0
	
	self.goal_scroll_x = 0
	self.goal_scroll_y = 0
	
	self.editing = false
	self.close_editing = false
	
	self.tile_spritesheet = Spritesheet("graphics/block.png", 16, 16, 4, 4)
	self.tile_font = love.graphics.newImageFont("graphics/letters.png", "abcdefghijklmnopqrstuvwxyz")
	self.edit_font = love.graphics.newImageFont("graphics/font_tiny.png", "abcdefghijklmnopqrstuvwxyz0123456789> ", 1)
	self.edit_border = love.graphics.newImage("graphics/edit_border.png")
	self.edit_cursor = love.graphics.newImage("graphics/cursor.png")
	self.edit_background = love.graphics.newImage("graphics/edit_background.png")
	
	self.spikes_sprite = love.graphics.newImage("graphics/spikes.png")
	self.flag_sprite = love.graphics.newImage("graphics/flag.png")
	self.coin_sprites = {
		love.graphics.newImage("graphics/coin.png"),
		love.graphics.newImage("graphics/coin_1.png"),
		love.graphics.newImage("graphics/coin_2.png"),
		love.graphics.newImage("graphics/coin_3.png"),
		love.graphics.newImage("graphics/coin_1.png"),

	}
	self.coin_spin = 0
	self.wizard_sprite = love.graphics.newImage("graphics/wizard.png")
	
	self.chest_sprite = love.graphics.newImage("graphics/chest.png")
	self.chest_open_sprite = love.graphics.newImage("graphics/chest_open.png")
	
	self.arrow_spritesheet = Spritesheet("graphics/arrows.png", 16, 16, 3, 3)
	
	self.blink_timer = 0
	
	self.edit_timer = 0
end

function Map:load_from_file(filename)
	local tbl = {}
	local map_file = love.filesystem.newFile(filename)
	for line in map_file:lines() do
		local chars = string_to_chars(line:gsub("%.", " "))
		table.insert(tbl, chars)
	end
	self:set_tiles(tbl)
end

function Map:add_words_to_used()
	local words = self:get_all_words()
	for _, w in ipairs(words) do
		self.used_words[w] = true
	end
end

function Map:remove_bump_objects()
	for y, row in ipairs(self.tiles) do
		for x, tile in ipairs(row) do
			world:remove(tile)
		end
	end
end

function Map:reset_used_words()
	self.used_words = {}
end

function Map:set_tiles(tbl)
	self.tiles = {}
	for y, row in ipairs(tbl) do
		self.tiles[y] = {}
		for x, tile in ipairs(row) do
			local tile_type = "block"
			local tile_immovable = true
			if tile == " " or tile == "." then
				tile_type = "air"
				tile_immovable = false
			end
			if tile == "*" then
				tile_type = "spikes"
			end
			if tile == "<" or tile == ">" or tile == "^" or tile == "V" or tile == "`" or tile == "," then
				tile_type = "arrow"
			end
			if tile == "C" then
				tile_type = "chest"
			end
			if tile == "F" then
				tile_type = "flag"
			end
			if tile == "O" then
				tile_type = "coin"
			end
			if tile == "W" then
				tile_type = "wizard"
			end
			if tile == "P" then
				self.player_spawn_x, self.player_spawn_y = self:get_tile_coords(x, y)
				tile_type = "air"
				tile_immovable = false
				tile = " "
			end
			table.insert(self.tiles[y], {
				type = tile_type,
				letter = tile,
				immovable = tile_immovable
			})
			local px, py = self:get_tile_coords(x, y)
			world:add(self.tiles[y][x], px, py, 16, 16)
		end
	end
	self:add_words_to_used()
end

function Map:toggle_edit_mode()
	if self.editing then
		-- test if all words are legal
		local words = self:get_all_words()
		if dict:has_words(words) then
			if self:check_for_connections() then
				-- award points & bonuses for long words
				for _, word in ipairs(words) do
					if self.used_words[word] == nil then
						self.used_words[word] = true
						local pts = ((#word)^2 - #word)/2
						player:give_points(pts)
						if #word >= 5 then
							local prize_n = (#word - 4)*2
							local letters = inventory:give_balanced_letters(prize_n)
							text:show_text("Great Word!\n\n You were awarded " .. prize_n .. " letters!\n(" .. letters:upper() .. ")")
						end
					end
				end
				sounds.close_edit:stop()
				sounds.close_edit:play()
				self.close_editing = true
				self:make_all_blocks_immovable()
			else
				print("ERROR: Blocks need to be connected!")
				sounds.error:stop()
				sounds.error:play()
			end
		else
			print("ERROR: Illegal word placement!")
			sounds.error:stop()
			sounds.error:play()
		end
	else
		self.editing = true
		self.edit_timer = 0
		sounds.open_edit:stop()
		sounds.open_edit:play()
	end
end

function Map:get_tile_at_position(sx, sy)
	tx = math.ceil(sx/16 + self.scroll_x/16)
	ty = math.ceil(sy/16 + self.scroll_y/16)
	return tx, ty
end

function Map:get_tile_coords(tx, ty)
	return (tx - 1) * 16, (ty - 1) * 16
end

function Map:draw_tile_sprite(tx, ty, x, y, tbl)
	local a, b, c, d = 0, 0, 0, 0
	
	if ty > 1 			and tbl[ty - 1][tx].type == "block" then a = 1 end
	if tx < self.width	and tbl[ty][tx + 1].type == "block" then b = 1 end
	if ty < self.height and tbl[ty + 1][tx].type == "block" then c = 1 end
	if tx > 1			and tbl[ty][tx - 1].type == "block" then d = 1 end
	
	local quad = self.tile_spritesheet:get_quad_4b(a, b, c, d)
	
	love.graphics.draw(self.tile_spritesheet.image, quad, x, y)
end

function Map:draw()
	local tbl = self.tiles
	for y, row in ipairs(tbl) do
		for x, tile in ipairs(row) do
			if self.editing then
				local px, py = self:get_tile_coords(x, y)
				if self.edit_timer >= (px-self.scroll_x)/512 + (py-self.scroll_y)/512 then
					love.graphics.draw(self.edit_background, px, py)
				end
			end
			if tile.type == "block" then
				local px, py = self:get_tile_coords(x, y)
				love.graphics.setColor(1,1,1)
				if not tile.immovable then
					love.graphics.setColor(1,1,1,0.5)
				end
				self:draw_tile_sprite(x, y, px, py, tbl)
				love.graphics.setFont(self.tile_font)
				love.graphics.print(tile.letter, px + 1, py)
			elseif tile.type == "spikes" then
				local px, py = self:get_tile_coords(x, y)
				love.graphics.setColor(1,1,1)
				love.graphics.draw(self.spikes_sprite, px, py)
			elseif tile.type == "arrow" then
				arrow_map = {
					["<"] = {1, 2},
					["`"] = {1, 1},
					["^"] = {2, 1},
					[">"] = {3, 2},
					[","] = {3, 3},
					["V"] = {2, 3}
				}
				local px, py = self:get_tile_coords(x, y)
				local qx, qy = unpack(arrow_map[tile.letter])
				self.arrow_spritesheet:draw(qx, qy, px, py)
			elseif tile.type == "chest" then
				local px, py = self:get_tile_coords(x, y)
				love.graphics.setColor(1,1,1)
				love.graphics.draw(self.chest_sprite, px, py)
			elseif tile.type == "chest_open" then
				local px, py = self:get_tile_coords(x, y)
				love.graphics.setColor(1,1,1)
				love.graphics.draw(self.chest_open_sprite, px, py)
			elseif tile.type == "flag" then
				local px, py = self:get_tile_coords(x, y)
				love.graphics.setColor(1,1,1)
				love.graphics.draw(self.flag_sprite, px, py)
			elseif tile.type == "coin" then
				local px, py = self:get_tile_coords(x, y)
				local s_n = (math.floor(self.coin_spin*7))%(#self.coin_sprites) + 1
				local sprite = self.coin_sprites[s_n]
				love.graphics.setColor(1,1,1)
				love.graphics.draw(sprite, px, py)
			elseif tile.type == "wizard" then
				local px, py = self:get_tile_coords(x, y)
				love.graphics.setColor(1,1,1)
				love.graphics.draw(self.wizard_sprite, px, py)
			end
		end
	end
	if self.editing then
		local mx, my = love.mouse.getPosition()
		mx, my = mx/3, my/3

		-- draw edit cursor --
		if self.edit_timer > 0.75 then
			local tx, ty = self:get_tile_at_position(mx, my)
			local px, py = self:get_tile_coords(tx, ty)
			love.graphics.draw(self.edit_cursor, px, py)
		end
	end
	love.graphics.setColor(1,1,1)
end

function Map:draw_foreground()
	if self.editing then
		-- draw border --
		if math.floor(self.blink_timer*2)%2 == 0 or self.edit_timer < 1 then
			love.graphics.setColor(1,1,1)
			love.graphics.draw(self.edit_border, -42 * (1-self.edit_timer)^2)
		end
		
		-- draw item selector --
		inventory:draw_item_selector()
	end
	love.graphics.setColor(1,1,1)
end

function Map:update(dt)
	self.blink_timer = self.blink_timer + dt
	self.coin_spin = self.coin_spin + dt
	if self.close_editing then
		self.edit_timer = math.max(self.edit_timer - dt, 0)
	elseif self.editing then
		self.edit_timer = math.min(self.edit_timer + dt, 1)
	end
	
	if self.close_editing and self.edit_timer == 0 then
		self.editing = false
		self.close_editing = false
	end
	
	self.scroll_x = math.max(self.scroll_x, 0)
	self.scroll_y = math.max(self.scroll_y, 0)
	self.scroll_x = math.min(self.scroll_x, #self.tiles[1] * 16 - 256)
	self.scroll_y = math.min(self.scroll_y, #self.tiles * 16 - 256)
	
	-- follow player
	if player.is_on_ground or player.y - self.scroll_y < 64 or player.y - self.scroll_y > 192 then
		self.goal_scroll_y = player.y - 128 + 8
	end
	self.goal_scroll_x = player.x - 128 + 6
	self.scroll_x = player.x - 128 + 6
	self.scroll_y = (self.goal_scroll_y*dt*4 + self.scroll_y)/(1+dt*4)

end

function Map:edit_tile(tx, ty)
	if ty > 0 and ty <= #self.tiles and tx > 0 and tx <= #self.tiles[1] then
		local tile = self.tiles[ty][tx]
		if tile.immovable then
			print("ERROR: Tile immovable!")
			sounds.error:stop()
			sounds.error:play()
		else
			if tile.type == "air" then
				local px, py = self:get_tile_coords(tx, ty)
				local _, len = world:queryRect(px, py, 16, 16, function(item) return item.is_player end)
				if len == 0 then
					if inventory:has_selected_letter() then
						tile.type = "block"
						tile.letter = inventory:get_selected_letter()
						inventory:remove_letter(tile.letter, 1)
					else
						print("ERROR: Letter unavailable!")
						sounds.error:stop()
						sounds.error:play()
					end
				else
					print("ERROR: Position illegal!")
					sounds.error:stop()
					sounds.error:play()
				end
			elseif tile.type == "block" then
				inventory:add_letter(tile.letter, 1)
				tile.type = "air"
				tile.letter = " "
			end
		end
	end
end

function Map:get_row_string(y, tbl)
	local tbl = tbl or self.tiles
	local str = ""
	for _, tile in ipairs(tbl[y]) do
		if tile.type == "block" then
			str = str .. tile.letter
		else
			str = str .. " "
		end
	end
	return str
end

function Map:get_col_string(x, tbl)
	local tbl = tbl or self.tiles
	local str = ""
	for _, row in ipairs(tbl) do
		local tile = row[x]
		if tile.type == "block" then
			str = str .. tile.letter
		else
			str = str .. " "
		end
	end
	return str
end

function Map:extract_words(str)
	local words = {}
	for word in str:gmatch("%S%S+") do
		table.insert(words, word)
	end
	return words
end

function Map:get_all_words(tbl)
	local tbl = tbl or self.tiles
	local big_str = ""
	-- read all rows
	for y = 1, #self.tiles, 1 do
		big_str = big_str .. " " .. self:get_row_string(y, tbl)
	end
	-- read all columns
	for x = 1, #self.tiles[1], 1 do
		big_str = big_str .. " " .. self:get_col_string(x, tbl)
	end
	
	local words = self:extract_words(big_str)
	
	return words
end

function Map:make_all_blocks_immovable()
	for y, row in ipairs(self.tiles) do
		for x, tile in ipairs(row) do
			if tile.type == "block" then
				tile.immovable = true
			end
		end
	end
end

function Map:has_solid_connection(tx, ty)
	local neighbor_coords = {
		{-1,  0},
		{ 1,  0},
		{ 0, -1},
		{ 0,  1}
	}
	local found_solid = false
	local connected = {}
	local function add_to_connected(t_x, t_y)
		if not found_solid then
			connected["_" .. t_x .. "_" .. t_y] = self.tiles[ty][tx]
			for _, t in ipairs(neighbor_coords) do
				if t_y + t[2] > 0 and t_y + t[2] <= #self.tiles then
					if t_x + t[1] > 0 and t_x + t[1] <= #self.tiles[1] then
						if self.tiles[t_y + t[2]][t_x + t[1]].type == "block" then
							if self.tiles[t_y + t[2]][t_x + t[1]].immovable then
								found_solid = true
							end
							if connected["_" .. t_x + t[1] .. "_" .. t_y + t[2]] == nil then
								add_to_connected(t_x + t[1], t_y + t[2])
							end
						end
					end
				end
			end
		end
	end
	add_to_connected(tx, ty)
	return found_solid
end

function Map:check_for_connections()
	local legal = true
	for y, row in ipairs(self.tiles) do
		for x, tile in ipairs(row) do
			if tile.type == "block" and not tile.immovable then
				legal = legal and self:has_solid_connection(x, y)
			end
		end
	end
	return legal
end

return Map