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

	resource.AddFile("materials/vgui/ttt/icon_skick.vmt")
end

if CLIENT then
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false

	SWEP.EquipMenuData = {
		type = "item_weapon",
		name = "name_spartan_kick",
		desc = "desc_spartan_kick"
	}

	SWEP.Icon = "vgui/ttt/icon_skick"
end

SWEP.Base = "weapon_tttbase"

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

SWEP.Primary.Delay = 0.4
SWEP.Primary.Recoil = 0
SWEP.Primary.Damage = 15
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

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

local soundHit = {
	Sound("player/skick/foot_kickwall.wav")
}

local soundHitFlesh = {
	Sound("player/skick/kick1.wav"),
	Sound("player/skick/kick2.wav"),
	Sound("player/skick/kick3.wav"),
	Sound("player/skick/kick4.wav"),
	Sound("player/skick/kick5.wav"),
	Sound("player/skick/kick6.wav")
}

local function ResetWeaponTimer()
	local plys = player.GetAll()

	for i = 1, #plys do
		local ply = plys[i]

		timer.Remove("skick_animation_" .. ply:SteamID64())
		timer.Remove("skick_animation_idle_" .. ply:SteamID64())
		timer.Remove("skick_attack_" .. ply:SteamID64())
	end
end

function SWEP:Initialize()
	if CLIENT then
		self:AddHUDHelp("skick_help_msb1", "skick_help_msb2", true)
	else
		self:SetWeaponHoldType("normal")
	end
end

function SWEP:Precache()

end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_IDLE)

	-- store owner in extra variable because the owner isn't valid
	-- once OnDrop is called
	self.notfiyOwner = self:GetOwner()

	return true
end

if SERVER then
	util.AddNetworkString("SKickResetClientTimer")

	function SWEP:Holster(wep)
		ResetWeaponTimer()

		net.Start("SKickResetClientTimer")
		net.Send(self.notfiyOwner)

		self.notfiyOwner = nil

		return self.BaseClass.Holster(self, wep)
	end

	function SWEP:OnDrop()
		ResetWeaponTimer()

		net.Start("SKickResetClientTimer")
		net.Send(self.notfiyOwner)

		self.notfiyOwner = nil

		self.BaseClass.OnDrop(self)
	end
end

if CLIENT then
	net.Receive("SKickResetClientTimer", function()
		ResetWeaponTimer()
	end)
end

function SWEP:PrimaryAttack()
	if CurTime() < self.NextStrike then return end

	self:EmitSound("player/skick/sparta.mp3")
	self.NextStrike = CurTime() + 3.5

	local owner = self:GetOwner()

	owner:SetAnimation(PLAYER_ATTACK1)

	timer.Create("skick_animation_" .. owner:SteamID64(), 1.80, 1, function()
		if not IsValid(self) then return end

		self.AttackAnim(self)
	end)

	timer.Create("skick_animation_idle_" .. owner:SteamID64(), 2.40, 1, function()
		if not IsValid(self) then return end

		self:SendWeaponAnim(ACT_VM_IDLE)
	end)

	timer.Create("skick_attack_" .. owner:SteamID64(), 2.0, 1, function()
		if not IsValid(self) then return end

		self.ShootBullets(self)
	end)
end

local kickedPlys = {}

hook.Add("TTTPrepareRound", "SpartanKickEnd", function()
	ResetWeaponTimer()

	kickedPlys = {}
end)

if SERVER then
	hook.Add("TTT2ModifyRagdollVelocity", "TTT2FixSpartanKickVelocity", function(ply, rag, v)
		for i = 1, #kickedPlys do
			if kickedPlys[i] ~= ply then continue end

			table.remove(kickedPlys, i)

			v:Mul(5)
		end
	end)
end

function SWEP:ShootBullets()
	local owner = self:GetOwner()

	if not IsValid(owner) then return end

	self:EmitSound("player/skick/foot_swing.wav")

	local trace = owner:GetEyeTrace()
	local ent = trace.Entity

	if trace.HitPos:Distance(owner:GetShootPos()) > 130 then return end

	if SERVER and ent:IsPlayer() or ent:IsNPC() then
		kickedPlys[#kickedPlys + 1] = ent
	end

	local bullet = {}
	bullet.Num = 5
	bullet.Src = owner:GetShootPos()
	bullet.Dir = owner:GetAimVector()
	bullet.Spread = Vector(0.04, 0.04, 0.04)
	bullet.Tracer = 0
	bullet.Force = 450
	bullet.Damage = 1000000

	owner:FireBullets(bullet)

	if not IsValid(ent) then return end

	if ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll" then
		owner:EmitSound(soundHitFlesh[math.random(1, #soundHitFlesh)])
	else
		owner:EmitSound(soundHit[math.random(1, #soundHit)])

		if CLIENT then return end

		if not door.IsValidNormal(ent:GetClass()) then return end

		if ent:IsDoorLocked() and not ent:DoorIsDestructible() then
			LANG.Msg(owner, "skick_door_locked_indestructible", nil, MSG_MSTACK_WARN)

			return
		end

		local norm = pos - owner:GetPos()
		norm:Normalize()

		local smoke = EffectData()
		smoke:SetOrigin(ent:GetPos())

		util.Effect("effect_smokedoor", smoke)

		ent:SafeDestroyDoor(owner, 1000 * norm)
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
