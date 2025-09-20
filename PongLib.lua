local G = love.graphics
local K = love.keyboard
local lib = {}

local gameWidth, gameHeight = 0,0
local ply1X, ply1Y = 0,0
local ply2X, ply2Y = 0,0
local plyW, plyH   = 0,0
local plySpacing   = 0
local plySpeed = 0

local ballX = 0
local ballY = 0
local ballRadius = 10
local ballSpeedX = 180
local ballSpeedY = 180
local ballDirectionX = 0
local ballDirectionY = 0

local playing = false
local pause = false
local prepare = true

local virtualPlayer = true
local vplyAttack = false

local point = false
local wait = 3
local ply1Points = 10
local ply2Points = 10

local font = G.newFont(50)
G.setFont(font)

love.audio.setVolume(0.1)
local hitSound = love.sound.newSoundData("hit.mp3")
local pointSound = love.sound.newSoundData("point.mp3")

local function setRandomBallDir()
	ballDirectionX =  love.math.random() >= 0.5 and 1 or -1
	ballDirectionY =  love.math.random() >= 0.5 and 1 or -1
end

local function rectCollision(x1,y1,w1,h1,x2,y2,w2,h2)
	local px = ballDirectionX < 0 and ply1X or ply2X
	local py = ballDirectionX < 0 and ply1Y or ply2Y

	local xmax = math.max(x1 + w1, x2 + w2)
	local xmin = math.min(x1, x2)

	local ymax = math.max(y1 + h1, y2 + h2)
	local ymin = math.min(y1, y2)

	local xdist = xmax - xmin
	local ydist = ymax - ymin

	if xdist < w1 + w2 and ydist < h1 + h2 then
		return true
	end

	return false
end

function lib.setPlayerProperties(width,height,spacing,speed)
	plyW, plyH  = width, height
	plySpacing  = spacing
	plySpeed    = speed

	-- set positions
	ply1X = spacing
	ply1Y = (gameHeight - plyH)/2
	ply2X = gameWidth - plySpacing - plyW
	ply2Y = ply1Y
end

function lib.setGameArea(width,height)
	gameWidth  = width
	gameHeight = height
	ballX = width/2
	ballY = height/2
end

function lib.draw()
	-- draw game area
	G.rectangle("line",1,1,gameWidth - 2,gameHeight - 2)
	G.line(gameWidth/2,0,gameWidth/2,gameHeight)

	if playing then

		-- draw players
		G.rectangle("fill",ply1X,ply1Y,plyW,plyH,6)
		G.rectangle("fill",ply2X,ply2Y,plyW,plyH,6)

		-- draw ball
		G.circle("fill",ballX,ballY,ballRadius)

		-- points
		local text = ""
		--G.print(ballSpeedY,font,0,5)
		--G.print(ballSpeedX,font,0,50)
		if ply1Points == 11 or ply2Points == 11 then
			text = ply1Points == 11 and "you win!" or "you lose!"
		else
			text = ply1Points.."       "..ply2Points
		end
		G.print(text,font,(gameWidth - font:getWidth(text))/2,100)
	else
		local text = "Press Enter to play"
		local w = G.getFont():getWidth(text)
		local x = (gameWidth - w)/2
		local y = (gameHeight - G.getFont():getHeight())/2
		G.print(text,x,y)
	end
end

