local symmath = require('symmath')

local mod = {}
local symvec = {}
symvec.__index = symvec

-- locals & utilities ----------------------------------------------------------

local floor = math.floor
local pi = symmath.pi
local sqrt = symmath.sqrt

local function all(cond, ...)
    local tab = {...}
    for _, n in ipairs(tab) do if not cond(n) then return false end end
    return true
end

local function isnumber(n) return type(n) == 'number' end

local function isexpression(n) return symmath.Expression:isa(n) end

-- module ----------------------------------------------------------------------

local function new(x, y, z)
    local v = {}
    if symmath.Matrix:isa(x) and y == nil and z == nil then -- check size?
        v.mat = x
    elseif all(function(e) return isnumber(e) or isexpression(e) end, x, y, z) then
        v.mat = symmath.Matrix({x}, {y}, {z})()
    else
        error('format error')
    end
    return setmetatable(v, symvec)
end

local function fromSpherical(r, theta, phi)

    local phi2 = phi + pi / 2

    local x = r * sin(phi2) * sin(theta)
    local y = r * cos(theta)
    local z = -r * cos(phi2) * sin(theta)

    return new(x, y, z)

end

local function vars(...)
    if all(function(e) return type(e) == 'string' end, ...) then
        return symmath.vars(...)
    end
end

local function compile(fv, ...)

    local v = fv(...)

    return symmath.export.Lua:toFunc({
        input = {...},
        output = {{x = v.mat[1][1]}, {y = v.mat[2][1]}, {z = v.mat[3][1]}}
    })

end

-- arithmetic utilities --------------------------------------------------------

-- add

local function scalarArrayAdd(s, m)
    mdim = m:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = m:clone()
    for i = 1, mw do for j = 1, mh do result[i][j] = s + result[i][j] end end
    return result
end

local function arrayScalarAdd(m, s)
    mdim = m:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = m:clone()
    for i = 1, mw do for j = 1, mh do result[i][j] = result[i][j] + s end end
    return result
end

-- sub

local function scalarArraySub(s, m)
    mdim = m:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = m:clone()
    for i = 1, mw do for j = 1, mh do result[i][j] = s - result[i][j] end end
    return result
end

local function arrayScalarSub(m, s)
    mdim = m:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = m:clone()
    for i = 1, mw do for j = 1, mh do result[i][j] = result[i][j] - s end end
    return result
end

-- mul

local function perElementMul(a, b)
    adim = a:dim()
    bdim = b:dim()
    local aw = adim[1]
    local ah = adim[2]
    local bw = bdim[1]
    local bh = bdim[2]
    if aw ~= bw or ah ~= bh then return end
    local result = a:clone()
    for i = 1, aw do
        for j = 1, ah do result[i][j] = result[i][j] * b[i][j] end
    end
    return result
end

local function scalarArrayMul(s, m)
    mdim = m:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = m:clone()
    for i = 1, mw do for j = 1, mh do result[i][j] = s * result[i][j] end end
    return result
end

local function arrayScalarMul(m, s)
    mdim = m:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = m:clone()
    for i = 1, mw do for j = 1, mh do result[i][j] = result[i][j] * s end end
    return result
end

-- div

local function perElementDiv(a, b)
    adim = a:dim()
    bdim = b:dim()
    local aw = adim[1]
    local ah = adim[2]
    local bw = bdim[1]
    local bh = bdim[2]
    if aw ~= bw or ah ~= bh then return end
    local result = a:clone()
    for i = 1, aw do
        for j = 1, ah do result[i][j] = result[i][j] / b[i][j] end
    end
    return result
end

local function scalarArrayDiv(s, m)
    mdim = m:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = m:clone()
    for i = 1, mw do for j = 1, mh do result[i][j] = s / result[i][j] end end
    return result
end

local function arrayScalarDiv(m, s)
    mdim = m:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = m:clone()
    for i = 1, mw do for j = 1, mh do result[i][j] = result[i][j] / s end end
    return result
end

-- vector functions ------------------------------------------------------------

function symvec:length() return self.mat:norm() end

function symvec:norm() return self / self:length() end

function symvec:dot(b)
    return (self.mat[1][1] * b.mat[1][1] + self.mat[2][1] * b.mat[2][1] +
               self.mat[3][1] * b.mat[3][1])()
end

function symvec:cross(b)
    local result = self.mat:clone()
    result[1][1] = self.mat[2][1] * b.mat[3][1] - self.mat[3][1] * b.mat[2][1]
    result[2][1] = self.mat[3][1] * b.mat[1][1] - self.mat[1][1] * b.mat[3][1]
    result[3][1] = self.mat[1][1] * b.mat[2][1] - self.mat[2][1] * b.mat[1][1]
    return new(result())
end

function symvec:rotate_around(axis, angle)
    local axis = axis:norm()
    return new((scalarArrayMul(symmath.cos(angle), self.mat)() +
                   scalarArrayMul(1 - symmath.cos(angle),
                                  scalarArrayMul(self:dot(axis), axis.mat)())() +
                   scalarArrayMul(symmath.sin(angle), self:cross(axis).mat)())())

