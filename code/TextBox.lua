local Object = require "libraries/classic"

local TextBox = Object:extend()

function TextBox:new()
	self.text = ""
	self.queue = {}
	self.timer = 0
	self.release_delay = 0
	self.speed = 1
	self.shown = false
	self.execute_after = function() end
	self.last_cutoff = 0
	self.blink_timer = 0
end

function TextBox:update(dt)
	if self.shown then
		self.blink_timer = self.blink_timer + dt
		self.timer = math.min(self.timer + self.speed * dt, 1)
		
		local cutoff = math.ceil(#self.text * self.timer)
		if cutoff > self.last_cutoff then
			sounds.text:stop()
			sounds.text:play()
		end
		self.last_cutoff = cutoff
		
		if self.timer == 1 then self.release_delay = self.release_delay + dt end
	end
	
	if self.release_delay >= 0.25 and (love.keyboard.isDown("space") or love.keyboard.isDown("return")) then
		self.execute_after()
		if #self.queue > 0 then
			self.shown = false
			self:show_text(unpack(self.queue[1]))
			table.remove(self.queue, 1)
		else
			self.shown = false
		end
		
	end
end

function TextBox:draw()
	if self.shown then
		love.graphics.setFont(font_text)
		love.graphics.setColor(1,1,1)
		local cutoff = math.ceil(#self.text * self.timer)
		local extra = ""
		if math.floor(self.blink_timer)%2 == 0 and self.timer == 1 then extra = ">" end
		love.graphics.printf({
			{1,1,1,1}, self.text:sub(1, cutoff),
			{1,1,1,0}, self.text:sub(cutoff),
			{1,1,1,1}, extra,
		}, 8, 16, 240, "left")
	end
end

function TextBox:show_text(text, execute_after)
	local execute_after = execute_after or function() end
	if not self.shown then
		self.text = text
		self.timer = 0
		self.release_delay = 0
		self.shown = true
		self.speed = 1/2
		self.execute_after = execute_after
	else
		table.insert(self.queue, {text, execute_after})
	end
end

return TextBox