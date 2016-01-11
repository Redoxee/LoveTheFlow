DT = 0.1

NB_ITERATION = 1

renderResolution = 256
renderWidth = renderResolution
renderHeight = renderResolution

windowsWidth = false
windowsHeight = false

renderQuad = false

bufferTexture = false
velocityTexture = false
pressureTexture = false
quantityTexture = false
divergenceTexture = false

advecShader = false
divergenceShader = false
jacobiIterationShader = false
gradientSubstractionShader = false

additionShader = false

testShader = false

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
	pressureTexture = g.newCanvas(renderWidth,renderHeight)
	divergenceTexture = g.newCanvas(renderWidth,renderHeight)

	renderQuad = g.newQuad(0,0,renderWidth,renderHeight,renderWidth,renderHeight)


	local shaderParameters = {
		sampleResolution = renderResolution
	}
	shaderParameters["##RENDERSIZE"] = renderResolution

	advecShader = BuildShaderWithParameter("ShadertoyShaders/AdvecShader", shaderParameters)
	divergenceShader = BuildShaderWithParameter("ShadertoyShaders/DivergenceShader",shaderParameters)
	jacobiIterationShader = BuildShaderWithParameter("ShadertoyShaders/JacobiIterationShader",shaderParameters)
	gradientSubstractionShader = BuildShaderWithParameter("ShadertoyShaders/GradientSubstractionShader",shaderParameters)

	magnitudeShader = g.newShader("Shaders/DrawMagnitude.shr")

	fullQuad = g.newQuad(0,0,windowsWidth,windowsHeight,windowsWidth,windowsHeight)

	g.setCanvas(velocityTexture)
	stillImage = g.newImage("Media/placeholder.png")
	g.draw(stillImage,renderQuad)
	-- g.setCanvas(pressureTexture)
	-- g.draw(stillImage,renderQuad)
	g.setCanvas()

end

ApplyImage = function()
	
	love.graphics.setCanvas(velocityTexture)
	love.graphics.draw(stillImage,renderQuad)
	-- love.graphics.setCanvas(pressureTexture)
	love.graphics.draw(stillImage,renderQuad)
	love.graphics.setCanvas()
end

ComputeFluid = function()
	local g = love.graphics
	local setCanvas = g.setCanvas
	local setShader = g.setShader

	-- advection velocity
	setCanvas(bufferTexture)
	setShader(advecShader)
	advecShader:send("dt",DT)
	g.draw(velocityTexture,renderQuad,0,0)

	--swap
	local t = velocityTexture
	velocityTexture = bufferTexture
	bufferTexture = t


	-- divergence
	setCanvas(bufferTexture)
	setShader(divergenceShader)
	-- divergenceShader:send("dt",DT)
	g.draw(velocityTexture,renderQuad,0,0)

	--swap
	local t = divergenceTexture
	divergenceTexture = bufferTexture
	bufferTexture = t

	-- JacobiIteratin
	for i = 1 , NB_ITERATION do 
		setCanvas(bufferTexture)
		setShader(jacobiIterationShader)
		-- jacobiIterationShader:send("dt",DT)
		jacobiIterationShader:send("pressureTexture",pressureTexture)
		jacobiIterationShader:send("divergenceTexture",divergenceTexture)
		g.draw(velocityTexture,renderQuad,0,0)

		--swap
		local t = pressureTexture
		pressureTexture = bufferTexture
		bufferTexture = t
	end

	setCanvas(bufferTexture)
	setShader(gradientSubstractionShader)
	-- gradientSubstractionShader:send("dt",DT)
	gradientSubstractionShader:send("pressureTexture",pressureTexture)
	g.draw(velocityTexture,renderQuad,0,0)


	--swap
	local t = velocityTexture
	velocityTexture = bufferTexture
	bufferTexture = t

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

DrawPressure = function()
	love.graphics.clear()
	love.graphics.draw(pressureTexture,fullQuad)
end

DrawDivergence = function()
	love.graphics.clear()
	love.graphics.draw(divergenceTexture,fullQuad)
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
