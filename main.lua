require "code/useful_stuff"
easing = require "libraries/easing"

local bump = require "libraries/bump"

local Dictionary = require "code/Dictionary"
local Map = require "code/Map"
local Inventory = require "code/Inventory"
local Player = require "code/Player"
local EventHandler = require "code/EventHandler"
local TextBox = require "code/TextBox"

function love.load()
	math.randomseed(os.time())

	-- window setup --
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.window.setMode(768, 768, {vsync=1, msaa=0})
	love.graphics.setBackgroundColor(1, 1, 0.9216)
	
	-- bump.lua setup --
	world = bump.newWorld()
	
	-- load stuff --
	font_text = love.graphics.newImageFont("graphics/font_text.png", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,;:!?'\"()[]{} 0123456789>*")
	font_text_end = love.graphics.newImageFont("graphics/font_text_end.png", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,;:!?'\"()[]{} 0123456789>*#")
	font_points = love.graphics.newImageFont("graphics/font_points.png", "p0123456789 ", 1)
	
	cursor = love.mouse.newCursor("cursor.png", 1, 1)
	cursor_hand = love.mouse.newCursor("cursor_hand.png", 3, 1)
	
	-- load sounds --
	sounds = {}
	sounds.error = love.audio.newSource("sounds/error.wav", "static")
	sounds.open_edit = love.audio.newSource("sounds/open_edit_menu.wav", "static")
	sounds.close_edit = love.audio.newSource("sounds/close_edit_menu.wav", "static")
	sounds.points = love.audio.newSource("sounds/points.wav", "static")
	sounds.coin = love.audio.newSource("sounds/coin.wav", "static")
	sounds.land = love.audio.newSource("sounds/land.wav", "static")
	sounds.text = love.audio.newSource("sounds/text_blip.wav", "static")
	
	-- music
	music = {}
	music.ending = love.audio.newSource("music/ending.wav", "stream")
	music.default = love.audio.newSource("music/default.wav", "stream")
	music.edit = love.audio.newSource("music/edit.wav", "stream")
	music.magic = love.audio.newSource("music/magic.wav", "stream")
	
	end_reached = 0
	show_end_screen = false
	end_screen = love.graphics.newImage("graphics/end_screen.png")
	end_timer = 0
	end_letters = {}
	restart_timer = 0
	
	show_start_screen = true
	start_game = false
	start_timer = 0
	start_player_timer = 0
	start_player_x = 256
	start_screen = love.graphics.newImage("graphics/start_screen.png")
	
	-- instantiate classes --
	map = Map(160, 32)
	dict = Dictionary("words.txt")
	inventory = Inventory()
	player = Player(0, 0)
	events = EventHandler()
	text = TextBox()
	
	-- test stuff
	map:load_from_file("level.txt")
	player:set_position(map.player_spawn_x, map.player_spawn_y)
	events:load_from_file("level_events.lua")
end

function love.update(dt)
	local next_cursor = cursor
	if not show_end_screen and not show_start_screen then
		love.mouse.setVisible(map.editing)
		restart_timer = math.min(restart_timer + dt, 1)
		if end_reached == 0 then
			music.ending:stop()
		end
		if not map.editing and not text.shown then
			player:update(dt)
			events:update(dt)
		end
		map:update(dt)
		text:update(dt)
		-- play all except end music
		music.default:play()
		music.edit:play()
		music.magic:play()
		-- calculate music volume
		local m_dist = distance(player.x,player.y, 384, 224)
		local m = -math.min(m_dist - 160, 0) / 160
		music.default:setVolume((1 - map.edit_timer) * (1-m) * (1-player.death_timer) * (1-end_reached) * restart_timer)
		music.magic:setVolume((1 - map.edit_timer) * m * (1-player.death_timer) * (1-end_reached) * restart_timer)
		music.edit:setVolume(map.edit_timer * (1-m) * (1-player.death_timer) * (1-end_reached) * restart_timer)
		music.ending:setVolume(1 - restart_timer + end_reached)
	elseif show_end_screen then	
		love.mouse.setVisible(true)
		-- set ending music volume
		music.ending:setVolume(1)
		-- increment end timer
		end_timer = math.min(end_timer + dt, 2)
		-- add flying end letters
		if end_timer == 2 and math.random() <= dt then
			local y = {math.random(0, 90), math.random(155, 240)}
			y = y[math.random(1, 2)]
			local l = "#"
			if math.random() > 0.25 then l = random_letter() end
			table.insert(end_letters, {
				y = y,
				x = 256,
				l = l,
				t = 0,
				speed = math.random(32, 128)
			})
		end
		-- animate flying letters
		for i, l in ipairs(end_letters) do
			l.x = l.x - l.speed * dt
			l.t = l.t + dt
			if l.x < -16 then
				table.remove(end_letters, i)
			end
		end
	else
		-- start screen
		love.mouse.setVisible(true)
		if start_game then
			start_timer = math.min(start_timer + dt, 1)
		end
		if start_timer == 1 then
			show_start_screen = false
		end
		start_player_timer = start_player_timer + dt * 12
		start_player_x = start_player_x - dt * 64
		if start_player_x < -16 then start_player_x = 256 end
		local mx, my = love.mouse.getPosition()
		mx, my = mx/3, my/3
		if point_in_box(mx, my, 41, 2, 35, 7) or point_in_box(mx, my, 96, 2, 69, 7) then
			next_cursor = cursor_hand
		end
	end
	love.mouse.setCursor(next_cursor)
end

function love.draw()
	love.graphics.scale(3, 3)
	love.graphics.translate(-math.floor(map.scroll_x), -math.floor(map.scroll_y))
	map:draw()
	player:draw()
	love.graphics.translate(math.floor(map.scroll_x), math.floor(map.scroll_y))
	map:draw_foreground()
	player:draw_points_display()
	text:draw()
	love.graphics.origin()
	if show_start_screen then
		local p = easing.inBack(start_timer/1, 0, 1, 1)
		-- draw start screen
		love.graphics.scale(3, 3)
		love.graphics.draw(start_screen, 0, -256 * p)
		local sprites = {player.sprites.default, player.sprites.walk_1, player.sprites.walk_2, player.sprites.walk_1}
		local sprite = sprites[math.floor(start_player_timer)%(#sprites) + 1]
		local y = math.max(-math.sin(start_player_x/22 + math.pi)*32, 0)
		local der = -(16/11)*math.cos(start_player_x/22) * y
		if der > 6 then
			sprite = player.sprites.jump
		elseif der < -6 then
			sprite = player.sprites.fall
		end
		love.graphics.draw(sprite, start_player_x + 16, 160 - y - 256 * p, 0, -1, 1)
		love.graphics.origin()
	elseif show_end_screen then
		-- draw end screen
		local p = easing.outBounce(end_timer/2, 0, 1, 1)
		love.graphics.scale(3, 3)
		love.graphics.setColor(1,1,1)
		love.graphics.draw(end_screen, 0, -256 + 256 * p)
		-- print score/coins
		love.graphics.setFont(font_text_end)
		love.graphics.print("Your Score: " .. player.points, 2, 256 * p - 10)
		local stars = ""
		for i = 1, player.coins, 1 do stars = stars .. "*" end
		love.graphics.printf(stars, 0, 256 * p - 10, 254, "right")
		-- draw flying letters
		for i, l in ipairs(end_letters) do
			love.graphics.print(l.l, math.floor(l.x), math.floor(l.y + math.sin(l.t) * 8))
		end
		love.graphics.origin()
	end
end

function love.keypressed(k)
	if k == "return" and not text.shown and not show_end_screen and not show_start_screen then
		map:toggle_edit_mode()
	end
	if (k == "s" or k == "down") and map.editing and not show_end_screen and not show_start_screen then
		inventory:scroll(1)
	end
	if (k == "w" or k == "up") and map.editing and not show_end_screen and not show_start_screen then
		inventory:scroll(-1)
	end
	if not map.editing and not text.shown and (k == "w" or k == "up" or k == "space") and not show_end_screen and not show_start_screen then
		player:jump()
	end
	if not map.editing and not text.shown and k == "r" and not show_end_screen and not show_start_screen then
		player:reset()
	end
	if k == "return" and show_start_screen then
		start_game = true
		start_timer = 0
	end
	if k == "r" and show_end_screen then
		show_end_screen = false
		player:reset()
	end
end

function love.mousepressed(x, y, b)
	if b == 1 and map.editing then
		local tx, ty = map:get_tile_at_position(x/3, y/3)
		map:edit_tile(tx, ty)
	end
	if b == 1 and show_start_screen then
		local tx, ty = x/3, y/3
		if point_in_box(tx, ty, 41, 2, 35, 7) then
			love.system.openURL("http://ovidios.de")
		end
		if point_in_box(tx, ty, 96, 2, 69, 7) then
			love.system.openURL("https://ldjam.com/users/ovidios/")
		end
	end
end

function love.wheelmoved(x, y)
	if map.editing and not show_end_screen and not show_start_screen then
		inventory:scroll(-y)
	end
end