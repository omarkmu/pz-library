/**
 * Information about a library module that can be toggled by consumers.
 */
export interface LibraryModule {
    /**
     * The Lua path to require as the definition of this module.
     * Mutually exclusive with `body`, which takes precedence.
     * Requires will have the form `LIB_NAME.MOD_NAME = require 'MOD_REQUIRE'`.
     */
    require?: string
    /**
     * The main content of the module definitions.
     * Mutually exclusive with and takes precedence over `require`.
     */
    body?: string[]
    /**
     * Content to insert on the line directly before the module body.
     */
    before?: string[]
    /**
     * Content to insert on the line directly after the module body.
     */
    after?: string[]
}

/**
 * Information about a library with content modules.
 */
export interface Library {
    /**
     * The name of the library.
     * This is used in default definitions.
     */
    name: string
    /**
     * The library path.
     * This is not included in library.json; it is added based on the provided path.
     */
    path: string
    /**
     * The library version.
     * This will be included as `LIB_NAME.VERSION = LIB_VERSION`.
     * If `definition` is specified, the version will not be automatically added.
     */
    version?: string
    /**
     * The directory in which Lua files will be discovered.
     * Defaults to the path of the library JSON file.
     */
    luaDirectory?: string[]
    /**
     * The path to the output Lua file relative to the library JSON file.
     * An output path provided as a command-line argument takes precedence over this.
     * Defaults to `bundle.lua` in the current directory.
     */
    outFile?: string[]
    /**
     * Default modules to include in the bundle when none are specified.
     */
    defaultModules?: string[]
    /**
     * Content to include at the top of the bundle file.
     */
    header?: string[]
    /**
     * The Lua definition of the library.
     * Defaults to `local LIB_NAME = {}`.
     */
    definition?: string[]
    /**
     * Content to insert on the line directly before the library definition.
     */
    before?: string[]
    /**
     * Content to insert on the line directly after the library definition.
     */
    after?: string[]
    /**
     * The Lua return line of the library.
     * Defaults to `return LIB_NAME`.
     */
    ['return']?: string[]
    /**
     * Mapping of module names to module definitions.
     */
    modules?: Record<string, LibraryModule>
}

/**
 * Arguments for library bundling.
 */
export interface BundleArgs {
    input: string
    all: boolean
    output?: string
    luaDirectory?: string
    modules?: string[]
}

/**
 * Contains information about an error that may have occurred due to user error.
 * Signals that only the message should be displayed rather than the default error traceback.
 */
export class ScriptError extends Error {
    constructor(message: string) {
        super(message)
        this.name = 'ScriptError'
    }
}
