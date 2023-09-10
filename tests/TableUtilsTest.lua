local test = require 'test'
local utils = require 'utils'


---@class omi.tests.TableUtils : omi.test.TestCase
local TableUtilsTest = test.case('TableUtilsTest')


local id = function(x) return x end
local isPositive = function(x) return x > 0 end
local isNegative = function(x) return x < 0 end
local isZero = function(x) return x == 0 end
local increment = function(x) return x + 1 end
local add = function(x, y) return x + y end

local _0 = { 0, 0, 0 }
local n01 = { 0, -1 }
local p01 = { 0,  1 }
local n12 = { -1, -2 }
local p12 = {  1,  2 }


---Tests `utils.all` with tables.
function TableUtilsTest:testAll()
    self:assertTrue(utils.all(isZero, _0))

    self:assertFalse(utils.all(isZero, n01))
    self:assertFalse(utils.all(isNegative, n01))
    self:assertFalse(utils.all(isPositive, n01))

    self:assertFalse(utils.all(isZero, p01))
    self:assertFalse(utils.all(isPositive, p01))
    self:assertFalse(utils.all(isNegative, p01))

    self:assertFalse(utils.all(isZero, n12))
    self:assertTrue(utils.all(isNegative, n12))
    self:assertFalse(utils.all(isPositive, n12))

    self:assertFalse(utils.all(isZero, p12))
    self:assertFalse(utils.all(isNegative, p12))
    self:assertTrue(utils.all(isPositive, p12))
end

---Tests `utils.all` with iterators.
function TableUtilsTest:testAllIter()
    self:assertTrue(utils.all(isZero, ipairs(_0)))

    self:assertFalse(utils.all(isZero, ipairs(n01)))
    self:assertFalse(utils.all(isNegative, ipairs(n01)))
    self:assertFalse(utils.all(isPositive, ipairs(n01)))

    self:assertFalse(utils.all(isZero, ipairs(p01)))
    self:assertFalse(utils.all(isPositive, ipairs(p01)))
    self:assertFalse(utils.all(isNegative, ipairs(p01)))

    self:assertFalse(utils.all(isZero, ipairs(n12)))
    self:assertTrue(utils.all(isNegative, ipairs(n12)))
    self:assertFalse(utils.all(isPositive, ipairs(n12)))

    self:assertFalse(utils.all(isZero, ipairs(p12)))
    self:assertFalse(utils.all(isNegative, ipairs(p12)))
    self:assertTrue(utils.all(isPositive, ipairs(p12)))
end

---Tests `utils.any` with tables.
function TableUtilsTest:testAny()
    self:assertTrue(utils.any(isZero, _0))

    self:assertTrue(utils.any(isZero, n01))
    self:assertTrue(utils.any(isNegative, n01))
    self:assertFalse(utils.any(isPositive, n01))

    self:assertTrue(utils.any(isZero, p01))
    self:assertTrue(utils.any(isPositive, p01))
    self:assertFalse(utils.any(isNegative, p01))

    self:assertFalse(utils.any(isZero, n12))
    self:assertTrue(utils.any(isNegative, n12))
    self:assertFalse(utils.any(isPositive, n12))

    self:assertFalse(utils.any(isZero, p12))
    self:assertFalse(utils.any(isNegative, p12))
    self:assertTrue(utils.any(isPositive, p12))
end

---Tests `utils.any` with iterators.
function TableUtilsTest:testAnyIter()
    self:assertTrue(utils.any(isZero, ipairs(_0)))

    self:assertTrue(utils.any(isZero, ipairs(n01)))
    self:assertTrue(utils.any(isNegative, ipairs(n01)))
    self:assertFalse(utils.any(isPositive, ipairs(n01)))

    self:assertTrue(utils.any(isZero, ipairs(p01)))
    self:assertTrue(utils.any(isPositive, ipairs(p01)))
    self:assertFalse(utils.any(isNegative, ipairs(p01)))

    self:assertFalse(utils.any(isZero, ipairs(n12)))
    self:assertTrue(utils.any(isNegative, ipairs(n12)))
    self:assertFalse(utils.any(isPositive, ipairs(n12)))

    self:assertFalse(utils.any(isZero, ipairs(p12)))
    self:assertFalse(utils.any(isNegative, ipairs(p12)))
    self:assertTrue(utils.any(isPositive, ipairs(p12)))
end

---Tests `utils.concat`.
function TableUtilsTest:testConcat()
    self:assertEqual(utils.concat({}), '')
    self:assertEqual(utils.concat({1, 2, 3, 'a'}), '123a')
    self:assertEqual(utils.concat({'hello'}), 'hello')
end

---Tests `utils.copy`.
function TableUtilsTest:testCopy()
    -- copies are equal
    self:assertEqual(utils.copy({}), {})
    self:assertEqual(utils.copy({{}}), {{}})
    self:assertEqual(utils.copy({1, 2, 3}), {1, 2, 3})

    -- copies are not reference equal
    self:assertFalse(utils.copy({}) == {})
end

---Tests `utils.filter`.
function TableUtilsTest:testFilter()
    self:assertEqual(utils.pack(utils.filter(isZero, _0)), _0)
    self:assertEqual(utils.pack(utils.filter(isZero, id(_0))), _0)
end

---Tests `utils.map`.
function TableUtilsTest:testMap()
    -- works as expected with numeric keys
    self:assertEqual(utils.pack(utils.map(increment, _0)), {1, 1, 1})

    -- works as expected with non-numeric keys
    self:assertEqual(utils.pack(utils.map(increment, {a = 0})), {a = 1})
end

---Tests `utils.mapList`.
function TableUtilsTest:testMapList()
    -- works as expected with numeric keys
    self:assertEqual(utils.pack(utils.mapList(increment, _0)), {1, 1, 1})

    -- works as expected with non-numeric keys
    self:assertEqual(utils.pack(utils.mapList(increment, {a = 0, 1})), {2})
end

---Tests `utils.pack`.
function TableUtilsTest:testPack()
    self:assertEqual(utils.pack(ipairs({1, 2, 3})), {1, 2, 3})
end

---Tests `utils.reduce` and `utils.reduceList`.
function TableUtilsTest:testReduce()
    -- reduce works as expected
    self:assertEqual(utils.reduce(add, 0, {1, 2, 3}), 6)
    self:assertEqual(utils.reduce(add, -6, {a=1, b=2, c=3}), 0)

    -- reduceList works as expected
    self:assertEqual(utils.reduceList(add, 0, {1, 2, 3, a = 6, [5] = 10}), 6)
    self:assertEqual(utils.reduceList(add, -6, {1, 2, 3, a = 100}), 0)
end

return TableUtilsTest