function lib.update(dt)
	if playing and (not pause) and (not point) and (not prepare) then

		-- move the ball
		ballX = ballX + (ballDirectionX * ballSpeedX) * dt
		ballY = ballY + (ballDirectionY * ballSpeedY) * dt

		-- check borders collision
		if ballY - ballRadius <= 0 then
			
			ballDirectionY = 1
			love.audio.newSource(hitSound):play()
			if ballSpeedX > 180 then
				ballSpeedX = ballSpeedX - 5
			end

		elseif ballY + ballRadius >= gameHeight  then

			ballDirectionY = -1
			love.audio.newSource(hitSound):play()

			if ballSpeedX > 180 then
				ballSpeedX = ballSpeedX - 5
			end
		end

		--[[
		if ballX - ballRadius < 0 then
			
			ballDirectionX = 1

		elseif ballX + ballRadius > gameWidth then
			
			ballDirectionX = -1
		end
		]]

		-- check keyboard input
		if K.isDown("s") then
			ply1Y = ply1Y - plySpeed * dt
		elseif K.isDown("x") then
			ply1Y = ply1Y + plySpeed * dt
		end

		-- second real player
		if not virtualPlayer then
			if K.isDown("k") then
				ply2Y = ply2Y - plySpeed * dt
			elseif K.isDown(",") then
				ply2Y = ply2Y + plySpeed * dt
			end
		else
			-- second player auntomatic move
			local atack = love.math.random() > 0.5 and true or false
			local border = love.math.random() > 0.5 and ply2Y or ply2Y + plyH
			if ballDirectionX > 0 then
				if ballY > ply2Y + plyH/2 then
					ply2Y = ply2Y + plySpeed * dt
				else
					ply2Y = ply2Y - plySpeed * dt
				end
			end
		end

		-- ball hit the player
		local col1 = rectCollision(ballX - ballRadius,ballY - ballRadius,2*ballRadius,2*ballRadius,ply1X,ply1Y,plyW,plyH)
		local col2 = rectCollision(ballX - ballRadius,ballY - ballRadius,2*ballRadius,2*ballRadius,ply2X,ply2Y,plyW,plyH)
		if col1 then
			love.audio.newSource(hitSound):play()
			ballDirectionX = 1
			local ycol = ((ballY - ply1Y)/plyH) - 0.5
			local yspeed = 50 * math.abs(ycol)
			local keyDown = false
			local dir = ballDirectionY
			local changeDir = false
			--print(ycol)
			if ballSpeedY + yspeed > 300 then
				yspeed = 300 - ballSpeedY
			end

			if ballDirectionY == 1 and K.isDown("s") then
				ballDirectionY = -1
				keyDown = true

			elseif ballDirectionY == -1 and K.isDown("x") then
				ballDirectionY = 1
				keyDown = true
			end

			changeDir = not (dir == ballDirectionY)
			if changeDir and keyDown then
				ballSpeedY = ballSpeedY + yspeed
				if ballSpeedX < 300 and math.abs(ycol) > 0.4 then
					ballSpeedX = 300
				end
			else
				ballSpeedY = ballSpeedY - 5
				if ballSpeedY < 180 then
					ballSpeedY = 180
				end
			end

		elseif col2 then
			love.audio.newSource(hitSound):play()
			ballDirectionX = -1

			ballSpeedY = ballSpeedY - 5
			if ballSpeedY < 180 then
				ballSpeedY = 180
			end
		end

		-- point event
		local ply1Point = ballX + ballRadius >= gameWidth and 1 or 0
		local ply2Point = ballX - ballRadius <= 0 and 1 or 0
		if ply1Point == 1 or ply2Point == 1 then
			love.audio.newSource(pointSound):play()
			wait = 3
			point = true
			ply1Points = ply1Points + ply1Point
			ply2Points = ply2Points + ply2Point
		end

	else
		if wait > 0 then
			wait = wait - dt
		else
			if point then
				point = false
				ballX = gameWidth/2
				ballY = gameHeight/2
				ballSpeedX = 180
				ballSpeedY = 180
				ply1Y = (gameHeight - plyH)/2
				ply2Y = ply1Y
				setRandomBallDir()
			elseif prepare then
				prepare = false
			end

			if ply1Points == 11 or ply2Points == 11 then
				playing = false
			end

			wait = 0
		end
	end
end

function lib.start()
	if not playing then
		playing = true
		pause = false
		prepare = true
		ply1Points = 0
		ply2Points = 0
		setRandomBallDir()
	end
end

function lib.pause()
	pause = not pause
end

return lib