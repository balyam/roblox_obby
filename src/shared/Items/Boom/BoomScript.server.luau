local Debris = game:GetService("Debris")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

local FUSE_TIME = 2 -- сколько секунд до "бума"
local COOLDOWN = 3 -- через сколько секунд можно бросить снова
local THROW_SPEED = 10
local BLAST_RADIUS = 10 -- радиус взрыва в стадах (studs)
local BLAST_PRESSURE = 1000000 -- сила отбрасывания (стандарт — 500000)

local canThrow = true

-- Activated срабатывает, когда игрок кликает, держа инструмент в руке
tool.Activated:Connect(function()
	if not canThrow then
		return
	end

	-- Пока инструмент в руке, его родитель — персонаж игрока
	local character = tool.Parent
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	canThrow = false

	-- Делаем копию шарика из руки — это и будет летящий Boom
	local boom = handle:Clone()
	boom.Name = "ThrownBoom"
	boom.CanCollide = true
	boom.CFrame = root.CFrame * CFrame.new(0, 1, -3) -- чуть впереди игрока
	boom.AssemblyLinearVelocity = root.CFrame.LookVector * THROW_SPEED + Vector3.new(0, 10, 0)
	boom.Parent = workspace

	-- Прячем шарик в руке, пока идёт перезарядка
	handle.Transparency = 1

	task.delay(FUSE_TIME, function()
		local explosion = Instance.new("Explosion")
		explosion.Position = boom.Position
		explosion.BlastRadius = BLAST_RADIUS
		explosion.BlastPressure = BLAST_PRESSURE
		-- 0 = никого не ломает и не убивает, только красиво отталкивает
		explosion.DestroyJointRadiusPercent = 0
		explosion.Parent = workspace

		-- Звук нельзя оставлять внутри шарика: удалим шарик — пропадёт и звук.
		-- Поэтому переносим звук в невидимую точку (Attachment) на месте взрыва
		local soundPoint = Instance.new("Attachment")
		soundPoint.WorldPosition = boom.Position
		soundPoint.Parent = workspace.Terrain
		local sound = boom.BoomSound
		sound.Parent = soundPoint
		sound.PlaybackSpeed = math.random(90, 110) / 100 -- каждый "бум" звучит чуть по-разному
		sound:Play()
		Debris:AddItem(soundPoint, 3) -- убрать точку через 3 секунды, когда звук доиграет

		boom:Destroy()
	end)

	task.delay(COOLDOWN, function()
		handle.Transparency = 0
		canThrow = true
	end)
end)
