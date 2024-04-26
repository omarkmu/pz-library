import typescript from '@rollup/plugin-typescript'

export default {
    input: './src/main.ts',
    output: {
        file: './index.cjs',
        format: 'cjs',
    },
    plugins: [ typescript() ],
    onwarn: (warning, warn) => {
        // ignore 3rd party warnings
        if (warning?.id?.indexOf?.('node_modules') !== -1) return
        if (warning?.ids?.[0]?.indexOf?.('node_modules') !== -1) return
        warn(warning)
    }
}
