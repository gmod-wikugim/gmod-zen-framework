-- Library use http://ip-api.com/json/24.48.0.1 to get geoip info

---@class zen.geoip
geoip = _GET("geoip")

---@class zen.geoip.Data
---@field status string
---@field country string 
---@field countryCode string
---@field region string
---@field regionName string
---@field city string
---@field zip string
---@field lat number
---@field lon number
---@field timezone string
---@field isp string
---@field org string
---@field as string
---@field query string


---@param ip string
---@param callback fun(data:zen.geoip.Data?)
function geoip.GetInfo(ip, callback)
    http.Fetch("http://ip-api.com/json/" .. ip,
        function(body, len, headers, code)
            local data = util.JSONToTable(body)
            if data then
                if data.status == "success" then
                    callback(data)
                else
                    callback(nil)
                end
            else
                callback(nil)
            end
        end,
        function(error)
            callback(nil)
        end
    )
end