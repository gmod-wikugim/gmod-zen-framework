module("zen", package.seeall)

tool.mt_Sandbox_Tools = tool.mt_Sandbox_Tools or {}

tool.mi_SandBoxToolCount = tool.mi_SandBoxToolCount or 0
---@param STOOL Tool
---@param class string
hook.Add("PreRegisterTOOL", "zen.map_edit.import", function(STOOL, class)
    tool.mt_Sandbox_Tools[class] = STOOL
    tool.mi_SandBoxToolCount = tool.mi_SandBoxToolCount + 1

    STOOL.sortID = tool.mi_SandBoxToolCount

    tool.ImportSandboxWeapon(STOOL,  class)
end)

---@param STOOL Tool
---@param class string
function tool.ImportSandboxWeapon(STOOL, class)
    ---@class zen_TOOL
    local TOOL = {}
    TOOL.id = class
    TOOL.Name = STOOL.Name or class
    TOOL.Icon = STOOL.Icon
    TOOL.Category = STOOL.Category or "SandBox"
    TOOL.IsSandBoxTool = true
    TOOL.STOOL = STOOL
    TOOL.sortID = STOOL.sortID or 0

    function TOOL:DoLeftClick(tr, who)
        local Click = self.STOOL.LeftClick
        if Click then
            if SERVER then
                local STOOL = tool.GetPlayerSTOOL(who, class)

                local old_eye_pos = META.PLAYER.EyePos
                local old_eye_angles = META.PLAYER.EyeAngles
                META.PLAYER.EyePos = function() return tr.EyePos end
                META.PLAYER.EyeAngles = function() return tr.Normal:Angle() end
                    xpcall(STOOL.LeftClick, ErrorNoHaltWithStack, STOOL, tr)
                META.PLAYER.EyePos = old_eye_pos
                META.PLAYER.EyeAngles = old_eye_angles
                else
                Click(self.STOOL, tr)
            end
        end
    end

    function TOOL:DoRightClick(tr, who)
        local Click = self.STOOL.RightClick
        if Click then
            if SERVER then
                local STOOL = tool.GetPlayerSTOOL(who, class)
                STOOL:RightClick(tr)
            else
                Click(self.STOOL, tr)
            end
        end
    end

    function TOOL:DoReload(tr, who)
        local Click = self.STOOL.Reload
        if Click then
            if SERVER then
                local STOOL = tool.GetPlayerSTOOL(who, class)
                STOOL:Reload(tr)
            else
                Click(self.STOOL, tr)
            end
        end
    end



    if CLIENT then
        if STOOL.DrawHUD then
            TOOL.Render = function (self, rendermode, priority, vw)
                self.STOOL:DrawHUD()
            end

        end
        TOOL.OnButtonPress = function (self, but, inkey, bind_name)
            if vgui.CursorVisible() then return end

            if inkey == IN_ATTACK then
                if STOOL.LeftClick then
                    local tr = map_edit.GetViewTrace()
                    self:DoLeftClick()
                    self:CallServerAction{
                        action = "left_click",
                        tr = tr
                    }
                end
            end

            if inkey == IN_ATTACK2 then
                if STOOL.RightClick then
                    local tr = map_edit.GetViewTrace()
                    self:DoRightClick()
                    self:CallServerAction{
                        action = "right_click",
                        tr = tr
                    }
                end
            end

            if inkey == IN_RELOAD then
                if STOOL.Reload then
                    local tr = map_edit.GetViewTrace()
                    self:DoReload()
                    self:CallServerAction{
                        action = "reload",
                        tr = tr
                    }
                end
            end
        end
    end

    if SERVER then
        TOOL.ServerAction = function(self, data, who)
            local action = data.action
            if !action then return end

            if action == "left_click"then
                self:DoLeftClick(data.tr, who)
            end

            if action == "right_click" then
                self:DoRightClick(data.tr, who)
            end

            if action == "reload" then
                self:DoReload(data.tr, who)
            end

        end
    end

    tool.Register(TOOL)
end

for class, STOOL in pairs(tool.mt_Sandbox_Tools) do
    tool.ImportSandboxWeapon(STOOL, class)
end