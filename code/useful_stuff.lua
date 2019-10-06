local letters = require "letter_probability"

function copy_table(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[copy_table(k, s)] = copy_table(v, s) end
	return res
end

function string_to_chars(str)
	local chars = {}
	for m in str:gmatch("..-") do
		table.insert(chars, m)    
	end
	return chars
end

function player_in_box(x, y, w, h)
	return player.x + 12 > x and player.x < x + w and player.y + 15 > y and player.y < y + h
end

function random_letter()
	local r = math.random() * 100
	for k, v in pairs(letters) do
		r = r - v
		if r <= 0 then return k end
	end
	return "e"
end

function in_table(tbl, item)
	for i, v in ipairs(tbl) do
		if v == item then return true end
	end
	return false
end

function distance(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

function point_in_box(x, y, x1, y1, w, h)
	return x > x1 and x < x1 + w and y > y1 and y < y1 + h
end