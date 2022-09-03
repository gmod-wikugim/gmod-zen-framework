iperm.RegisterPermission("gm.no_hunger", iperm.flags.NO_TARGET, "Access to remove hunger")
iperm.RegisterPermission("gm.anti_cuff", iperm.flags.NO_TARGET, "Access to easy cuff")
iperm.RegisterPermission("gm.many_ammo", iperm.flags.NO_TARGET, "Give you a lot of money after weapon reselect!")
iperm.RegisterPermission("gm.good_med_kit", iperm.flags.NO_TARGET, "Level up your med_kit!")
iperm.RegisterPermission("gm.ultimate_keys", iperm.flags.NO_TARGET, "Allow your keys access to open all doors!")


hook.Add("PlayerHasHunger", "zen.integration", function(ply)
    if ply:izen_HasPerm("gm.no_hunger") then return false end
end)

hook.Add("OnHandcuffed", "zen.integration", function(who, target, cuff)
    if SERVER then
        print("On Cuffed")
        cuff.Reload = function(self)
            local victim = self.Owner:GetEyeTrace().Entity
            if not IsValid(victim) or not victim:IsPlayer() then return end

            local cuff = victim:Give( "weapon_handcuffed" )
            if not IsValid(cuff) then return end

            cuff:SetCuffStrength( 2 )
            cuff:SetCuffRegen( 2 )

            cuff:SetCuffMaterial( "models/props_lab/warp_sheet" )
            cuff:SetRopeMaterial( "models/props_lab/warp_sheet" )

            cuff:SetKidnapper( self.Owner )
            cuff:SetRopeLength( 100 )

            cuff:SetCanBlind( true )
            cuff:SetCanGag( true )

            cuff.CuffType = ""

            self:Uncuff()
        end
        cuff.SecondaryAttack = function(self)
            self:Uncuff()
        end
    end
end)

hook.Add("PlayerSwitchWeapon", "zen.integration", function (ply, old, new)
    if not IsValid(new) then return end

    if ply:izen_HasPerm("gm.anti_cuffs") then
        if SERVER then
            if new:GetClass() == "weapon_handcuffed" then
                timer.Simple(0, function()
                    if new.SetCuffStrength then
                        new:SetCuffStrength(0)
                        new:SetCanGag(false)
                        new:SetCanBlind(false)
                    end
                end)
            end
        end
    end

    if ply:izen_HasPerm("gm.many_ammo") then
        if SERVER then
            local ammo1 = new:GetPrimaryAmmoType()
            local clip1 = new:GetMaxClip1()
            if ammo1 != -1 and clip1 > 0 then
                ply:SetAmmo(clip1 * 999, ammo1)
            end

            local ammo2 = new:GetSecondaryAmmoType()
            local clip2 = new:GetMaxClip2()
            if ammo2 != -1 and clip2 > 0 then
                ply:SetAmmo(clip2 * 999, ammo1)
            end
        end
    end

    if ply:izen_HasPerm("gm.many_snowballs") then
        if SERVER then
            if new.SetSnowballCount then
                new:SetSnowballCount(999999)
            end
        end
    end

    if ply:izen_HasPerm("gm.good_med_kit") then
        if new:GetClass() == "med_kit" then
            new.Heal = 25
            new.Primary.Delay = 0.02
            new.Secondary.Delay = 0.02
        end
    end

    if ply:izen_HasPerm("gm.ultimate_keys") and rp and rp.properties and rp.notify then
        if new:GetClass() == "keys" then
            function new:PrimaryAttack()
                self:SetNextPrimaryFire( CurTime() + 0.5 )
                self:SetNextSecondaryFire( CurTime() + 0.5 )
                if SERVER then
                    self.Owner:LagCompensation(true)
                    local ent = self.Owner:GetEyeTrace().Entity
                    self.Owner:LagCompensation(false)

                    if not ent or not util.IsDoor(ent) then
                        return
                    end

                    if self.Owner:GetPos():DistToSqr(ent:GetPos()) > 10000 then
                        return
                    end

                    if util.IsDoor(ent) then
                        rp.properties.close_door(ent)

                        rp.notify(self.Owner, 0, 4, "Вы закрыли дверь!")
                        ent:EmitSound( "npc/metropolice/gear".. math.random(1, 6) ..".wav" )
                    elseif ent.FadingDoor then
                        ent:UnFade()
                    end
                end
            end

            function new:SecondaryAttack()
                self:SetNextPrimaryFire( CurTime() + 0.5 )
                self:SetNextSecondaryFire( CurTime() + 0.5 )
                if SERVER then
                    self.Owner:LagCompensation(true)
                    local ent = self.Owner:GetEyeTrace().Entity
                    self.Owner:LagCompensation(false)

                    if not ent then
                        return false
                    end


                    if util.IsDoor(ent) then

                        if self.Owner:GetPos():DistToSqr(ent:GetPos()) > 10000 then
                            return
                        end

                        rp.properties.open_door(ent)

                        rp.notify(self.Owner, 0, 4, "Вы открыли дверь!")
                        ent:EmitSound( "npc/metropolice/gear".. math.random(1, 6) ..".wav" )
                    elseif ent.FadingDoor then
                        ent:Fade()
                        timer.Simple(2, function()
                            if not IsValid(ent) then return end
                            ent:UnFade()

                        end)
                    end
                end
            end
        end
    end
end)

