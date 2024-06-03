-- SPDX-License-Identifier: Zlib
--
-- Copyright (c) 2024 lifehackerhansol

-- Offsets:
-- 0xC8: ARM9 ROM offset - 0xC8
-- 0xCC: ARM9 address
-- 0xD0: ARM9 size
-- 0xD4: ARM7 ROM offset - 0xC8
-- 0xD8: ARM7 address
-- 0xDC: ARM7 size

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
