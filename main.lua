-- WorldCrawlWars Copyright 2011 Iwan 'qubodup' Gabovitch <qubodup@gmail.com>
-- Licensed under um... GPL! Ha, take that!
-- Some game about words, crawl and war I guess

-- blocks class
Blocks = {}
Blocks.__index = Blocks

function Blocks.create()
	local blcks = {}
	setmetatable(blcks,Blocks)
	-- the actual blocks.. in the block cells.. in the block lines.. it's a table of x tables of y booleans
	blcks.blocks = {}
	-- top position (top is first line)
	blcks.linepos = 0
	return blcks
end

function Blocks:move()
	self.linepos = self.linepos - 1
end

function Blocks:makestep(direction)
	if direction == "left" then
		-- I don't understand why I have to add one
		table.insert(self.blocks[1],#self.blocks[1]+1,self.blocks[1][1])
		table.remove(self.blocks[1],1)
	elseif direction == "right" then
		table.insert(self.blocks[1],1,self.blocks[1][#self.blocks[1]])
		table.remove(self.blocks[1],#self.blocks[1])
	elseif direction == "up" and self.linepos > 1 then
		self.linepos = self.linepos - 1
		timer.fall.counter = 0
	end
end

function Blocks:collide(otherblocks)
	local collisionExists = false
	for i,line in ipairs(self.blocks) do
		-- line = 1 handled elsewhere
		if i ~= 1 and otherblocks then collisionExists = true end
	end
	return collisionExists
end

function love.load()
	bg = love.graphics.newImage("stars.png")
	math.randomseed(os.time())
	require("letters.lua")
	base = {
		block = {
			size = 4,
		},
	}
		-- the playfield is called map here (sorry for being an rts player)
		-- limited by screen size and padding of one block
	base.map = {
		maxwidth = math.floor(love.graphics.getWidth() / base.block.size) - base.block.size,
		maxheight = math.floor(love.graphics.getHeight() / base.block.size) - 2 * base.block.size,
	}
	-- title means menu or something like that
	stage = "title"
	-- tracks keys required to have been pressed for game start
	--keyPressed = { up = false, left = false, right = false}
	keyPressed = { up = true, left = true, right = true}
	-- blocks that are fixed
	blocksFixed = {}
	-- time.. dt.. oh boy..
	timer = {
		fall = {
			counter = 0,
			limit = 0.7, -- initial game speed so to say
		},
	}
	-- attacker, fixed and falling blocks blocks (ugh..)
	blocksAttacker = Blocks.create()
	blocksAttacker.linepos = base.map.maxheight + 7
	blocksFalling = Blocks.create()
	-- align middle title text
	blocksFalling.linepos = math.floor(base.map.maxheight / 2)
	blocksFixed = Blocks.create()
end

function startWar(textfile)
	blocksAttacker.blocks = text2blocks(file2text(textfile))
	blocksFalling.blocks = text2blocks(file2text("title.txt"))
	stage = "game"
	timer.fall.counter = 0
end

-- file goes in, table of lines (text) goes out
function file2text(filename)
	local lines = {}
	for line in love.filesystem.lines(filename) do
		table.insert(lines, line)
	end
	return lines
end

-- table of lines goes in, table of blocks goes out
function text2blocks(text)
	local blocks = {} -- table of blocks made from imported characters
	local lineStart = 1 -- current first row for character insertion
	for n,line in ipairs(text) do
		local newLine = true -- var for knowing if there's a new 'line' (set of 5 tables by default) to be filled
		for char in line:gmatch"." do
			-- #charBlock is 5
			local charBlock = char2block(string.lower(char))
			-- if we're going into a new line
			if newLine then
				-- if the previous line can hold no more chars, fill the tables with false
				if lineStart ~= 1 then
					for cnt=1,6 do
						local num = lineStart - cnt
						blocks[num] = tableFillFalse(blocks[num])
					end
				end
				-- create new lines for new line
				for cnt=0,5 do
					table.insert(blocks,{})
				end
				newLine = false
			end
			-- insert the blocks
			for o,crow in ipairs(charBlock) do
				-- for each cell in a row
				-- adding lines to blocks on need
				for p,ccell in ipairs(crow) do
					table.insert(blocks[lineStart - 1 + o], ccell)
					-- add space unless end of row
					if p == #charBlock[1] and #blocks[lineStart - 1 + o] < base.map.maxwidth then
						table.insert(blocks[lineStart - 1 + o], false)
					end
				end --ccells
			end --crow
			-- check if
			if #blocks[lineStart] + #charBlock[1] > base.map.maxwidth then
				lineStart = lineStart + 6
				newLine = true
			end
		end --char
		newLine = true
	end --line
	-- following code is dirty solution to last line not having full width
	lineStart = lineStart + 6
	for cnt=1,6 do
		local num = lineStart - cnt
		blocks[num] = tableFillFalse(blocks[num])
	end
	return blocks
end

function tableFillFalse(tableFalse)
	while #tableFalse < base.map.maxwidth do
		table.insert(tableFalse,false)
	end
	return tableFalse
end

-- character goes in, representing block goes out
function char2block(char)
	local block = {}
	-- assign char-representing block table to block var (or nil if not available)
	block = letters[char]
	-- exception for unknown, including space, since variables can't be called " "
	if block == nil then
		block = {{false,false,false},{false,false,false},{false,false,false},{false,false,false},{false,false,false},}
	end
	return block
end

function love.update(dt)
	if stage == "game" then
		timer.fall.counter = timer.fall.counter + dt
	end
	if stage == "game" and timer.fall.counter >= timer.fall.limit then
		timer.fall.counter = timer.fall.counter%timer.fall.limit
		-- move attacker blocks if they're not high enough
		if blocksAttacker.linepos > base.map.maxheight - 8 then
			blocksAttacker:move()
		end
		-- put falling blocks in fixed blocks if they are too high (collide with border or fixed blocks
		if blocksFalling.collide(blocksFixed) or blocksFalling.linepos == 1 then
			table.insert(blocksFixed,blocksFalling.blocks[1])
			table.remove(blocksFalling.blocks,1)
		-- move blocks if they're not too hight
		else
			blocksFalling:move()
		end
	end
end

function love.draw(dt)
	love.graphics.draw(bg,0,0)
	if stage == "title" then
		
	end
	if stage == "game" then
		-- attacker blocks
		local pos = {
			x = base.block.size * 2,
			y = blocksAttacker.linepos * base.block.size + base.block.size,
		} 
		for i,bline in ipairs(blocksAttacker.blocks) do
			for j,bcell in ipairs(bline) do
				colorRandomize("mid")
				if bcell then love.graphics.rectangle("fill", pos.x, pos.y, base.block.size, base.block.size) end
				colorRandomize("dark")
				if not bcell then love.graphics.rectangle("fill", pos.x, pos.y, base.block.size, base.block.size) end
				pos.x = pos.x + base.block.size
			end -- bcell
			pos.x = base.block.size * 2
			pos.y = pos.y + base.block.size
		end -- bline
		-- attacker blocks
		local pos = {
			x = base.block.size * 2,
			y = blocksFalling.linepos * base.block.size + base.block.size,
		} 
		-- falling blocks
		for i,bline in ipairs(blocksFalling.blocks) do
			for j,bcell in ipairs(bline) do
				colorRandomize("light")
				if bcell then love.graphics.rectangle("fill", pos.x, pos.y, base.block.size, base.block.size) end
				colorRandomize("dark")
				if not bcell then love.graphics.rectangle("fill", pos.x, pos.y, base.block.size, base.block.size) end
				pos.x = pos.x + base.block.size
			end -- bcell
			pos.x = base.block.size * 2
			pos.y = pos.y + base.block.size
		end -- bline
	end -- if stage is game
end

function love.keypressed(key, unicode)
	-- quit available at all times
	if key == '' or key == 'escape' then
		love.event.push('q') -- quit the game 
	end
	if stage == "game" then
		if key == "right" or "left" then
			blocksFalling:makestep(key)
		end
	elseif stage == "title" then
		if key == 'up' or key == 'left' or key == 'right' then
			keyPressed[key] = true
			if keyPressed.up and keyPressed.left and keyPressed.right then
				startWar("test.txt")
			end
		end
	end
end

function colorRandomize(tone)
	if tone == "light" then
		love.graphics.setColor(math.random(200,255),math.random(200,255),math.random(200,255))
	elseif tone == "mid" then
		love.graphics.setColor(math.random(100,255),math.random(100,255),math.random(100,255))
	elseif tone == "dark" then
		love.graphics.setColor(math.random(50,55),math.random(50,55),math.random(50,55))
	end
end

