if SERVER then

	AddCSLuaFile("shared.lua")

	resource.AddFile("materials/models/hevsuit/hevsuit_sheet.vmt")
	resource.AddFile("materials/models/hevsuit/hevsuit_sheet_normal.vtf")

	resource.AddFile("models/weapons/v_kick.dx80.vtx")
	resource.AddFile("models/weapons/v_kick.dx90.vtx")
	resource.AddFile("models/weapons/v_kick.mdl")
	resource.AddFile("models/weapons/v_kick.sw.vtx")
	resource.AddFile("models/weapons/v_kick.vvd")

	resource.AddFile("sound/player/skick/foot_kickbody.wav")
	resource.AddFile("sound/player/skick/foot_kickwall.wav")
	resource.AddFile("sound/player/skick/foot_swing.wav")
	resource.AddFile("sound/player/skick/kick1.wav")
	resource.AddFile("sound/player/skick/kick2.wav")
	resource.AddFile("sound/player/skick/kick3.wav")
	resource.AddFile("sound/player/skick/kick4.wav")
	resource.AddFile("sound/player/skick/kick5.wav")
	resource.AddFile("sound/player/skick/kick6.wav")
	resource.AddFile("sound/player/skick/madness.mp3")
	resource.AddFile("sound/player/skick/sparta.mp3")

	resource.AddFile("materials/vgui/ttt/icon_sparta.png")
end

if CLIENT then
	SWEP.Category = "Shot846"
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
	SWEP.PrintName = "Spartan Kick"
	SWEP.Slot = 7

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "Kick them out of their Life!"
	}

	SWEP.Icon = "vgui/ttt/icon_sparta.png"
end

SWEP.Base = "weapon_tttbase"
SWEP.PrintName = "Spartan Kick"
SWEP.Author = "Converted by Porter"
SWEP.Instructions = "Spartan Kick!"
SWEP.Purpose = "THIS IS SPARTAAAAAAA!"

SWEP.ViewModelFOV = 75
SWEP.ViewModelFlip = false

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.NextStrike = 0

SWEP.ViewModel = "models/weapons/v_kick.mdl"
SWEP.WorldModel = "models/props_lab/huladoll.mdl"
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.AllowDrop = false
SWEP.DestroyDoor = 1

-------------Primary Fire Attributes----------------------------------------
SWEP.Primary.Delay = 0.4 --In seconds
SWEP.Primary.Recoil = 0 --Gun Kick
SWEP.Primary.Damage = 15 --Damage per Bullet
SWEP.Primary.NumShots = 1 --Number of shots per one fire
SWEP.Primary.Cone = 0 --Bullet Spread
SWEP.Primary.ClipSize = -1 --Use "-1 if there are no clips"
SWEP.Primary.DefaultClip = -1 --Number of shots in next clip
SWEP.Primary.Automatic = true --Pistol fire (false) or SMG fire (true)
SWEP.Primary.Ammo = "none" --Ammo Type

util.PrecacheSound("player/skick/madness.mp3")
util.PrecacheSound("player/skick/foot_kickwall.wav")
util.PrecacheSound("player/skick/foot_kickbody.wav")
util.PrecacheSound("player/skick/sparta.mp3")
util.PrecacheSound("player/skick/kick1.wav")
util.PrecacheSound("player/skick/kick2.wav")
util.PrecacheSound("player/skick/kick3.wav")
util.PrecacheSound("player/skick/kick4.wav")
util.PrecacheSound("player/skick/kick5.wav")
util.PrecacheSound("player/skick/kick6.wav")

function SWEP:Initialize()
	if CLIENT then
		self:AddHUDHelp("MOUSE1 : Kick Like a Spartan", "MOUSE2 : Play Madness Sound", false)
	else
		self:SetWeaponHoldType("normal")
	end

	self.Hit = {
		Sound("player/skick/foot_kickwall.wav")
	}

	self.FleshHit = {
		Sound("player/skick/kick1.wav"),
		Sound("player/skick/kick2.wav"),
		Sound("player/skick/kick3.wav"),
		Sound("player/skick/kick4.wav"),
		Sound("player/skick/kick5.wav"),
		Sound("player/skick/kick6.wav")
	}
end

function SWEP:Precache()

end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_IDLE)

	return true
end

