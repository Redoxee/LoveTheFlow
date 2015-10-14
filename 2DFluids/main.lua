DT = 0.1


renderResolution = 256
renderWidth = renderResolution
renderHeight = renderResolution

windowsWidth = false
windowsHeight = false

renderQuad = false

bufferTexture = false
velocityTexture = false
densityTexture = false
quantityTexture = false

advectionShader = false
jacobiShader = false
divergenceShader = false
gradientSubstractionShader = false
boundaryShader = false

additionShader = false

stillImage = false

fullQuad = false

function love.load()
	windowsWidth,windowsHeight = love.window.getWidth(),love.window.getHeight()
	Initialize()
end
Initialize = function()
	local g = love.graphics

	bufferTexture = g.newCanvas(renderWidth,renderHeight)
	velocityTexture = g.newCanvas(renderWidth,renderHeight)
	densityTexture = g.newCanvas(renderWidth,renderHeight)

	renderQuad = g.newQuad(0,0,renderWidth,renderHeight,renderWidth,renderHeight)


	local shaderParameters = {
		sampleResolution = renderResolution
	}


	advectionShader = BuildShaderWithParameter("GPUGemShaders/AdvectionShader", shaderParameters)
	jacobiShader = BuildShaderWithParameter("GPUGemShaders/JacobiShader", shaderParameters)
	divergenceShader = BuildShaderWithParameter("GPUGemShaders/DivergenceShader", shaderParameters)
	gradientSubstractionShader = BuildShaderWithParameter("GPUGemShaders/DivergenceShader", shaderParameters)
	boundaryShader = BuildShaderWithParameter("GPUGemShaders/BoundaryShader", shaderParameters)

	additionShader = BuildShaderWithParameter("AdditionShader", shaderParameters)

	magnitudeShader = g.newShader("Shaders/DrawMagnitude.shr")

	fullQuad = g.newQuad(0,0,windowsWidth,windowsHeight,windowsWidth,windowsHeight)

	g.setCanvas(velocityTexture)
	stillImage = g.newImage("Media/placeholder.png")
	g.draw(stillImage,renderQuad)
	g.setCanvas(densityTexture)
	g.draw(stillImage,renderQuad)
	g.setCanvas()

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

	-- advection velocity
	setCanvas(bufferTexture)
	setShader(advectionShader)
	advectionShader:send("quantityField",velocityTexture)
	advectionShader:send("dt",DT)
	g.draw(velocityTexture,renderQuad,0,0)
	local t = velocityTexture
	velocityTexture = bufferTexture
	bufferTexture = t

	-- jacobi
	for i = 1,10 do
		local step = 1/renderResolution
		local alpha = (step * step) / DT
		local rBeta = 1/(4 + (step * step) / DT)

		setCanvas(bufferTexture)
		setShader(jacobiShader)
		jacobiShader:send("quantityField",velocityTexture)
		jacobiShader:send("alpha",alpha)
		jacobiShader:send("rBeta",rBeta)
		g.draw(velocityTexture,renderQuad,0,0)
		local t = velocityTexture
		velocityTexture = bufferTexture
		bufferTexture = t
	end

	-- Force
	-- setCanvas(bufferTexture)
	-- setShader(additionShader)
	-- additionShader:send("additionalField",stillImage)
	-- g.draw(velocityTexture,renderQuad,0,0)
	-- local t = velocityTexture
	-- velocityTexture = bufferTexture
	-- bufferTexture = t


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
	DT = dt
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
