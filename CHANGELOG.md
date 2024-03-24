# 2.0.2
- Removed `@enum` and `@generic` annotations

# 2.0.1
- Fixed incorrect behavior in `utils.escape`

# 2.0.0
- Improved `omi.fmt.Parser`
    - Added `match`, `perform`, and `createTree` methods
    - Parse trees will have no type by default
    - The `postprocess` method will now be called at the end of `parse`
    - `errors` and `warnings` fields will not be added to trees by default
    - `_errors` and `_warnings` fields are now required
    - Renamed `error` field to `message` in warning and error records
    - Renamed `_treeNodeName` field to `_treeNodeType`
    - Removed `Errors` table
- Improved `omi.interpolate.Parser`
    - `parse` will now return a result object
    - Removed `Errors` table
- Added support for a custom `exit` function in `test.run`
- Removed `VERSION` field (to make automatically pulling in relevant changes easier)
- Renamed `omi.Sandbox` to `omi.SandboxHelper` for clarity
- Fixed error printing format for test failures with no associated function name

# 1.2.2
- Fixed incorrect behavior in `utils.trimleft`

# 1.2.1
- Fixed dependency on `next` function in json encode

# 1.2.0
- Added json functions to utils module

# 1.1.0
- Added support for character entities in format strings
- Added `get` and `has` at-map format string functions

# 1.0.0
- Initial release
