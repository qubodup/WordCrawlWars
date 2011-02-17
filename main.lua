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
	blcks.linepos = 1
	return blcks
end

function Blocks:move()
	-- put falling blocks in fixed blocks if they are too high (collide with border or fixed blocks)
	if  blocksFall.linepos == 1 or blocksFall:collide(blocksFix) then
		--table.insert(blocksFix.blocks,blocksFall.blocks[1])
		--table.remove(blocksFall.blocks,1)
		--if blocksFall.linepos > #blocksFix.blocks then table.insert(blocksFix,{}) end
		blocksFix:injectBlocks(blocksFall)
		table.remove(blocksFall.blocks,1)
		blocksFall.linepos = blocksFall.linepos + 1
		blocksFall:remTopEmpty()
	else
		self.linepos = self.linepos - 1
	end
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
		self:move()
		timer.fall.counter = 0
	end
end

-- blocksFall:collide(blocksFix)
function Blocks:collide(otherblocks)
	local collisionExists = false
	if self.linepos > 1 and otherblocks.blocks[self.linepos - 1] ~= nil then
		for i,v in ipairs(self.blocks[1]) do
			if v and otherblocks.blocks[self.linepos - 1][i] then collisionExists = true end
		end
	end
--debug	if collisionExists then print("colEx",collisionExists) end
	return collisionExists
end

-- blocksFix:injectBlocks(blocksFall)
function Blocks:injectBlocks(otherblocks)
	if self.blocks[blocksFall.linepos] == nil then table.insert(self.blocks,tableFillFalse({})) end
	for i,v in ipairs(self.blocks[otherblocks.linepos]) do
		self.blocks[otherblocks.linepos][i] = v or otherblocks.blocks[1][i]
	end
end

function Blocks:remTopEmpty()
	while blocksFall.blocks[1] ~= nil and tableIsFullOfFalse(blocksFall.blocks[1]) do
		table.remove(blocksFall.blocks,1)
		blocksFall.linepos = blocksFall.linepos + 1
	end
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
	-- time.. dt.. oh boy..
	timer = {
		fall = {
			counter = 0,
			limit = 0.7, -- initial game speed so to say
		},
	}
	-- attacker, fixed and falling blocks blocks (ugh..)
	blocksAtt = Blocks.create()
--	blocksAtt.linepos = base.map.maxheight + 7
	blocksAtt.linepos = math.floor(base.map.maxheight/3)
	blocksFall = Blocks.create()
	-- align middle title text
	blocksFall.linepos = math.floor(base.map.maxheight / 8)
--	blocksFall.linepos = math.floor(base.map.maxheight / 2)
	blocksFix = Blocks.create()
end

function startWar(textfile)
	blocksAtt.blocks = text2blocks(file2text(textfile))
	blocksFall.blocks = text2blocks(file2text("title.txt"))
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

function tableIsFullOfFalse(testtable)
	local onlyfalse = true
	for i,v in ipairs(testtable) do if v then onlyfalse = not v end end
	return onlyfalse
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
		if blocksAtt.linepos > base.map.maxheight - 8 then
			blocksAtt:move()
		end
		blocksFall:move()
	end
	-- update falling
	while #blocksAtt.blocks > 0 and #blocksFall.blocks == 0 do
		table.insert(blocksFall.blocks,blocksAtt.blocks[1])
		blocksFall.linepos = blocksAtt.linepos
		table.remove(blocksAtt.blocks,1)
		blocksAtt.linepos = blocksAtt.linepos + 1
		blocksFall:remTopEmpty()
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
			y = blocksAtt.linepos * base.block.size + base.block.size,
		} 
		for i,bline in ipairs(blocksAtt.blocks) do
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
		-- fixed blocks
		local pos = {
			x = base.block.size * 2,
			y = blocksFix.linepos * base.block.size + base.block.size,
		} 
		for i,bline in ipairs(blocksFix.blocks) do
			for j,bcell in ipairs(bline) do
				colorRandomize("red")
				if bcell then love.graphics.rectangle("fill", pos.x, pos.y, base.block.size, base.block.size) end
				colorRandomize("dark")
				if not bcell then love.graphics.rectangle("fill", pos.x, pos.y, base.block.size, base.block.size) end
				pos.x = pos.x + base.block.size
			end -- bcell
			pos.x = base.block.size * 2
			pos.y = pos.y + base.block.size
		end -- bline
		-- falling blocks
		local pos = {
			x = base.block.size * 2,
			y = blocksFall.linepos * base.block.size + base.block.size,
		} 
		for i,bline in ipairs(blocksFall.blocks) do
			for j,bcell in ipairs(bline) do
				colorRandomize("light")
				if bcell then love.graphics.rectangle("fill", pos.x, pos.y, base.block.size, base.block.size) end
				--colorRandomize("dark")
				--if not bcell then love.graphics.rectangle("fill", pos.x, pos.y, base.block.size, base.block.size) end
				pos.x = pos.x + base.block.size
			end -- bcell
			pos.x = base.block.size * 2
			pos.y = pos.y + base.block.size
		end -- bline
--debuFixg
				colorRandomize("red")
love.graphics.rectangle("fill",0,blocksAtt.linepos, 2,1)
love.graphics.rectangle("fill",0,blocksFall.linepos,2,1)
love.graphics.rectangle("fill",0,blocksFix.linepos, 2,1)
--print(blocksAtt.linepos,blocksFall.linepos,blocksFix.linepos)
--debug
	end -- if stage is game
end

function love.keypressed(key, unicode)
	-- quit available at all times
	if key == '' or key == 'escape' then
		love.event.push('q') -- quit the game 
	end
	if stage == "game" then
		if key == "right" or "left" then
			blocksFall:makestep(key)
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
	elseif tone == "red" then
		love.graphics.setColor(math.random(100,255),math.random(100,155),math.random(100,155))
	end
end

