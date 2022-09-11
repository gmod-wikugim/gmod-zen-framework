
nt.mt_StringNumbers_IDS = nt.mt_StringNumbers_IDS or {}

nt.mt_StringNumbers = nt.mt_StringNumbers or {}
nt.iStringNumbers_Counter = nt.iStringNumbers_Counter or 0

nt.mt_StringNumbersSingle = nt.mt_StringNumbersSingle or {}
nt.iStringNumbersSingle_Counter = nt.iStringNumbersSingle_Counter or 0

nt.mt_StringNumbersMulti = nt.mt_StringNumbersMulti or {}
nt.iStringNumbersMulti_Counter = nt.iStringNumbersMulti_Counter or 0

local _find = string.find
local _lower = string.lower

function nt.RegisterStringNumbers(word, new_id)
	if nt.mt_StringNumbers_IDS[word] then return nt.mt_StringNumbers_IDS[word].id end
    local lower_case = _lower(word)
    if nt.mt_StringNumbers_IDS[lower_case] then return nt.mt_StringNumbers_IDS[lower_case].id end


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

	nt.iStringNumbers_Counter = new_id or (nt.iStringNumbers_Counter + 1)
    local word_id = nt.iStringNumbers_Counter

	nt.mt_StringNumbers[word_id] = {
		word = lower_case,
        id = word_id,
	}
    local tWord = nt.mt_StringNumbers[word_id]

    nt.mt_StringNumbers_IDS[word] = tWord
    nt.mt_StringNumbers_IDS[lower_case] = tWord

	-- if of_count > 0 then
    --     nt.mt_StringNumbersMulti[word_id] = tWord
    --     nt.iStringNumbersMulti_Counter = nt.iStringNumbersMulti_Counter + 1

	-- 	tWord.content = of
	-- 	tWord.sep = true
	-- 	tWord.count = of_count
    --     if SERVER then
    --         nt.SendToChannel("string_id.multi_word", nil, word_id, tWord) -- TODO: Fix and return string_id.multi_word
    --     end
    -- else
        nt.mt_StringNumbersSingle[word_id] = tWord
        nt.iStringNumbersSingle_Counter = nt.iStringNumbersSingle_Counter + 1
        if SERVER then
            nt.SendToChannel("string_id.single_word", nil, word_id, lower_case)
        end
    -- end


	return word_id
end


nt.mt_listReader["string_id"] = function()
    local word_id = net.ReadUInt(12)
    local tWord = nt.mt_StringNumbers[word_id]
    if not tWord then
        MsgC(clr_red, "[NT-Predicted-Error] READ: Word id not exists: ", word_id, "\n")
        return
    end
    return tWord.word
end

nt.mt_listWriter["string_id"] = function(var)
    net.WriteUInt(nt.RegisterStringNumbers(var), 12)
end

nt.mt_listExtraTypes["string_id"] = "string"

nt.RegisterChannel("string_id.single_word", nt.t_ChannelFlags.PUBLIC, {
    id = 3,
    priority = 3,
    types = {"uint12", "string"},
    fPostReader = function(tChannel, word_id, word)
        if CLIENT then
            nt.RegisterStringNumbers(word, word_id)
        end
    end,
    fPullWriter = function(tChannel, _, ply)
        net.WriteUInt(nt.iStringNumbersSingle_Counter, 16)
        for word_id, tWord in pairs(nt.mt_StringNumbersSingle) do
            nt.Write(tChannel.types, {word_id, tWord.word})
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

/*
nt.RegisterChannel("string_id.multi_word", nt.t_ChannelFlags.PUBLIC, { -- TODO: Fix multi_word
    id = 4,
    priority = 4,
    fPostReader = function(tChannel, word_id, word)
        if CLIENT then
            nt.RegisterStringNumbers(word, word_id)
        end
    end,
    fWriter = function(tChannel, word_id, tWord)
        nt.Write({"uint12", "uint6"}, {word_id, tWord.count})
        for k, word_id in ipairs(tWord.content) do
            net.WriteUInt(word_id, 12)
        end
    end,
    fReader = function(tChannel)
        local word_id, iCounter = nt.Read({"uint12", "uint6"})
        local content = {}
        for k = 1, iCounter do
            local k_word_id = net.ReadUInt(12)
            local s_word = nt.mt_StringNumbersSingle[k_word_id]
            if not s_word then
                MsgC(clr_red, "[NT-Predicted-Error] multiword.fReader Single Word not exists: ", k_word_id, "\n")
                return
            end
            table.insert(content,  s_word)
        end

        local word = table.concat(content, ".")
        return word_id, word
    end,
    fPullWriter = function(tChannel, _, ply)
        net.WriteUInt(nt.iStringNumbersMulti_Counter, 16)
        for word_id, tWord in pairs(nt.mt_StringNumbersMulti) do
            tChannel.fWriter(tWord.id, tWord)
        end
    end,
    fPullReader = function(tChannel, tContent, tResult)
        tChannel.iCounter = net.ReadUInt(16)
        for k = 1, tChannel.iCounter do
            local k, v = tChannel.fReader()
            table.insert(tResult, { k, v })
        end
    end,
})
*/