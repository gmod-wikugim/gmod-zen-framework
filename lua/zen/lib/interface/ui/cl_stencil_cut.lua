module("zen")

---@class zen.stencil_cut
stencil_cut = _GET("stencil_cut")

-- Cache render functions
local render_SetStencilEnable = render.SetStencilEnable
local render_ClearStencil = render.ClearStencil
local render_SetStencilTestMask = render.SetStencilTestMask
local render_SetStencilWriteMask = render.SetStencilWriteMask
local render_SetStencilPassOperation = render.SetStencilPassOperation
local render_SetStencilZFailOperation = render.SetStencilZFailOperation
local render_SetStencilCompareFunction = render.SetStencilCompareFunction
local render_SetStencilReferenceValue = render.SetStencilReferenceValue
local render_SetStencilFailOperation = render.SetStencilFailOperation

-- Stencil Box Cut Operation
function stencil_cut.StartStencil()
    -- If you'd like to see the mask layer, you can comment this line out
    render_SetStencilEnable(true)

    -- First, let's configure the parts of the Stencil system we aren't using right now so we know they
    -- won't affect what we're doing
    ------ Make sure we're starting with a Stencil Buffer where all pixels have a Stencil value of 0
    render_ClearStencil()

    ------ 255 corresponds to 8 bits (1 byte) where all bits are 1 (11111111), which is a bitmask that won't
    ------ change anything
    render_SetStencilTestMask(255)
    render_SetStencilWriteMask(255)

    ------ If a pixel fully passes, or if it fails the depth test, don't modify its Stencil Buffer value
    ------ (KEEP the current value)
    render_SetStencilPassOperation(STENCILOPERATION_KEEP)
    render_SetStencilZFailOperation(STENCILOPERATION_KEEP)

    -- Now, let's configure the parts of the Stencil system we are going to use
    ------ We're creating a mask, so we don't want anything we do right now to draw onto the screen
    ------ All pixels should fail the Compare Function (They should NEVER pass)
    render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)

    ------ When a pixel fails, which they all should, we want to REPLACE their current Stencil value with
    ------ whatever the Reference Value is
    ------ We can use whatever Reference Value we want for this; They have no special meaning.
    render_SetStencilReferenceValue(9)
    render_SetStencilFailOperation(STENCILOPERATION_REPLACE)
end
local stencil_cut_StartStencil = stencil_cut.StartStencil

-- Stencil Box Cut Operation
function stencil_cut.EndStencil()
    render_ClearStencil()
    -- Return original values
    render_SetStencilPassOperation(STENCILOPERATION_KEEP)
    render_SetStencilZFailOperation(STENCILOPERATION_KEEP)
    render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
    render_SetStencilReferenceValue(0)
    render_SetStencilFailOperation(STENCILOPERATION_KEEP)

    render_SetStencilEnable(false)
end
local stencil_cut_EndStencil = stencil_cut.EndStencil

-- Stencil Box Cut Operation
---@param callback fun(width: number, height: number)
---@param width number
---@param height number
function stencil_cut.FilterStencil(callback, width, height)
    callback(width, height)

    render_SetStencilFailOperation(STENCILOPERATION_KEEP)

    ------ We want to pass (and therefore draw on) pixels that match (Are EQUAL to) the Reference Value
    render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
end

---@param draw_func fun()
---@param mask_func fun()
function stencil_cut.DrawWithSimpleMask(draw_func, mask_func)
    stencil_cut_StartStencil()

    mask_func()

    render_SetStencilFailOperation(STENCILOPERATION_KEEP)

    ------ We want to pass (and therefore draw on) pixels that match (Are EQUAL to) the Reference Value
    render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)

    draw_func()

    stencil_cut_EndStencil()
end