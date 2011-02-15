-- WorldCrawlWars Copyright 2011 Iwan 'qubodup' Gabovitch <qubodup@gmail.com>
-- Licensed under um... GPL! Ha, take that!
-- Some game about words, crawl and war I guess

-- blocks class
Blocks = {}
Blocks.__index = Blocks

function Blocks.create()
	local blcks = {}
	setmetatable(blcks,Blocks)
	-- the actual blocks.. in the blocks.. in the blocks..? it's a table of x tables of y booleans
	blcks.blocks = {}
	-- top position (top is first line)
	blcks.linepos = {}
	return blcks
end

function Blocks:move()
	self.linepos = self.linepos + 1
end

function Blocks.collide(otherblocks)
	local collisionExists = false
	for i,v in ipairs(self.blocks) do
		if true then collisionExists = true end
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
		columns = math.floor(love.graphics.getWidth() / base.block.size) - 2 * base.block.size,
		rows = math.floor(love.graphics.getHeight() / base.block.size) - 2 * base.block.size,
	}
	-- title means menu or something like that
	stage = "title"
	-- tracks keys required to have been pressed for game start
	keyPressed = { up = false, left = false, right = false}
	-- blocks that are fixed
	blocksFixed = {}
	-- time.. dt.. oh boy..
	timer = {
		fall = {
			counter = 0,
			limit = 8, -- initial game speed so to say
		},
	}
	-- attacker, fixed and falling blocks blocks (ugh..)
	blocksAttacker = Blocks.create()
	blocksFixed = Blocks.create()
	blocksFalling = Blocks.create()
end

function startWar(textfile)
	blocksAttacker.blocks = text2blocks(file2text(textfile))
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
	local blocks = {}
	-- the following two vars are for letter wrap and count blocks, not pixels
	local lineBlocks = 0
	local currLine = 1
	for n,line in ipairs(text) do
		table.insert(blocks, {})
		for char in line:gmatch"." do
			-- letter wrap
			if lineBlocks > base.map.columns then
				table.insert(blocks, {})
				currLine = currLine + 1
				lineBlocks = 0
			end
			charBlocks = char2block(string.lower(char))
			-- + 1 because of empty space behind each char
			lineBlocks = lineBlocks + #charBlocks[1] + 1
			table.insert(blocks[currLine], charBlocks)
		end
		currLine = currLine + 1
		lineBlocks = 0
	end
	return blocks
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
		if blocksAttacker.linepos < 16 then
			blocksAttacker:move()
		end
		-- put falling blocks in fixed blocks if they are too high
		if blocksFalling.collide(blocksFixed) then
			
		-- move blocks if they're not too hight
		else
			
		end
	end
end

function love.draw(dt)
	love.graphics.draw(bg,0,0)
	if stage == "title" then
		
	end
	if stage == "game" then
		--pos = {blocksAttack.linepos
		pos = {x=base.block.size*2,y=love.graphics.getHeight() - base.block.size*7}
		for i,line in ipairs(blocksAttacker.blocks) do
			for j,char in ipairs(line) do
				for k,blockline in ipairs(char) do
					for l,block in ipairs(blockline) do
						if block then love.graphics.rectangle("fill",pos.x,pos.y,base.block.size,base.block.size) end
						pos.x = pos.x + base.block.size --l%#blockline
						love.graphics.setColor(math.random(100,255),math.random(100,255),math.random(100,255))
					end -- block
					pos.x = pos.x - #blockline*base.block.size
					pos.y = pos.y + base.block.size
				end -- blockline
			pos.x = pos.x + (#char[1] + 1)*base.block.size
			pos.y = pos.y - base.block.size*5
			end -- char
			pos.x = base.block.size*2
			pos.y = pos.y + base.block.size*10
		end -- line
	end -- if stage is game
end

function love.keypressed(key, unicode)
	-- quit available at all times
	if key == '' or key == 'escape' then
		love.event.push('q') -- quit the game 
	end
	if stage == "title" then
		if key == 'up' or key == 'left' or key == 'right' then
			keyPressed[key] = true
			if keyPressed.up and keyPressed.left and keyPressed.right then
				startWar("test.txt")
			end
		end
	end
end

