import path from 'path'
import { promises as fs } from 'fs'
import { ScriptError } from './types.ts'

type ErrMsgFunc = (op: string, f: string, n: string) => string

const defaultErrorMessage = (op: string, f: string, n: string, e: unknown) => `failed to ${op} ${n} '${f}': ${e}`

const errorMessages: Record<string, ErrMsgFunc> = {
    EPERM: (op: string, f: string, n: string) => `cannot ${op} ${n} '${f}': not permitted`, 
    EACCES: (op: string, f: string, n: string) => `cannot ${op} ${n} '${f}': access denied`, 
    ENOENT: (op: string, f: string, n: string) => `cannot ${op} ${n} '${f}': file does not exist`,
    EISDIR: (op: string, f: string, n: string) => `cannot ${op} ${n}: '${f}' is a directory`,
}

/**
 * Tries to read an input file.
 * @param inFile The path to the file to read.
 * @param name A friendly name for the input file.
 * @returns File content.
 * @throws ScriptError or original error.
 */
export async function readFile(inFile: string, name: string = 'input file') {
    try {
        return await fs.readFile(inFile, { encoding: 'utf-8' })
    } catch (e) {
        if (!(e instanceof Error) || !('code' in e) || typeof e.code !== 'string') {
            throw e
        }

        if (e.code in errorMessages) {
            throw new ScriptError(errorMessages[e.code]('read', inFile, name))
        }

        throw new ScriptError(defaultErrorMessage('read', inFile, name, e))
    }
}

/**
 * Tries to write to an output file.
 * @param outFile The output file path.
 * @param content File content to write.
 * @param name A friendly name for the output file.
 * @throws ScriptError or original error.
 */
export async function writeFile(outFile: string, content: string, name: string = 'output file') {
    try {
        await fs.mkdir(path.dirname(outFile), { recursive: true })
        await fs.writeFile(outFile, content, { flag: 'w' })
    } catch (e) {
        if (!(e instanceof Error) || !('code' in e) || typeof e.code !== 'string') {
            throw e
        }

        if (e.code in errorMessages) {
            throw new ScriptError(errorMessages[e.code]('write', outFile, name))
        }

        throw new ScriptError(defaultErrorMessage('write', outFile, name, e))
    }
}

/**
 * Tries setting the directory.
 * @param path The directory to change to.
 * @param name A friendly name for the directory.
 * @throws ScriptError or original error.
 */
export function chdir(path: string, name: string) {
    try {
        process.chdir(path)
    } catch (e) {
        if (!(e instanceof Error) || !('code' in e) || typeof e.code !== 'string') {
            throw e
        }

        if (e.code === 'ENOENT') {
            throw new ScriptError(`invalid ${name} '${path}'`)
        }

        throw new ScriptError(`invalid ${name} '${path}' ${e}`)
    }
}

/**
 * Checks whether the provided input path is a directory.
 * @param path The input path.
 */
export async function isDirectory(path: string) {
    try {
        const stat = await fs.lstat(path)
        return stat.isDirectory()
    } catch (e) {
        return false
    }
}
