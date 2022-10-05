include("shared.lua")

function ENT:Draw()
end

function ENT:Think()
    local physobj = self:GetPhysicsObject()

    if ( IsValid( physobj ) ) then

        physobj:SetPos( self:GetPos() )

        physobj:SetAngles( self:GetAngles() )

        physobj:EnableMotion( false )

        physobj:Sleep()

    end
end