end

function symvec:scale(mag) return self * (mag / self:length()) end

function symvec:apply_abs()
    local mdim = self.mat:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = self.mat:clone()
    for i = 1, mw do
        for j = 1, mh do result[i][j] = symmath.abs(result[i][j]) end
    end
    return new(result())
end

function symvec:apply_exp()
    local mdim = self.mat:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = self.mat:clone()
    for i = 1, mw do
        for j = 1, mh do result[i][j] = symmath.exp(result[i][j]) end
    end
    return new(result())
end

function symvec:apply_sqrt()
    local mdim = self.mat:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = self.mat:clone()
    for i = 1, mw do
        for j = 1, mh do result[i][j] = symmath.sqrt(result[i][j]) end
    end
    return new(result())
end

function symvec:apply_sin()
    local mdim = self.mat:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = self.mat:clone()
    for i = 1, mw do
        for j = 1, mh do result[i][j] = symmath.sin(result[i][j]) end
    end
    return new(result())
end

function symvec:apply_cos()
    local mdim = self.mat:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = self.mat:clone()
    for i = 1, mw do
        for j = 1, mh do result[i][j] = symmath.cos(result[i][j]) end
    end
    return new(result())
end

function symvec:apply_atan()
    local mdim = self.mat:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = self.mat:clone()
    for i = 1, mw do
        for j = 1, mh do result[i][j] = symmath.atan(result[i][j]) end
    end
    return new(result())
end

function symvec:apply_tanh()
    local mdim = self.mat:dim()
    local mw = mdim[1]
    local mh = mdim[2]
    local result = self.mat:clone()
    for i = 1, mw do
        for j = 1, mh do result[i][j] = symmath.tanh(result[i][j]) end
    end
    return new(result())
end

-- meta functions --------------------------------------------------------------

function symvec:__tostring() return tostring(self.mat) end

function symvec.__concat(a, b)
    local s1 = type(a) == 'table' and tostring(a.mat) or tostring(a)
    local s2 = type(b) == 'table' and tostring(b.mat) or tostring(b)
    return s1 .. s2
end

function symvec.__eq(a, b) return a.mat == b.mat end

function symvec:__unm() return new(-self.mat) end

function symvec.__add(a, b)
    if isnumber(a) or symmath.Expression:isa(a) then
        return new(scalarArrayAdd(a, b.mat)())
    elseif isnumber(b) or symmath.Expression:isa(b) then
        return new(arrayScalarAdd(a.mat, b)())
    else
        return new((a.mat + b.mat)())
    end
end

function symvec.__sub(a, b)
    if isnumber(a) or symmath.Expression:isa(a) then
        return new(scalarArraySub(a, b.mat)())
    elseif isnumber(b) or symmath.Expression:isa(b) then
        return new(arrayScalarSub(a.mat, b)())
    else
        return new((a.mat - b.mat)())
    end
end

function symvec.__mul(a, b)
    if isnumber(a) or symmath.Expression:isa(a) then
        return new(scalarArrayMul(a, b.mat)())
    elseif isnumber(b) or symmath.Expression:isa(b) then
        return new(arrayScalarMul(a.mat, b)())
    else
        return new(perElementMul(a.mat, b.mat)())
    end
end

function symvec.__div(a, b)
    if isnumber(a) or symmath.Expression:isa(a) then
        return new(scalarArrayDiv(a, b.mat)())
    elseif isnumber(b) or symmath.Expression:isa(b) then
        return new(arrayScalarDiv(a.mat, b)())
    else
        return new(perElementDiv(a.mat, b.mat)())
    end
end

-- export module ---------------------------------------------------------------

mod.fromSpherical = fromSpherical
mod.vars = vars
mod.compile = compile
mod.pi = symmath.pi
mod.e = symmath.e
mod.abs = symmath.abs
mod.sqrt = symmath.sqrt
mod.cbrt = symmath.cbrt
mod.sin = symmath.sin
mod.asin = symmath.asin
mod.sinh = symmath.sinh
mod.cos = symmath.cos
mod.acos = symmath.acos
mod.cosh = symmath.cosh
mod.tan = symmath.tan
mod.atan = symmath.atan
mod.tanh = symmath.tanh

return setmetatable(mod, {__call = function(_, ...) return new(...) end})

-- local function wat(i)

--     print('---')
--     if symmath.Variable:isa(i) then
--         print('Variable')
--     elseif symmath.Matrix:isa(i) then
--         local s = {}
--         for i, d in ipairs(i:dim()) do s[i] = d end
--         print('Matrix [' .. table.concat(s, ',') .. ']')
--     elseif symmath.Array:isa(i) then
--         print('symmath.Array')
--     elseif symmath.Expression:isa(i) then
--         print('Expression')
--     else
--         print(type(i))
--     end
-- end
