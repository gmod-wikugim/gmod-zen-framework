ENT.Type = "anim"
ENT.Base = "base_entity"


function ENT:Initialize()
    local vertices = self.vertices

    self:SetKeyValue("classname", "zen_zone")

    if SERVER then
        self:SetUseType(SIMPLE_USE)
    end

    self:SetNoDraw(true)
    self:PhysicsInitConvex( vertices )

    local phys = self:GetPhysicsObject()
    if (phys:IsValid()) then
        phys:EnableMotion(false)
        phys:EnableDrag(false)
    end

    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid( SOLID_VPHYSICS	 )

    self:SetSolidFlags( FSOLID_CUSTOMRAYTEST + FSOLID_CUSTOMBOXTEST )

    self.m_bCustomCollisions = true

    self:EnableCustomCollisions(true);
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:CollisionRulesChanged()
end