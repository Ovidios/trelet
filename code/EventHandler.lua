local Object = require "libraries/classic"

local EventHandler = Object:extend()

function EventHandler:new()
	self.events = {}
end

function EventHandler:new_event(id, trigger, on_trigger, update)
	self.events[id] = {
		id = id,
		trigger = trigger or function(self) return true end,
		on_trigger = on_trigger or function(self) end,
		update = update or function(self, dt) end
	}
end

function EventHandler:reset()
	self.events = {}
end

function EventHandler:load_from_file(filename)
	local event_list = love.filesystem.load(filename)()
	for _, e in ipairs(event_list) do
		self:new_event(unpack(e))
	end
end

function EventHandler:update(dt)
	for id, e in pairs(self.events) do
		e:update(dt)
		
		if e:trigger() then
			e:on_trigger()
		end
	end
end

function EventHandler:remove_event(id)
	self.events[id] = nil
end

return EventHandler