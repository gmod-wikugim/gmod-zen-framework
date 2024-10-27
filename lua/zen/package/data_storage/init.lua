local package = {}

package.PACKAGE_NAME = "data_storage"
package.PACKAGE_VERSION = "0.0.1"

---@param name string
function package.new(name)
    local copy = {}

    copy.PACKAGE_NAME = package.PACKAGE_NAME .. "." .. name
    copy.PACKAGE_VERSION = package.PACKAGE_VERSION

    return copy
end


return package