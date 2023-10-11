local math = math
local class = require 'class'
local utils = require 'utils/type'


---Base string parser.
---@class omi.fmt.Parser : omi.Class
---@field protected _errors omi.fmt.ParserError[]?
---@field protected _warnings omi.fmt.ParserError[]?
---@field protected _ptr integer
---@field protected _text string
---@field protected _node omi.fmt.ParseTreeNode?
---@field protected _tree omi.fmt.ParseTree
---@field protected _treeNodeName string
---@field protected _raiseErrors boolean
local Parser = class()

Parser.Errors = {
    BAD_CHAR = 'unexpected character: `%s`',
}


---Base parser options.
---@class omi.fmt.ParserOptions
---@field raiseErrors boolean?
---@field treeNodeName string?

---Describes error that occurred during parsing.
---@class omi.fmt.ParserError
---@field error string
---@field node omi.fmt.ParseTreeNode?
---@field range integer[]

---Describes a node in a parse tree.
---@class omi.fmt.ParseTreeNode
---@field type string
---@field range integer[]
---@field value string?
---@field children omi.fmt.ParseTreeNode[]?

---Top-level parse tree node.
---@class omi.fmt.ParseTree : omi.fmt.ParseTreeNode
---@field source string
---@field errors omi.fmt.ParserError[]?
---@field warnings omi.fmt.ParserError[]?


---Moves the parser pointer forward.
---@param inc integer? The value to move forward by. Defaults to 1.
---@protected
function Parser:forward(inc)
    self:pos(self:pos() + (inc or 1))
end

---Moves the parser pointer backwards.
---@param inc integer? The value to move backwards by. Defaults to 1.
---@protected
function Parser:rewind(inc)
    self:pos(self:pos() - (inc or 1))
end

---Gets the current `n` bytes at the current pointer.
---@param n integer? The number of bytes to get. Defaults to 1.
---@return string
---@protected
function Parser:peek(n)
    return self:index(self:pos(), n or 1)
end

---Reads the current `n` bytes at the current pointer and moves the pointer forward.
---@param n integer? The number of bytes to read. Defaults to 1.
---@return string
---@protected
function Parser:read(n)
    n = n or 1

    local result = self:peek(n)
    self:forward(n)

    return result
end

---Returns a substring of the current text.
---@param i integer The index at which the substring should begin.
---@param n integer? The number of characters to return. Defaults to 1.
---@return string
---@protected
function Parser:index(i, n)
    n = n or 1
    return self._text:sub(i, i + n - 1)
end

---Returns the length of the current text.
---@return integer
---@protected
function Parser:len()
    return #self._text
end

---Gets or sets the current pointer position.
---@param value integer?
---@return integer
---@protected
function Parser:pos(value)
    if value then
        self._ptr = value
    end

    return self._ptr
end

