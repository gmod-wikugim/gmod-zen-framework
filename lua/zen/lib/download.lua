-- Library which download files from internet
-- Repeat 3 times if failed, each 5 seconds
-- Check to good code result 200

---@class zen.download
download = _GET("download")

-- Get URL with retries
---@param url string
---@param callback fun(body:string?)
function download.GetURL(url, callback)
    local attempts = 0
    local max_attempts = 3
    local delay_between_attempts = 5

    local function tryFetch()
        attempts = attempts + 1

        http.Fetch(url,
            function(body, len, headers, code)
                if code == 200 then
                    callback(body)
                else
                    if attempts < max_attempts then
                        timer.Simple(delay_between_attempts, tryFetch)
                    else
                        callback(nil)
                    end
                end
            end,
            function(error)
                if attempts < max_attempts then
                    timer.Simple(delay_between_attempts, tryFetch)
                else
                    callback(nil)
                end
            end
        )
    end

    tryFetch()
end

-- Get URL with saving to file and cache time
---@param url string
---@param filepath string? Use util.SHA256 if nil
---@param cache_time number seconds
---@param callback fun(success:boolean, fullpath:string?)
function download.GetURLToFile(url, filepath, cache_time, callback)
    filepath = filepath or ("download/" .. util.SHA256(url) .. ".dat")
    local fullpath = string.lower("data/" .. filepath)

    -- Check if file exists and is fresh
    if file.Exists(filepath, "DATA") then
        local file_time = file.Time(filepath, "DATA")
        if os.time() - file_time < cache_time then
            callback(true, fullpath)
            return
        end
    end

    download.GetURL(url, function(body)
        if body then
            file.CreateDir(string.GetPathFromFilename(filepath))
            local bSuccess = file.Write(filepath, body)
            if not bSuccess then
                print("Failed to write downloaded file to " .. fullpath)
                callback(false, nil)
                return
            end
            callback(true, fullpath)
        else
            callback(false, nil)
        end
    end)
end





