local G = love.graphics
local pong = require "PongLib"

function love.load()
	love.window.setTitle("Pong Classic")
	pong.setGameArea(800,600)
	pong.setPlayerProperties(20,110,50,180)
end

function love.update(dt)
	pong.update(dt)
end

function love.draw()
	pong.draw()
end

function love.keyreleased(key, scancode)
	if key == "return" then
		pong.start()
	end
end