---Adds a node to the current tree node.
---If there is no current node, this sets the current node.
---@param node omi.fmt.ParseTreeNode The node to add.
---@return omi.fmt.ParseTreeNode node The newly added node.
---@protected
function Parser:addNode(node)
    local parent = self._node

    if not parent then
        self:setCurrentNode(node)
        return node
    end

    if not parent.children then
        parent.children = {}
    end

    parent.children[#parent.children + 1] = node

    return node
end

---Creates a new tree node.
---@param type string The node type.
---@param node table? The table to use for the node.
---@return omi.fmt.ParseTreeNode
---@protected
function Parser:createNode(type, node)
    node = node or {}
    node.type = type
    node.range = node.range or {}
    self:setNodeRange(node, node.range[1], node.range[2])

    return node
end

---Sets the current tree node and returns the old node.
---@param node omi.fmt.ParseTreeNode?
---@return omi.fmt.ParseTreeNode? oldNode
---@protected
function Parser:setCurrentNode(node)
    local old = self._node
    self._node = node

    return old
end

---Sets the range of a tree node.
---@param node omi.fmt.ParseTreeNode
---@param start integer?
---@param stop integer?
---@protected
function Parser:setNodeRange(node, start, stop)
    local len = #self._text
    local pos = self:pos()
    node.range[1] = math.max(1, math.min(start or node.range[1] or pos, len))
    node.range[2] = math.max(1, math.min(stop or node.range[2] or pos, len))
end

---Sets the start position of a tree node's range.
---@param node omi.fmt.ParseTreeNode
---@param start integer? The start position. If omitted, the current pointer is used.
---@protected
function Parser:setNodeStart(node, start)
    self:setNodeRange(node, start or self:pos())
end

---Sets the end position of a tree node's range.
---@param node omi.fmt.ParseTreeNode
---@param stop integer? The end position. If omitted, the current pointer is used.
---@protected
function Parser:setNodeEnd(node, stop)
    self:setNodeRange(node, nil, stop or self:pos())
end

---Reads an expression.
---Must be implemented by subclasses.
---@return omi.fmt.ParseTreeNode?
---@protected
function Parser:readExpression()
    error('not implemented')
end

---Reports a parser error.
---@param err string
---@param node omi.fmt.ParseTreeNode
---@param start integer?
---@param stop integer?
---@protected
function Parser:error(err, node, start, stop)
    self._errors[#self._errors + 1] = {
        error = err,
        node = node ~= self._tree and node or nil,
        range = {
            start or node.range[1],
            stop or node.range[2],
        },
    }

    if self._raiseErrors then
        error(err)
    end
end

---Reports a parser error at the current position.
---@param err string
---@param node omi.fmt.ParseTreeNode
---@param len integer?
---@protected
function Parser:errorHere(err, node, len)
    len = len or 1
    local pos = self:pos()
    self:error(err, node, pos, pos + len - 1)
end

---Reports a parser warning.
---@param err string
---@param node omi.fmt.ParseTreeNode
---@param start integer?
---@param stop integer?
---@protected
function Parser:warning(err, node, start, stop)
    self._warnings[#self._warnings + 1] = {
        error = err,
        node = node ~= self._tree and node or nil,
        range = {
            start or node.range[1],
            stop or node.range[2],
        },
    }
end

---Reports a parser warning at the current position.
---@param err string
---@param node omi.fmt.ParseTreeNode
---@param len integer?
---@protected
function Parser:warningHere(err, node, len)
    len = len or 1
    local pos = self:pos()
    self:warning(err, node, pos, pos + len - 1)
end

---Resets the parser state.
---@param text string? If provided, sets the text to parse.
function Parser:reset(text)
    self._ptr = 1
    self._text = tostring(text or self._text or '')
    self._errors = {}
    self._warnings = {}
    self._node = nil

    local tree = self:addNode(self:createNode(self._treeNodeName))

    ---@cast tree omi.fmt.ParseTree
    tree.source = self._text
    self:setNodeEnd(tree, #self._text)

    self._tree = tree
end

---Performs parsing and returns the tree.
---@return omi.fmt.ParseTree
function Parser:parse()
    while self:pos() <= self:len() do
        if not self:readExpression() then
            self:error(Parser.Errors.BAD_CHAR:format(self:peek()), self._tree, self:pos(), self:pos())

            -- avoid infinite loops
            self:forward()
        end
    end

    if #self._errors > 0 then
        self._tree.errors = self._errors
    end

    if #self._warnings > 0 then
        self._tree.warnings = self._warnings
    end

    return self._tree
end

---Performs postprocessing on the result tree, transforming it into a usable format.
---@param tree omi.fmt.ParseTree
---@return unknown
function Parser:postprocess(tree)
    return tree
end

---Creates a new parser.
---@param text string
---@param options omi.fmt.ParserOptions?
---@return omi.fmt.Parser
function Parser:new(text, options)
    ---@type omi.fmt.Parser
    local this = setmetatable({}, self)

    options = options or {}

    this:reset(text)
    this._raiseErrors = utils.default(options.raiseErrors, false)
    this._treeNodeName = utils.default(options.treeNodeName, 'tree')

    return this
end


return Parser