hook.Add("CanKnockoutPlayer", "zen.integration", function(ply)
    if ply:izen_HasPerm("zen.AntiKnockout") then return false end
end)

icmd.registerCommand("respawn", {}, function(ply)
    if ply:Alive() then ply:KillSilint() end

    ply:Spawn()

    return true, "You was respawned"
end)

icmd.registerCommand("alive", {}, function(ply)
    if ply:Alive() then return false, "You already alive!" end

    local pos = ply:GetPos()
    ply:Spawn()
    timer.Simple(0, function()
        ply:SetPos(pos)
    end)

    return true, "You was respawned"
end)

icmd.registerCommand("money", {}, function(ply, cmd, args)
    local money = ply:GetMoney()
    local new_money = tonumber(args[1])

    if new_money or money == math.huge then
        local new_money = new_money or 10000
        ply:SetMoney(new_money)
        return true, string.Interpolate("Your money now: ${n:1}", {new_money})
    else
        ply:SetMoney(math.huge)
        return true, "Yoru money now: infinity :D"
    end
end)

icmd.registerCommand("afk", {}, function(ply)
    local isAfk = ply.eZenAFKdoll != nil

    if isAfk then
        if IsValid(ply.eZenAFKdoll) then ply.eZenAFKdoll:Remove() end
        ply.eZenAFKdoll = nil
        local pos = ply:GetPos()
        ply:UnSpectate()
        ply:Spawn()

        ply:SetHealth(999)
        ply:SetArmor(999)
        ply:GodDisable()
        ply:SetNoTarget(false)

        timer.Simple(0, function()
            ply:SetPos(pos)
        end)

        return true, "You disable AFK mode"
    else
        ply.eZenAFKdoll = ents.Create("prop_physics")
        local doll = ply.eZenAFKdoll

        local ang = ply:GetAngles()
        ang.p = 0
		ang.r = 0

        local pos = ply:GetPos()
        local veh = ply:GetVehicle()

        if IsValid(veh) then
            pos = veh:GetPos()
        end

        ply:ExitVehicle()
        ply:Extinguish()
        ply:StripWeapons()

        doll:SetModel("models/maxofs2d/companion_doll.mdl")
        doll:SetPos(pos)
        doll:SetAngles(ang)
        doll:PhysicsInit(SOLID_VPHYSICS)
        doll.pp_world = true
        doll:Spawn()
        doll:Activate()

        hook.Add("zen.worldclick.onPress", doll, function(self, fply, code, tr)
            if fply != ply then return end

            if code != MOUSE_LEFT then return end
            if not ply:KeyDown(IN_JUMP) then return end
            -- if IsValid(tr.Entity) then return end

            local ang = tr.Normal:Angle()
            ang.p = 0
            ang.r = 0

            doll:SetPos(tr.HitPos)
            doll:SetAngles(ang)
        end)

        ply:DeleteOnRemove(doll)

        local physobj = doll:GetPhysicsObject()
        if IsValid(physobj) then
            physobj:EnableMotion(false)
            physobj:Sleep()
        end


        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(doll)

        doll:zen_SetVar("3d2d.name", ply:Nick())
        doll:zen_SetVar("3d2d.name.color", COLOR.RED)
        doll:zen_SetVar("rp.outlines.color", COLOR.RED)

        ply:SetHealth(999)
        ply:SetArmor(999)
        ply:GodEnable(true)
        ply:SetNoTarget(true)

        return true, "You enable AFK mode"
    end
end)

local cant_target = "${ply:1} сейчас находится в принудительном афк режиме!\nВы можете написать ему в PM через чат!"

hook.Add("fl.RestrictTarget", "zen.afkBlock", function(ply, victim, command, args)
    if victim.eZenAFKdoll == nil then return end

    return false, string.Interpolate(cant_target, {victim})
end)

hook.Add("fl.RestrictTargetSID", "zen.afkBlock", function(ply, sid, command, args)
    local victim = util.GetPlayerEntity(sid)
    if not IsValid(victim) then return end
    if victim.eZenAFKdoll == nil then return end

    return false, string.Interpolate(cant_target, {ply})
end)

hook.Add("fl.Printer.OverUpgrade", "zen.Interpolate", function(ply, printer, upgrade, next_level)
    if ply:izen_HasPerm("zen.Printer.OverUpgrade") then return true end
end)