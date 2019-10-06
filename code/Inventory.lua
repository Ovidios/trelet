local Object = require "libraries/classic"

local Inventory = Object:extend()

function Inventory:new()
	self.alphabet = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
	self.letters = {
		a = 0,
		b = 0,
		c = 0,
		d = 0,
		e = 0,
		f = 0,
		g = 0,
		h = 0,
		i = 0,
		j = 0,
		k = 0,
		l = 0,
		m = 0,
		n = 0,
		o = 0,
		p = 0,
		q = 0,
		r = 0,
		s = 0,
		t = 0,
		u = 0,
		v = 0,
		w = 0,
		x = 0,
		y = 0,
		z = 0
	}
	self.selected_letter = 1
end

function Inventory:reset()
	self.letters = {}
	for _, l in ipairs(self.alphabet) do
		self.letters[l] = 0
	end
end

function Inventory:has_letter(l)
	return self.letters[l] > 0
end

function Inventory:has_selected_letter()
	local l = self:get_selected_letter()
	return self:has_letter(l)
end

function Inventory:get_selected_letter()
	return self.alphabet[self.selected_letter]
end

function Inventory:add_letter(l, amount)
	self.letters[l] = self.letters[l] + amount
end

function Inventory:remove_letter(l, amount)
	self.letters[l] = self.letters[l] - amount
end

function Inventory:scroll(n)
	self.selected_letter = self.selected_letter + n
	while self.selected_letter > #self.alphabet do self.selected_letter = self.selected_letter - #self.alphabet end
	while self.selected_letter <= 0 do self.selected_letter = #self.alphabet - self.selected_letter end
end

function Inventory:draw_item_selector()
	love.graphics.setFont(font_text)
	for i, l in ipairs(self.alphabet) do
		local p = math.min(-i/#self.alphabet + map.edit_timer*2, 1)
		local y = 3 + (i-1)*9
		local num = self.letters[self.alphabet[i]]
		local str = ""
		if i == self.selected_letter then
			str = num .. " >  "
		end
		str = str .. l
		
		if num > 0 then
			love.graphics.setColor(1,1,1)
		else
			love.graphics.setColor(1,1,1,0.5)
		end
		
		love.graphics.printf(str:upper(), 48 * (1-p), y, 253, "right")
	end
	love.graphics.setColor(1,1,1)
end

function Inventory:give_balanced_letters(n)
	local given = ""
	for _=1,n,1 do
		local l = random_letter()
		given = given .. l
		self:add_letter(l, 1)
	end
	return given
end

return Inventory