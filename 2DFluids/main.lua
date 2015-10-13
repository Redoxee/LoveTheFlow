
renderResolution = 256
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

magnitudeShader = false

stillImage = false

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


	local shaderParameters = {
		sampleResolution = renderResolution
	}

	velocityShader = BuildShaderWithParameter("VelocityShader",shaderParameters)
	densityShader = BuildShaderWithParameter("DensityShader",shaderParameters)

	magnitudeShader = love.graphics.newShader("Shaders/DrawMagnitude.shr")

	fullQuad = love.graphics.newQuad(0,0,windowsWidth,windowsHeight,windowsWidth,windowsHeight)

	love.graphics.setCanvas(velocityTexture)
	stillImage = love.graphics.newImage("Media/placeholder.png")
	love.graphics.draw(stillImage,renderQuad)
	love.graphics.setCanvas(densityTexture)
	love.graphics.draw(stillImage,renderQuad)
	love.graphics.setCanvas()

end

ApplyImage = function()
	
	love.graphics.setCanvas(velocityTexture)
	love.graphics.draw(stillImage,renderQuad)
	love.graphics.setCanvas(densityTexture)
	love.graphics.draw(stillImage,renderQuad)
	love.graphics.setCanvas()
end

ComputeFluid = function()
	local g = love.graphics
	local setCanvas = g.setCanvas
	local setShader = g.setShader

	setCanvas(tempTexture)
	g.clear()
	setShader(velocityShader)

	velocityShader:send("DensitySampler",densityTexture)
	velocityShader:send("FieldLinearSampler",velocityTexture)
	g.draw(velocityTexture,renderQuad,0,0)

	local prevVelocity = velocityTexture
	velocityTexture = tempTexture

	setCanvas(prevVelocity)
	g.clear()
	setShader(densityShader)

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

DrawVelocityMagnitude = function()
	love.graphics.clear()
	love.graphics.setShader(magnitudeShader)
	love.graphics.draw(velocityTexture,fullQuad)
end

DrawDensity = function()
	love.graphics.clear()
	love.graphics.draw(densityTexture,fullQuad)
end


function love.draw()
	ComputeFluid()
	DrawVelocity()
end

function love.update( dt )
	
	if love.keyboard.isDown("escape") then
  		love.event.push('quit')
	end
end


BuildShaderWithParameter = function(shaderName,parameters)
	print("Building : " .. tostring(shaderName))
	local shaderText = GetShader(shaderName)
	if parameters then
		for k,v in pairs(parameters) do
			shaderText = shaderText:gsub(k,v)
		end
	end
	return love.graphics.newShader(shaderText)
end

GetShader = function(name)
	local shdr = ""
	local BASEPATH = "C:/Users/Anton/Documents/git/2DFluids/LoveTheFlow/2DFluids/"
	local fileName = BASEPATH .. "Shaders/".. name .. ".shr"
	local file = io.open(fileName,"r")
	

	for line in file:lines() do
		shdr = shdr .. line .. "\n"
	end

	file:close()
	return shdr
end
