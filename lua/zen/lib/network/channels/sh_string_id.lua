
nt.mt_StringNumbers_IDS = nt.mt_StringNumbers_IDS or {}

nt.mt_StringNumbers = nt.mt_StringNumbers or {}
nt.iStringNumbers_Counter = nt.iStringNumbers_Counter or 0

nt.mt_StringNumbersSingle = nt.mt_StringNumbersSingle or {}

nt.mt_StringNumbersMulti = nt.mt_StringNumbersMulti or {}

local _find = string.find
local _lower = string.lower

function nt.RegisterStringNumbers(word, new_id)
	if nt.mt_StringNumbers_IDS[word] and (not new_id or nt.mt_StringNumbers_IDS[word].id == new_id) then return nt.mt_StringNumbers_IDS[word].id end

    new_id = new_id or (nt.mt_StringNumbers_IDS[word] and nt.mt_StringNumbers_IDS[word].id)


	local of = {}
	local of_count = 0
	if _find(word, ".", nil, true) then
		local tbl = string.Split(word, ".")
		for k, v in ipairs(tbl) do
			of_count = of_count + 1
			local new_id = nt.RegisterStringNumbers(v)
			table.insert(of, new_id)
		end
	end

    if CLIENT and new_id == nil then
        error("Client can't to register string_id with auto_id")
    end

	nt.iStringNumbers_Counter = new_id or (nt.iStringNumbers_Counter + 1)
    local word_id = nt.iStringNumbers_Counter

	nt.mt_StringNumbers[word_id] = {
		word = word,
        id = word_id,
	}
    local tWord = nt.mt_StringNumbers[word_id]

    nt.mt_StringNumbers_IDS[word] = tWord

	if of_count == 0 then
        nt.mt_StringNumbersSingle[word_id] = tWord
        if SERVER then
            nt.SendToChannel("string_id.single_word", nil, word_id, word)
        end
    elseif of_count > 0 then
        nt.mt_StringNumbersMulti[word_id] = tWord

		tWord.content = of
		tWord.sep = true
		tWord.count = of_count
        if SERVER then
            nt.SendToChannel("string_id.multi_word", nil, word_id, tWord.content) -- TODO: Fix and return string_id.multi_word
        end
    end


	return word_id
end


nt.mt_listReader["string_id"] = function()
    local word_id = net.ReadUInt(16)
    local tWord = nt.mt_StringNumbers[word_id]
    if not tWord then
        MsgC(clr_red, "[NT-Predicted-Error] READ: Word id not exists: ", word_id, "\n")
        return
    end
    return tWord.word
end

nt.mt_listWriter["string_id"] = function(var)
    net.WriteUInt(nt.RegisterStringNumbers(var), 16)
end

util.RegisterTypeConvert("string_id", TYPE.STRING)

nt.RegisterChannel("string_id.single_word", nt.t_ChannelFlags.PUBLIC, {
    id = 3,
    priority = 3,
    types = {"uint16", "string"},
    fPostReader = function(tChannel, word_id, word)
        if CLIENT then
            nt.RegisterStringNumbers(word, word_id)
        end
    end,
    fPullWriter = function(tChannel, _, ply)
        net.WriteUInt(table.Count(nt.mt_StringNumbersSingle), 16)
        for word_id, tWord in pairs(nt.mt_StringNumbersSingle) do
            nt.Write(tChannel.types, {tWord.id, tWord.word})
        end
    end,
    fPullReader = function(tChannel, tContent, tResult)
        tChannel.iCounter = net.ReadUInt(16)
        for k = 1, tChannel.iCounter do
            local k, v = nt.Read(tChannel.types)
            table.insert(tResult, { k, v })
        end
    end,
})


nt.RegisterChannel("string_id.multi_word", nt.t_ChannelFlags.PUBLIC, { -- TODO: Fix multi_word
    id = 4,
    priority = 4,
    types = {"uint16", "array:uint16"},
    fPostReader = function(tChannel, word_id, tWordArray)
        if CLIENT then
            local full_word = {}
            for k, id in pairs(tWordArray) do
                table.insert(full_word, nt.mt_StringNumbersSingle[id].word)
            end
            local word = table.concat(full_word, ".")
            nt.RegisterStringNumbers(word, word_id)
        end
    end,
    fPullWriter = function(tChannel, _, ply)
        net.WriteUInt(table.Count(nt.mt_StringNumbersMulti), 16)
        for word_id, tWord in pairs(nt.mt_StringNumbersMulti) do
            nt.Write(tChannel.types, {word_id, tWord.content})
        end
    end,
    fPullReader = function(tChannel, tContent, tResult)
        tChannel.iCounter = net.ReadUInt(16)
        for k = 1, tChannel.iCounter do
            local k, v = nt.Read(tChannel.types)
            table.insert(tResult, { k, v })
        end
    end,
})