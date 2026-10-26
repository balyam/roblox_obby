-- Генератор трассы: строит этапы obby сразу после финиша тестовой трассы Course

local STAGES = 20 -- сколько этапов построить
local SEED = 42 -- одно и то же число = одна и та же трасса при каждом запуске
local PLATFORM_Y = 6 -- высота, на которой идет трасса

local LAVA_COLOR = Color3.fromRGB(255, 90, 0)

local course = workspace:WaitForChild("Course")
local finish = course:WaitForChild("Finish")

local generated = Instance.new("Folder")
generated.Name = "GeneratedCourse"
generated.Parent = workspace

local random = Random.new(SEED)

-- "Курсор": координата Z, где заканчивается уже построенная часть трассы
local startZ = finish.Position.Z + finish.Size.Z / 2
local z = startZ

-- Обычный неподвижный блок
local function block(name, size, position, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Parent = parent
	return part
end

-- Блок лавы: тег "Lava" подхватит LavaScript
local function lava(name, size, position, parent)
	local part = block(name, size, position, LAVA_COLOR, parent)
	part.Material = Enum.Material.Neon
	part:AddTag("Lava")
	return part
end

-- Надпись над деталью ("Этап 5", "ФИНИШ!")
local function label(part, text)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.MaxDistance = 80
	gui.Parent = part

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0
	textLabel.Parent = gui
end

-- Движущаяся платформа. Ездит туда-обратно вдоль оси axis на distance от центра.
-- Двигаем ее физикой (PrismaticConstraint), а не телепортом, —
-- тогда игрок, стоящий на платформе, едет вместе с ней.
local function movingPlatform(parent, center, axis, distance, speed, color, startDelay)
	-- Невидимая неподвижная "рельса"
	local rail = block("Rail", Vector3.one, center, color, parent)
	rail.Transparency = 1
	rail.CanCollide = false

	local platform = block("MovingPlatform", Vector3.new(6, 1, 6), center, color, parent)
	platform.Anchored = false

	local railAttachment = Instance.new("Attachment")
	railAttachment.Axis = axis
	railAttachment.Parent = rail

	local platformAttachment = Instance.new("Attachment")
	platformAttachment.Axis = axis
	platformAttachment.Parent = platform

	-- PrismaticConstraint разрешает только скользить вдоль оси, без вращения
	local slider = Instance.new("PrismaticConstraint")
	slider.Attachment0 = railAttachment
	slider.Attachment1 = platformAttachment
	slider.ActuatorType = Enum.ActuatorType.Servo -- сам едет к TargetPosition
	slider.Speed = speed
	slider.ServoMaxForce = 10000000
	slider.Parent = platform

	-- Физику платформы считает сервер, чтобы она не дергалась у игроков
	platform:SetNetworkOwner(nil)

	task.spawn(function()
		task.wait(startDelay)
		local side = 1
		while platform.Parent do
			slider.TargetPosition = side * distance
			task.wait(2 * distance / speed + 0.5)
			side = -side
		end
	end)
end

-- Площадка в начале каждого этапа
local function stagePad(stage, color, parent)
	local pad = block("Stage" .. stage, Vector3.new(8, 1, 8), Vector3.new(0, PLATFORM_Y, z + 4), color, parent)
	pad.Material = Enum.Material.SmoothPlastic
	pad:SetAttribute("Stage", stage)
	pad:AddTag("Checkpoint") -- площадку подхватит модуль Checkpoints
	label(pad, "Этап " .. stage)
	z += 8
end

-- Типы этапов. difficulty — от 0 (первый этап) до 1 (последний)

-- Прыжки по платформам: с ростом сложности они меньше, а промежутки больше
local function jumpsStage(difficulty, color, parent)
	local count = 3 + math.floor(difficulty * 2)
	local size = 6 - difficulty * 3
	local gap = 4 + difficulty * 4
	for _ = 1, count do
		z += gap
		local x = random:NextNumber(-3, 3) * difficulty
		local y = PLATFORM_Y + random:NextNumber(-1, 1)
		block("Jump", Vector3.new(size, 1, size), Vector3.new(x, y, z + size / 2), color, parent)
		z += size
	end
	z += gap
end

-- Дорожка с полосками лавы, через которые надо перепрыгнуть
local function lavaPathStage(difficulty, color, parent)
	local strips = 2 + math.floor(difficulty * 3)
	local stripWidth = 2 + difficulty * 1.5
	local length = 8 * (strips + 1)
	block("Path", Vector3.new(6, 1, length), Vector3.new(0, PLATFORM_Y, z + length / 2), color, parent)
	for i = 1, strips do
		local stripZ = z + i * 8
		lava("LavaStrip", Vector3.new(6, 0.4, stripWidth), Vector3.new(0, PLATFORM_Y + 0.7, stripZ), parent)
	end
	z += length
end

-- Платформа-лифт: возит вперед-назад над широкой ямой с лавой
local function forwardMoverStage(difficulty, color, parent)
	local gap = 20 + math.floor(difficulty * 10)
	local speed = 6 + difficulty * 6
	local distance = (gap - 6) / 2 - 0.5 -- чтобы платформа почти касалась краев
	movingPlatform(parent, Vector3.new(0, PLATFORM_Y, z + gap / 2), Vector3.zAxis, distance, speed, color, 0)
	z += gap
end

-- Две платформы ездят влево-вправо: надо поймать момент для прыжка
local function sidewaysMoverStage(difficulty, color, parent)
	local speed = 6 + difficulty * 8
	local distance = 8
	for i = 1, 2 do
		z += 3
		local delay = (i - 1) * distance / speed -- вторая платформа отстает
		movingPlatform(parent, Vector3.new(0, PLATFORM_Y, z + 3), Vector3.xAxis, distance, speed, color, delay)
		z += 6
	end
	z += 3
end

local stageTypes = { jumpsStage, lavaPathStage, forwardMoverStage, sidewaysMoverStage }

for stage = 1, STAGES do
	local difficulty = (stage - 1) / (STAGES - 1)
	local color = Color3.fromHSV((stage - 1) / STAGES, 0.55, 1) -- радуга
	local stageFolder = Instance.new("Folder")
	stageFolder.Name = "Stage" .. stage
	stageFolder.Parent = generated

	stagePad(stage, color, stageFolder)
	local buildStage = stageTypes[(stage - 1) % #stageTypes + 1]
	buildStage(difficulty, color, stageFolder)
end

-- Финиш
local finalPad = block("FinalFinish", Vector3.new(16, 1, 16), Vector3.new(0, PLATFORM_Y, z + 8), Color3.fromRGB(50, 255, 80), generated)
finalPad.Material = Enum.Material.Neon
label(finalPad, "ФИНИШ!")
z += 16

-- Лава под всей новой трассой
local length = z - startZ
lava("LavaFloor", Vector3.new(40, 1, length), Vector3.new(0, 0.5, startZ + length / 2), generated)
