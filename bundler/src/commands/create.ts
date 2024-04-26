import path from 'path'
import ast from 'luaparse'
import luabundle from 'luabundle'
import { BundleArgs, Library, ScriptError } from '../types.ts'
import { chdir, isDirectory, readFile, writeFile } from '../utils.ts'


const luaIdentRegex = /^[_a-zA-Z][_\w]*$/


/**
 * Wraps the input in a Lua string, escaping the quote character as needed.
 * @param input The input string.
 * @returns The input string wrapped with single quotes.
 */
const luaString = (input: string) => `'${input.replace(/'/g, "\\'")}'`

/**
 * Generates the Lua source for a library root.
 * @param library The library definition.
 * @param modules An allowlist of module names.
 * @returns Generated Lua source.
 */
const buildRoot = (library: Library, modules: string[]) => {
    const result = []

    if (library.before) {
        result.push(...library.before)
    }

    if (library.definition !== undefined) {
        result.push(...library.definition)
    } else {
        result.push(`local ${library.name} = {}\n`)

        if (library.version) {
            result.push(`${library.name}.VERSION = ${luaString(library.version)}\n`)
        }
    }

    if (library.after) {
        result.push(...library.after)
    }

    if (library.modules) {
        for (const mod of modules) {
            const module = library.modules[mod]
            if (!module) continue
            if (!module.body && !module.require) {
                continue
            }

            if (module.before) {
                result.push(...module.before)
            }

            if (module.body) {
                result.push(...module.body)
            } else if (module.require) {
                const moduleAfter = mod.match(luaIdentRegex) ? `.${mod}` : `[${luaString(mod)}]`
                result.push(`${library.name}${moduleAfter} = require ${luaString(module.require)}\n`)
            }

            if (module.after) {
                result.push(...module.after)
            }
        }
    }

    if (library['return'] !== undefined) {
        result.push(...library['return'])
    } else {
        result.push(`return ${library.name}\n`)
    }

    return result.join('\n')
}

/**
 * Validates an optional field to ensure it is either a string or a string array.
 * If the field is a string, it is converted to a string array.
 * @param obj The object to check.
 * @param field The field to check.
 * @param prefix A prefix to include before error messages.
 * @throws Throws if the field value is not a string or a string array.
 */
const validateStringArrField = (obj: any, field: string, prefix: string = '') => {
    if (!(field in obj)) return

    if (typeof obj[field] === 'string') {
        // strings can be coerced into single-element arrays
        obj[field] = [ obj[field] ]
        return
    }

    if (!Array.isArray(obj[field])) {
        throw `${prefix}field '${field}' must be a string or string array`
    }

    for (const val of obj[field]) {
        if (typeof val !== 'string') {
            throw `${prefix}field '${field}' must be a string or string array`
        }
    }
}

/**
 * Validates a library, performing corrections if possible.
 * @param library The library object.
 * @throws If the library is invalid, throws a string that explains why.
 */
const validateLibrary = (library: Library): library is Library => {
    if (!('name' in library)) {
        throw `missing required field 'name'`
    }

    if (typeof library.name !== 'string') {
        throw `field 'name' must be a string`
    }

    if (!library.name.match(luaIdentRegex)) {
        throw `field 'name' must be a valid Lua identifier`
    }

    if ('version' in library && typeof library.version !== 'string') {
        throw `field 'version' must be a string`
    }

    const fields = [
        'luaDirectory',
        'outFile',
        'defaultModules',
        'header',
        'definition',
        'before',
        'after',
        'return',
    ]

    fields.forEach(field => validateStringArrField(library, field))

    if (!('modules' in library)) return true
    if (typeof library.modules !== 'object') {
        throw `field 'modules' must be an object`
    }

    for (const [name, module] of Object.entries(library.modules)) {
        const prefix = `module '${name}' `
        if (typeof module !== 'object' || !module) {
            throw `${prefix}must be an object`
        }

        if (!('require' in module) && !('body' in module)) {
            throw `${prefix}must have 'require' or 'body' field`
        }

        if ('require' in module && typeof module.require !== 'string') {
            throw `${prefix}field 'require' must be a string`
        }

        validateStringArrField(module, 'body', prefix)
        validateStringArrField(module, 'before', prefix)
        validateStringArrField(module, 'after', prefix)
    }

    return true
}

