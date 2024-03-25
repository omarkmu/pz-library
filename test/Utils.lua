local utils = require 'utils'

describe('table utility', function()
    local isPositive = function(x) return x > 0 end
    local isNegative = function(x) return x < 0 end
    local isZero = function(x) return x == 0 end
    local increment = function(x) return x + 1 end
    local add = function(x, y) return x + y end

    local _0 = { 0, 0, 0 }
    local n01 = { 0, -1 }
    local p01 = { 0, 1 }
    local n12 = { -1, -2 }
    local p12 = { 1, 2 }

    describe('utils.all', function()
        it('should return expected values with table inputs', function()
            assert.True(utils.all(isZero, _0))

            assert.False(utils.all(isZero, n01))
            assert.False(utils.all(isNegative, n01))
            assert.False(utils.all(isPositive, n01))

            assert.False(utils.all(isZero, p01))
            assert.False(utils.all(isPositive, p01))
            assert.False(utils.all(isNegative, p01))

            assert.False(utils.all(isZero, n12))
            assert.True(utils.all(isNegative, n12))
            assert.False(utils.all(isPositive, n12))

            assert.False(utils.all(isZero, p12))
            assert.False(utils.all(isNegative, p12))
            assert.True(utils.all(isPositive, p12))
        end)

        it('should return expected values with iterator inputs', function()
            assert.True(utils.all(isZero, ipairs(_0)))

            assert.False(utils.all(isZero, ipairs(n01)))
            assert.False(utils.all(isNegative, ipairs(n01)))
            assert.False(utils.all(isPositive, ipairs(n01)))

            assert.False(utils.all(isZero, ipairs(p01)))
            assert.False(utils.all(isPositive, ipairs(p01)))
            assert.False(utils.all(isNegative, ipairs(p01)))

            assert.False(utils.all(isZero, ipairs(n12)))
            assert.True(utils.all(isNegative, ipairs(n12)))
            assert.False(utils.all(isPositive, ipairs(n12)))

            assert.False(utils.all(isZero, ipairs(p12)))
            assert.False(utils.all(isNegative, ipairs(p12)))
            assert.True(utils.all(isPositive, ipairs(p12)))
        end)
    end)

    describe('utils.any', function()
        it('should return expected values with table inputs', function()
            assert.True(utils.any(isZero, _0))

            assert.True(utils.any(isZero, n01))
            assert.True(utils.any(isNegative, n01))
            assert.False(utils.any(isPositive, n01))

            assert.True(utils.any(isZero, p01))
            assert.True(utils.any(isPositive, p01))
            assert.False(utils.any(isNegative, p01))

            assert.False(utils.any(isZero, n12))
            assert.True(utils.any(isNegative, n12))
            assert.False(utils.any(isPositive, n12))

            assert.False(utils.any(isZero, p12))
            assert.False(utils.any(isNegative, p12))
            assert.True(utils.any(isPositive, p12))
        end)

        it('should return expected values with iterator inputs', function()
            assert.True(utils.all(isZero, ipairs(_0)))

            assert.False(utils.all(isZero, ipairs(n01)))
            assert.False(utils.all(isNegative, ipairs(n01)))
            assert.False(utils.all(isPositive, ipairs(n01)))

            assert.False(utils.all(isZero, ipairs(p01)))
            assert.False(utils.all(isPositive, ipairs(p01)))
            assert.False(utils.all(isNegative, ipairs(p01)))

            assert.False(utils.all(isZero, ipairs(n12)))
            assert.True(utils.all(isNegative, ipairs(n12)))
            assert.False(utils.all(isPositive, ipairs(n12)))

            assert.False(utils.all(isZero, ipairs(p12)))
            assert.False(utils.all(isNegative, ipairs(p12)))
            assert.True(utils.all(isPositive, ipairs(p12)))
        end)
    end)

    describe('utils.concat', function()
        it('should concatenate strings', function()
            assert.equal(utils.concat({}), '')
            assert.equal(utils.concat({ 'hello' }), 'hello')
            assert.equal(utils.concat({ 'a', 'b' }), 'ab')
        end)

        it('should concatenate numbers', function()
            assert.equal(utils.concat({ 1, 2 }), '12')
            assert.equal(utils.concat({ 1, 2, 'a', 3, 'b' }), '12a3b')
        end)

        it('should convert non-string values to strings', function()
            local t = setmetatable({}, {
                __tostring = function()
                    return 'string'
                end,
            })

            assert.equal(utils.concat({ t }), 'string')
        end)
    end)

    describe('utils.copy', function()
        it('should create equal copies', function()
            assert.same(utils.copy({}), {})
            assert.same(utils.copy({ {} }), { {} })
            assert.same(utils.copy({ 1, 2, 3 }), { 1, 2, 3 })
        end)

        it('should create copies that are not reference equal', function()
            local original = {}
            assert.is_not.equal(utils.copy(original), original)
        end)
    end)

    describe('utils.filter', function()
        it('should filter elements according to a predicate', function()
            assert.same(utils.pack(utils.filter(isZero, _0)), _0)
            assert.same(utils.pack(utils.filter(isZero, n01)), { 0 })
        end)

        it('should filter iterator elements according to a predicate', function()
            assert.same(utils.pack(utils.filter(isZero, pairs(_0))), _0)
            assert.same(utils.pack(utils.filter(isZero, pairs(n01))), { 0 })
        end)
    end)

    describe('utils.map', function()
        it('should work as expected with numeric keys', function()
            assert.same(utils.pack(utils.map(increment, _0)), { 1, 1, 1 })
        end)

        it('should work as expected with non-numeric keys', function()
            assert.same(utils.pack(utils.map(increment, { a = 0, b = 1 })), { a = 1, b = 2 })
        end)
    end)

    describe('utils.mapList', function()
        it('should work as expected with numeric keys', function()
            assert.same(utils.pack(utils.mapList(increment, _0)), { 1, 1, 1 })
        end)

        it('should work as expected with non-numeric keys', function()
            assert.same(utils.pack(utils.mapList(increment, { a = 0, 1 })), { 2 })
        end)
    end)

    describe('utils.pack', function()
        it('should pack an iterator into a table', function()
            assert.same(utils.pack(ipairs({ 1, 2, 3 })), { 1, 2, 3 })
            assert.same(utils.pack(ipairs({ 1, 2, 3, a = 1 })), { 1, 2, 3 })
            assert.same(utils.pack(pairs({ 1, 2, 3, a = 1 })), { 1, 2, 3, a = 1 })
        end)
    end)

    describe('utils.reduce', function()
        it('should reduce an iterator into a table', function()
            assert.same(utils.reduce(add, 0, { 1, 2, 3 }), 6)
            assert.same(utils.reduce(add, -6, { a = 1, b = 2, c = 3 }), 0)
        end)
    end)

    describe('utils.reduceList', function()
        it('should reduce an iterator into a list', function()
            assert.same(utils.reduceList(add, 0, { 1, 2, 3, a = 6, [5] = 10 }), 6)
            assert.same(utils.reduceList(add, -6, { 1, 2, 3, a = 100 }), 0)
        end)
    end)
end)

describe('string utility', function()
    describe('utils.escape', function()
        it('should replace special characters', function()
            assert.equal(utils.escape('[]()+-*?.^$%'), '%[%]%(%)%+%-%*%?%.%^%$%%')
        end)

        it('should not replace non-special characters', function()
            assert.equal(utils.escape('ABC123!'), 'ABC123!')
        end)
    end)
end)
