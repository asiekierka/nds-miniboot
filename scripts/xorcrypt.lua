-- SPDX-License-Identifier: Zlib
--
-- Copyright (c) 2024 lifehackerhansol

local input_file <close> = io.open(arg[1], "r+b")
local key = tonumber(arg[2], 16)

-- Encrypt header
if key ~= 0 then
    input_file:seek("set", 0)
    header = input_file:read(512)
    local encryptedHeader = ""
    for i=1,512 do encryptedHeader = encryptedHeader .. string.char(string.byte(header, i) ~ key) end

    -- Write encrypted header
    input_file:seek("set", 0x000)
    input_file:write(encryptedHeader)
end
