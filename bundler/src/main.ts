import yargs from 'yargs'
import type { Argv } from 'yargs'
import { hideBin } from 'yargs/helpers'
import { createLibraryBundle } from './commands/create.ts'
import { ScriptError } from './types.ts'


/**
 * Outputs an error and updates the exit code.
 */
function onError(e: unknown) {
    if (e instanceof ScriptError) {
        console.log(e.message)
    } else {
        console.error(e)
    }

    process.exitCode = 1
}

/**
 * Builds the library bundle create command yargs object.
 */
function buildCreateCommand(yargs: Argv) {
    return yargs
        .positional('input', {
            type: 'string',
            desc: 'path to Lua or JSON file'
        })
        .option('modules', {
            alias: 'm',
            type: 'string',
            array: true,
            desc: 'library modules to include'
        })
        .option('all', {
            type: 'boolean',
            alias: 'a',
            default: false,
            desc: 'include all modules',
        })
        .option('output', {
            type: 'string',
            alias: 'o',
            desc: 'output file path',
        })
        .option('lua-directory', {
            type: 'string',
            alias: 'l',
            desc: 'directory to search for Lua files',
        })
        .demandOption('input')
}

yargs(hideBin(process.argv))
    .scriptName('bundler')
    .help('help', 'show help')
    .version(false)
    .command('create <input>',
        'create a library bundle',
        buildCreateCommand,
        (args) => createLibraryBundle(args).catch(onError))
    .demandCommand()
    .strict()
    .parseAsync()
    .catch(onError)