/**
 * Tries to read a Library object from a given file.
 * This will only try to read files ending in .json.
 * @param input Input file path.
 * @returns The library definition, if successfully read.
 */
const readLibrary = async (input: string) => {
    if (await isDirectory(input)) {
        input = path.join(input, 'library.json')
    }

    if (path.extname(input).toUpperCase() !== '.JSON') {
        return
    }

    let library
    const json = await readFile(input)

    try {
        library = JSON.parse(json)
    } catch (e) {
        if (!(e instanceof Error)) throw e
        throw new ScriptError(`failed to read library: ${e.message}`)
    }

    try {
        if (!validateLibrary(library)) return
    } catch (e) {
        throw new ScriptError(`invalid library: ${e}`)
    }

    library.path = input
    return library
}

/**
 * Creates the initial bundle.
 * @param input The input file path or library information.
 * @param modules A list of library modules to include.
 * @returns The bundle source.
 */
const createBundle = async (input: Library | string, modules: string[]) => {
    let source
    if (typeof input === 'string') {
        source = await readFile(input)
    } else {
        source = buildRoot(input, modules)
    }

    try {
        return luabundle.bundleString(source, {
            identifiers: {
                require: 'require',
            }
        })
    } catch (e) {
        throw new ScriptError(`failed to create bundle: ${e}`)
    }
}

/**
 * Rewrites the initial generated bundle based on library definitions.
 * This replaces the runtime and removes additional parameters from module functions.
 * @param bundled The initial bundle content.
 * @param library The library information object.
 * @returns The final output bundle.
 */
const rewriteBundle = async (bundled: string, library: Library | undefined) => {
    const runtime = await readFile(path.join(__dirname, 'runtime.lua'))
    const tree = ast.parse(bundled, { locations: true })

    let root, returnStatement, runtimeNode
    const modules = []
    for (const node of tree.body) {
        if (node.type === 'CallStatement') {
            const base = node.expression.base
            if (base.type !== 'Identifier') continue
            if (base.name !== '__bundle_register') continue
            if (node.expression.type !== 'CallExpression') continue

            const firstArg = node.expression.arguments[0]
            if (firstArg?.type !== 'StringLiteral') continue

            if (firstArg.raw === '"__root"') {
                root = node
            } else {
                modules.push(node)
            }
        } else if (node.type === 'ReturnStatement') {
            returnStatement = node
        } else if (node.type === 'LocalStatement') {
            const initNode = node.init[0]
            if (!initNode) continue
            if (initNode.type !== 'CallExpression') continue
            if (initNode.base.type !== 'FunctionDeclaration') continue

            runtimeNode = node
        }
    }

    const lines = bundled.split('\n')
    const result = [ ...(library?.header ?? []) ]

    if (root && returnStatement && runtimeNode) {
        // rewrite the bundle to place the root in the main chunk
        result.push(runtime)

        for (const mod of modules) {
            if (mod.expression.base.type !== 'Identifier') continue
            if (mod.expression.type !== 'CallExpression') continue

            const modName = mod.expression.arguments[0]
            if (modName.type !== 'StringLiteral') continue

            result.push(`${mod.expression.base.name}(${modName.raw}, function(require)`)
            result.push(...lines.slice(mod.loc!.start.line, mod.loc!.end.line))

        }
        
        result.push(...lines.slice(root.loc!.start.line, root.loc!.end.line - 1))
    } else {
        // unexpected structure → no bundling occurred
        result.push(...lines)
    }

    return result.join('\n')
}

/**
 * Creates a library bundle based on the provided arguments.
 */
export const createLibraryBundle = async (args: BundleArgs) => {
    const input = path.resolve(args.input)
    const library = await readLibrary(input)

    const output = path.resolve(
        args.output
        ?? (library?.outFile && path.join(path.dirname(library.path), ...library.outFile))
        ?? path.join('.', 'bundle.lua'))

    const luaDirectory = args.luaDirectory
        ?? (library?.luaDirectory && path.join(path.dirname(library.path), ...library.luaDirectory))
        ?? (library?.path && path.dirname(library.path))

    const modules = args.all
        ? Object.keys(library?.modules ?? [])
        : (args.modules && args.modules.length > 0)
            ? args.modules
            : (library?.defaultModules ?? [])

    if (luaDirectory) chdir(path.resolve(luaDirectory), 'Lua directory')
    const bundled = await rewriteBundle(await createBundle(library ?? input, modules), library)

    await writeFile(output, bundled)
}
