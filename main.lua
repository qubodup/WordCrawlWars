function love.load()
	bg = love.graphics.newImage("stars.png")
	math.randomseed(os.time())
	require("letters.lua")
	-- Some game name about words, crawl and war I guess
	base = {
		block = {
			size = 4,
		},
	}
	blocks = text2blocks(file2text("test.txt"))
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
	-- limited by screen size and padding of one block
	local maxBlocks = math.floor(love.graphics.getWidth() / base.block.size) - 2 * base.block.size
	local currLine = 1
	for n,line in ipairs(text) do
		table.insert(blocks, {})
		for char in line:gmatch"." do
			-- letter wrap
			if lineBlocks > maxBlocks then
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

function love.draw(dt)
	love.graphics.draw(bg,0,0)
	pos = {x=base.block.size*2,y=love.graphics.getHeight() - base.block.size*7}
	for i,line in ipairs(blocks) do
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
end

function love.keypressed(key, unicode)
        if key == 'q' or key == 'escape' then
                love.event.push('q') -- quit the game 
        end
end

