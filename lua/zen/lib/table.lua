module("zen", package.seeall)

table = _GET("table", table)


function table.AddI(dest, source, index)
	if ( dest == source ) then return dest end

	-- At least one of them needs to be a table or this whole thing will fall on its ass
	if ( !istable( source ) ) then return dest end
	if ( !istable( dest ) ) then dest = {} end

    local index_offset = 0
	for k, v in pairs( source ) do
        if index then
		    table.insert( dest, index + index_offset, v )
            index_offset = index_offset + 1
        else
		    table.insert( dest, v )
        end
	end

	return dest
end