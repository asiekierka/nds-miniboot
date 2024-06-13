-- SPDX-License-Identifier: Zlib
--
-- Copyright (c) 2024 Adrian "asie" Siekierka

-- Original algorithm discovered by yasu, 2007
--
-- http://hp.vector.co.jp/authors/VA013928/
-- http://www.usay.jp/
-- http://www.yasu.nu/

local ADD_PADDING = false

local function crypt(sector, key1, is_encrypt)
	local result = ""
	local slen = #sector
	if ADD_PADDING then slen = 512 end

	for i=1,slen do
		local b = 0
		if i <= #sector then b = string.byte(sector, i) end

		local key2 = ((key1 >> 7) & 0x80)
			| ((key1 >> 6) & 0x60)
			| ((key1 >> 5) & 0x10)
			| ((key1 >> 4) & 0x0C)
			| (key1 & 0x03);

		result = result .. string.char(b ~ key2)
		if is_encrypt then b = b ~ key2 end

		local tmp = (b << 8) ~ key1
		local tmpXor = 0
		for i=0,15 do tmpXor = tmpXor ~ (tmp >> i) end

		key1 = 0
		key1 = key1 | (((tmpXor & 0x80) | (tmp & 0x7C)) << 8)
		key1 = key1 | (((tmp ~ (tmpXor >> 14)) << 8) & 0x0300)
		key1 = key1 | ((((tmp >> 1) ~ tmp) >> 6) & 0xFC)
		key1 = key1 | (((tmp ~ (tmpXor >> 1)) >> 8) & 0x03)
	end

	return result
end

local input_file = io.open(arg[1], "rb")
local input_data = input_file:read("a")
input_file:close()
input_file = io.open(arg[1], "wb")

local encrypt = true
local key = tonumber(arg[2] or "484A", 16)
local i = 0

while true do
	local sector = string.sub(input_data, i*512+1, i*512+512)
	if (sector == nil) or (#sector <= 0) then break end
	
	input_file:write(crypt(sector, (key ~ i) & 0xFFFF, encrypt))

	i = i + 1
end

input_file:close()