function SWEP:PrimaryAttack()
	if CurTime() < self.NextStrike then return end

	self:EmitSound("player/skick/sparta.mp3")

	self.NextStrike = CurTime() + 3.5

	local swep = self

	timer.Create("skicktimer1", 1.80, 1, function()
		if IsValid(swep) then
			swep.AttackAnim(swep)
		end
	end)

	timer.Create("skicktimer2", 2.40, 1, function()
		if IsValid(swep) then
			swep:SendWeaponAnim(ACT_VM_IDLE)
		end
	end)

	timer.Create("skicktimer3", 2.0, 1, function()
		if IsValid(swep) then
			swep.ShootBullets(swep)
		end
	end)

	self.Owner:SetAnimation(PLAYER_ATTACK1)
end

local kickedPlys = {}

hook.Add("TTTPrepareRound", "SpartanKickEnd", function(ply)
	for i = 1, 6 do
		local name = "skicktimer" .. i

		if timer.Exists(name) then
			timer.Remove(name)
		end
	end

	kickedPlys = {}
end)

if SERVER then
	hook.Add("TTT2ModifyRagdollVelocity", "TTT2FixSpartanKickVelocity", function(ply, rag, v)
		for k, p in ipairs(kickedPlys) do
			if p == ply then
				table.remove(kickedPlys, k)

				v:Mul(5)
			end
		end
	end)
end

function SWEP:ShootBullets()
	local owner = self:GetOwner() or self.Owner

	if not IsValid(owner) then return end

	self:EmitSound("player/skick/foot_swing.wav")

	local trace = owner:GetEyeTrace()

	if trace.HitPos:Distance(owner:GetShootPos()) <= 130 then
		if SERVER and TTT2 and trace.Entity:IsPlayer() or trace.Entity:IsNPC() then
			kickedPlys[#kickedPlys + 1] = trace.Entity
		end

		bullet = {}
		bullet.Num = 5
		bullet.Src = owner:GetShootPos()
		bullet.Dir = owner:GetAimVector()
		bullet.Spread = Vector(0.04, 0.04, 0.04)
		bullet.Tracer = 0
		bullet.Force = 450
		bullet.Damage = 1000000

		owner:FireBullets(bullet)

		if not IsValid(trace.Entity) then return end

		if trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity:GetClass() == "prop_ragdoll" then
			owner:EmitSound(self.FleshHit[math.random(1, #self.FleshHit)])
		else
			owner:EmitSound(self.Hit[math.random(1, #self.Hit)])

			if SERVER and trace.Entity:GetClass() == "prop_door_rotating" then
				trace.Entity:Fire("open", "", 0.001)
				trace.Entity:Fire("unlock", "", 0.001)

				local pos = trace.Entity:GetPos()
				local model = trace.Entity:GetModel()
				local skin = trace.Entity:GetSkin()

				local smoke = EffectData()
				smoke:SetOrigin(pos)

				util.Effect("effect_smokedoor", smoke)

				trace.Entity:SetNotSolid(true)
				trace.Entity:SetNoDraw(true)

				local function ResetDoor(door, fakedoor)
					door:SetNotSolid(false)
					door:SetNoDraw(false)

					fakedoor:Remove()
				end

				local norm = pos - owner:GetPos()
				norm:Normalize()

				local push = 1000 * norm

				local ent = ents.Create("prop_physics")
				ent:SetPos(pos)
				ent:SetAngles(Angle(10, 50, 0))
				ent:SetModel(model)

				if skin then
					ent:SetSkin(skin)
				end

				ent:Spawn()

				timer.Create("skicktimer4", .01, 1, function()
					if IsValid(ent) and push then
						ent:GetPhysicsObject():SetVelocity(push)
					end
				end)

				timer.Create("skicktimer5", .01, 1, function()
					if IsValid(ent) and push then
						ent:GetPhysicsObject():SetVelocity(push)
					end
				end)

				timer.Create("skicktimer6", 25, 1, function()
					if trace and IsValid(trace.Entity) and IsValid(ent) then
						ResetDoor(trace.Entity, ent)
					end
				end)
			end
		end
	end
end

function SWEP:SecondaryAttack()
	if CurTime() < self.NextStrike then return end

	self:EmitSound("player/skick/madness.mp3")

	self.NextStrike = CurTime() + 2.9
end

function SWEP:AttackAnim()
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
end
