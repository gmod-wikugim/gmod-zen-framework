module("zen", package.seeall)

---@class zen.stencil_cut
stencil_cut = _GET("stencil_cut")

-- Stencil Box Cut Operation
function stencil_cut.StartStencil()
    -- If you'd like to see the mask layer, you can comment this line out
    render.SetStencilEnable( true )

    -- First, let's configure the parts of the Stencil system we aren't using right now so we know they
    -- won't affect what we're doing
    ------ Make sure we're starting with a Stencil Buffer where all pixels have a Stencil value of 0
    render.ClearStencil()

    ------ 255 corresponds to 8 bits (1 byte) where all bits are 1 (11111111), which is a bitmask that won't
    ------ change anything
    render.SetStencilTestMask( 255 )
    render.SetStencilWriteMask( 255 )

    ------ If a pixel fully passes, or if it fails the depth test, don't modify its Stencil Buffer value
    ------ (KEEP the current value)
    render.SetStencilPassOperation( STENCILOPERATION_KEEP )
    render.SetStencilZFailOperation( STENCILOPERATION_KEEP )

    -- Now, let's confiure the parts of the Stencil system we are going to use
    ------ We're creating a mask, so we don't want anything we do right now to draw onto the screen
    ------ All pixels should fail the Compare Function (They should NEVER pass)
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )

    ------ When a pixel fails, which they all should, we want to REPLACE their current Stencil value with
    ------ whatever the Reference Value is
    ------ We can use whatever Reference Value we want for this; They have no special meaning.
    render.SetStencilReferenceValue( 9 )
    render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
end

-- Stencil Box Cut Operation
function stencil_cut.EndStencil()
    render.ClearStencil()
    -- Return original values
    render.SetStencilPassOperation( STENCILOPERATION_KEEP )
    render.SetStencilZFailOperation( STENCILOPERATION_KEEP )
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
    render.SetStencilReferenceValue( 0 )
    render.SetStencilFailOperation( STENCILOPERATION_KEEP )

    render.SetStencilEnable( false )
end

-- Stencil Box Cut Operation
---@param callback fun(width: number, height: number)
---@param width number
---@param height number
function stencil_cut.FilterStencil(callback, width, height)
    callback(width, height)

    render.SetStencilFailOperation( STENCILOPERATION_KEEP )

    ------ We want to pass (and therefore draw on) pixels that match (Are EQUAL to) the Reference Value
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )

end