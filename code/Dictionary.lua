local Object = require "libraries/classic"

local Dictionary = Object:extend()


function Dictionary:new(words_filename)
	self.words_lookup = {}
	
	local words_file = love.filesystem.newFile(words_filename)
	for line in words_file:lines() do
		self.words_lookup[line] = true
	end
end

function Dictionary:has_word(word)
	return self.words_lookup[word:lower()] == true
end

function Dictionary:has_words(words)
	local has = true
	for _, word in ipairs(words) do
		has = has and self:has_word(word)
	end
	return has
end

return Dictionary