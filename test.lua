#!/usr/bin/env lua

symvec = require('symvec')

-- local func = symvec.compile(function(x1, y1, z1, x2, y2, z2, dtime, speedV,
--                                       speedH, radius)

--     local pos = symvec(x1, y1, z1)
--     local ppos = symvec(x2, y2, z2) + symvec(0, 10, 0)

--     local rad = pos - ppos
--     local radH = rad * symvec(1, 0, 1)
--     local radV = rad * symvec(0, 1, 0)
--     local distH = radH:length()
--     local distV = radV:length()
--     local corH = symvec.atan((distH - radius) / radius)
--     local corV = symvec.tanh(distV)

--     local speed = radH:rotate_around(symvec(0, 1, 0), symvec.pi / 2 + corH)
--                       :scale(speedH) - radV:scale(corV * speedV)


--     return pos + speed * dtime

-- end,
--                              symvec.vars('x1', 'y1', 'z1', 'x2', 'y2', 'z2',
--                                           'dtime', 'speedV', 'speedH', 'radius'))

-- print(func(1, 2, 3))



func = function (x1, y1, z1, x2, y2, z2, dtime, speedV, speedH, radius)
	local tmp1 = x1 * x2
	local tmp2 = x1 * x1
	local tmp3 = 2 * tmp1
	local tmp4 = z1 * z2
	local tmp5 = z1 * z1
	local tmp6 = 2 * tmp4
	local tmp7 = tmp5 - tmp6
	local tmp8 = z2 * z2
	local tmp9 = x2 * x2
	local tmp10 = tmp7 + tmp8
	local tmp11 = tmp2 - tmp3
	local tmp12 = tmp9 + tmp10
	local tmp13 = tmp11 + tmp12
	local tmp14 = math.sqrt(tmp13)
	local tmp22 = tmp9 - tmp6
	local tmp23 = tmp5 + tmp8
	local tmp25 = tmp22 + tmp23
	local tmp26 = -tmp3
	local tmp27 = tmp25 + tmp2
	local tmp28 = tmp26 + tmp27
	local tmp29 = math.sqrt(tmp28)
	local tmp30 = tmp29 - radius
	local tmp31 = tmp30 / radius
	local tmp32 = math.atan(tmp31)
	local tmp33 = 2 * tmp32
	local tmp34 = tmp33 + math.pi
	local tmp35 = tmp34 / 2
	local tmp36 = math.cos(tmp35)
	local tmp86 = math.sin(tmp35)
	local tmp134 = 20 * y1
	local tmp135 = y1 * y2
	local tmp136 = y1 * y1
	local tmp137 = 2 * tmp135
	local tmp138 = tmp136 - tmp137
	local tmp139 = y2 * y2
	local tmp140 = 20 * y2
	local tmp141 = tmp138 + tmp139
	local tmp142 = 100 - tmp134
	local tmp143 = tmp140 + tmp141
	local tmp144 = tmp142 + tmp143
	local tmp145 = math.sqrt(tmp144)
	local tmp158 = math.tanh(tmp145)
	local x = (dtime * speedH * z2 * tmp86 + dtime * speedH * x1 * tmp36 - dtime * speedH * x2 * tmp36 - dtime * speedH * z1 * tmp86 + x1 * tmp14) / tmp14
	local y = (dtime * speedV * y2 * tmp158 + 10 * dtime * speedV * tmp158 - dtime * speedV * y1 * tmp158 + y1 * tmp145) / tmp145
	local z = (dtime * speedH * z1 * tmp36 - dtime * speedH * z2 * tmp36 + dtime * speedH * x1 * tmp86 - dtime * speedH * x2 * tmp86 + z1 * tmp14) / tmp14
	return x, y, z
end
