local ffi = require 'ffi'
local istype = ffi.istype
local sizeof = ffi.sizeof
local cbor = require './cbor'
local encode = cbor.encode
local decode = cbor.decode
local bin = cbor.bin
local buf = cbor.buf

local function equal(a, b)
  if a == b then return true end
  local ta = type(a)
  local tb = type(b)
  if ta ~= tb then return false end
  if ta == 'table' then
    local keys = {}
    local key
    while true do
      key = next(a, key)
      if not key then break end
      if not equal(a[key], b[key]) then return false end
      keys[key] = true
    end
    key = nil
    while true do
      key = next(b, key)
      if not key then break end
      if not keys[key] then return false end
      keys[key] = nil
    end
    return not next(keys)
  elseif ta == 'cdata' then
    if istype(buf, a) and istype(buf, b) then
      if sizeof(a) ~= sizeof(b) then return false end
      for i = 0, sizeof(a) - 1 do
        if a[i] ~= b[i] then return false end
      end
      return true
    end
    return a == b
  else
    error 'TODO: handle more types'
  end
end

local tests = {
  0, '\x00',
  1, '\x01',
  10, '\x0a',
  23, '\x17',
  24, '\x18\x18',
  25, '\x18\x19',
  100, '\x18\x64',
  1000, '\x19\x03\xe8',
  1000000, '\x1a\x00\x0f\x42\x40',
  -- 1000000000000, '\x1b\x00\x00\x00\xe8\xd4\xa5\x10\x00',
  1000000000000ULL, '\x1b\x00\x00\x00\xe8\xd4\xa5\x10\x00',
  -1, '\x20',
  -10, '\x29',
  -100, '\x38\x63',
  -1000, '\x39\x03\xe7',
  false, '\xf4',
  true, '\xf5',
  nil, '\xf6',
  bin(''), '\x40',
  bin('\x01\x02\x03\x04'), '\x44\x01\x02\x03\x04',
  '', '\x60',
  'a', '\x61\x61',
  'IETF', '\x64\x49\x45\x54\x46',
  {}, '\x80',
  {1, 2, 3}, '\x83\x01\x02\x03',
  {1, {2, 3}, {4, 5}}, '\x83\x01\x82\x02\x03\x82\x04\x05',
  {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25},
  '\x98\x19\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x18\x18\x19',
  {[1] = 2, [3] = 4}, '\xa2\x03\x04\x01\x02',
  {a = 1, b = {2, 3}}, '\xa2\x61\x61\x01\x61\x62\x82\x02\x03',
  {'a', {b = 'c'}}, '\x82\x61\x61\xa1\x61\x62\x61\x63',
}

for i = 1, #tests, 2 do
  print()
  local diag = tests[i]
  local serialized = tests[i + 1]
  p('value   ', diag, #serialized + 1)
  p('expected', serialized)
  local actual = encode(diag)
  p('encoded ', actual)
  assert(actual == serialized)
  local decoded, size = decode(serialized, 1)
  p('decoded ', decoded, size)
  assert(size == #serialized + 1)
  assert(equal(diag, decoded))
end

p(encode{name='Tim',age=36,programmer=true})
