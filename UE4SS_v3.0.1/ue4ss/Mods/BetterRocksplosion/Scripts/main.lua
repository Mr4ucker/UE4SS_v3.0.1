---@diagnostic disable: undefined-global

-- LoopRocksplosion
-- Restaura a versao base do mod:
-- aumenta o raio da explosao e remove o cooldown.

local MOD_NAME = "[BetterRocksplosion] "
local RADIUS = 650.0
local SPELL_ASSET = "/Game/Gameplay/UtilityMagic/PerkSpells/Rocksplosion/USD_Rocksplosion.USD_Rocksplosion"

local function Log(message)
    print(MOD_NAME .. message)
end

local function ApplyRocksplosionCooldown()
    local spell = StaticFindObject(SPELL_ASSET)
    if not spell or not spell:IsValid() then
        Log("Spell nao encontrada: " .. SPELL_ASSET)
        return
    end

    spell:SetPropertyValue("CooldownDuration", 0)
    Log("Cooldown aplicado: " .. tostring(spell:GetPropertyValue("CooldownDuration")))
end

local function ApplyRocksplosionRadius(sphere)
    if not sphere or not sphere:IsValid() then
        return
    end

    sphere:SetPropertyValue("Radius", RADIUS)
    Log("Radius aplicado: " .. tostring(sphere:GetPropertyValue("Radius")))
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    ExecuteInGameThread(function()
        ApplyRocksplosionCooldown()
    end)
end)

NotifyOnNewObject("/Script/Dominion.DominionShape_Sphere", function(sphere)
    if not sphere:IsValid() then
        return
    end

    local full_name = sphere:GetFullName()
    if full_name:find("BP_Magic_Rocksplosion") and full_name:find("DelayedDamageInfliction") then
        ExecuteInGameThread(function()
            ApplyRocksplosionRadius(sphere)
        end)
    end
end)

Log("Mod restaurado. Radius: " .. tostring(RADIUS))
