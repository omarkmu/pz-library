local test = require 'test'

if test.isMain() then
    test.run({
        require('tests/InterpolatorTest'),
        require('tests/TableUtilsTest'),
    }, { args = { ... }})
end
