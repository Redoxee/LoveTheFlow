
renderResolution = 128
renderWidth = renderResolution
renderHeight = renderResolution

windowsWidth = false
windowsHeight = false

renderQuad = false

tempTexture = false
velocityTexture = false
densityTexture = false

velocityShader = false
densityShader = false



fullQuad = false

function love.load()
	windowsWidth,windowsHeight = love.window.getWidth(),love.window.getHeight()
	Initialize()
end
Initialize = function()
	
	tempTexture = love.graphics.newCanvas(renderWidth,renderHeight)
	velocityTexture = love.graphics.newCanvas(renderWidth,renderHeight)
	densityTexture = love.graphics.newCanvas(renderWidth,renderHeight)

	renderQuad = love.graphics.newQuad(0,0,renderWidth,renderHeight,renderWidth,renderHeight)

	velocityShader = love.graphics.newShader("Shaders/VelocityShader.shr")
	densityShader = love.graphics.newShader("Shaders/DensityShader.shr")

	fullQuad = love.graphics.newQuad(0,0,windowsWidth,windowsHeight,windowsWidth,windowsHeight)

	love.graphics.setCanvas(velocityTexture)
	local img = love.graphics.newImage("Media/placeholder.png")
	love.graphics.draw(img,renderQuad)
	love.graphics.setCanvas()

end

ComputeFluid = function()

	local g = love.graphics
	local setCanvas = g.setCanvas
	local setShader = g.setShader

	setCanvas(tempTexture)
	g.clear()
	setShader(velocityShader)
	velocityShader:send("FieldSampler",velocityTexture)
	velocityShader:send("DensitySampler",densityTexture)
	velocityShader:send("FieldLinearSampler",velocityTexture)
	g.draw(velocityTexture,renderQuad,0,0)

	local prevVelocity = velocityTexture
	velocityTexture = tempTexture

	setCanvas(prevVelocity)
	g.clear()
	setShader(densityShader)
	densityShader:send("DensitySampler",densityTexture)
	densityShader:send("DensityLinearSampler",densityTexture)
	densityShader:send("FieldLinearSampler",velocityTexture)
	g.draw(densityTexture,renderQuad,0,0)

	tempTexture = densityTexture
	densityTexture = prevVelocity

	setShader()
	setCanvas()
end


DrawVelocity = function()

	love.graphics.clear()
	love.graphics.draw(velocityTexture,fullQuad)
end

DrawDensity = function()
	love.graphics.clear()
	love.graphics.draw(densityTexture,fullQuad)
end


function love.draw()
	ComputeFluid()
	DrawDensity()
end

function love.update( dt )
	
	if love.keyboard.isDown("escape") then
  		love.event.push('quit')
	end
end