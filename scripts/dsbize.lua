-- SPDX-License-Identifier: Zlib
--
-- Copyright (c) 2024 Adrian "asie" Siekierka
-- Copyright (c) 2024 lifehackerhansol

-- Offsets:
-- 0xC8: ARM9 ROM offset - 0xC8
-- 0xCC: ARM9 address
-- 0xD0: ARM9 size
-- 0xD4: ARM7 ROM offset - 0xC8
-- 0xD8: ARM7 address
-- 0xDC: ARM7 size

-- GBATEK swiCRC16 pseudocode
-- https://problemkaputt.de/gbatek-bios-misc-functions.htm
function crc16(data, size)
    local crc = 0xFFFF
    local i = 1
    for i=1,size do
        crc = crc ~ string.byte(data, i)
        for j=1,8 do
            carry = (crc & 0x0001) > 0
            crc = crc >> 1
            if carry then
                crc = crc ~ 0xA001
            end
        end
    end
    return crc
end

function read32(file, offset)
    file:seek("set", offset)
    return string.unpack("<I4", file:read(4))
end

function write32(file, offset, data)
    file:seek("set", offset)
    file:write(string.pack("<I4", data))
    return
end

local input_file <close> = io.open(arg[1], "r+b")
local encrypt = true
local key = tonumber(arg[2], 16)
local i = 0

-- Read ARM/ARM7 location data
local arm9romOffset = read32(input_file, 0x20)
local arm9executeAddress = read32(input_file, 0x24)
local arm9destination = read32(input_file, 0x28)
local arm9binarySize = read32(input_file, 0x2C)
local arm7romOffset = read32(input_file, 0x30)
local arm7executeAddress = read32(input_file, 0x34)
local arm7destination = read32(input_file, 0x38)
local arm7binarySize = read32(input_file, 0x3C)

-- Verify execution address and destination is identical.
-- That's all the M3 supports.
if arm9executeAddress ~= arm9destination
then
    error("e9 != r9. Rebuild ROM using ndstool.")
    exit()
end
if arm7executeAddress ~= arm7destination
then
    error("e7 != r7. Rebuild ROM using ndstool.")
    exit()
end

-- Write addresses to the DSBooter expected area
-- ldr pc, [pc,#0x10]
write32(input_file, 0xC0, 0xE59FF010)
-- ldr pc, [pc,#0x0C]
write32(input_file, 0xC4, 0xE59FF00C)
write32(input_file, 0xC8, arm9romOffset - 0xC8)
write32(input_file, 0xCC, arm9destination)
write32(input_file, 0xD0, arm9binarySize)
write32(input_file, 0xD4, (arm7romOffset - 0xC8))
write32(input_file, 0xD8, arm7destination)
write32(input_file, 0xDC, arm7binarySize)

-- Fix logo(?) CRC
input_file:seek("set", 0xC0)
local logo = input_file:read(0x9C)
local logoCRC = crc16(logo, 0x9C)
input_file:seek("set", 0x15C)
input_file:write(string.pack("<I2", logoCRC))

-- Fix header CRC
input_file:seek("set", 0)
local header = input_file:read(512)
local headerCRC = crc16(header, 0x15E)
input_file:seek("set", 0x15E)
input_file:write(string.pack("<I2", headerCRC))

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
