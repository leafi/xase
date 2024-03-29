local utf8 = require'utf8'

assert(utf8.next('') == nil)
assert(utf8.next('a') == 1)
assert(utf8.next('ab', 1) == 2)
assert(utf8.next('ab', 2) == nil)

assert(utf8.len('') == 0)
assert(utf8.len('a') == 1)
assert(utf8.len('ab') == 2)

assert(utf8.byte_index('', -1) == nil)
assert(utf8.byte_index('', 0) == nil)
assert(utf8.byte_index('', 1) == nil)
assert(utf8.byte_index('', 2) == nil)
assert(utf8.byte_index('abc', 3) == 3)
assert(utf8.byte_index('abc', 5) == nil)

assert(utf8.char_index('', -1) == nil)
assert(utf8.char_index('', 0) == nil)
assert(utf8.char_index('', 1) == nil)
assert(utf8.char_index('', 2) == nil)
assert(utf8.char_index('abc', 3) == 3)
assert(utf8.char_index('abc', 5) == nil)

assert(utf8.prev('', -1) == nil)
assert(utf8.prev('', 0) == nil)
assert(utf8.prev('', 1) == nil)
assert(utf8.prev('', 2) == nil)
assert(utf8.prev('a', 1) == nil)
assert(utf8.prev('a', 2) == 1)
assert(utf8.prev('a', 3) == nil)
assert(utf8.prev('abc', 4) == 3)
assert(utf8.prev('abc', 3) == 2)
assert(utf8.prev('abc', 2) == 1)
assert(utf8.prev('abc', 1) == nil)

local ii =   100; for i in utf8.byte_indices_reverse(string.rep('a',   100)) do assert(i == ii); ii = ii - 1 end
local ii = 10000; for i in utf8.byte_indices_reverse(string.rep('a', 10000)) do assert(i == ii); ii = ii - 1 end

--TODO: utf8.prev

assert(utf8.sub('abc', 1, 2) == 'ab')
assert(utf8.sub('abc', 2, 5) == 'bc')
assert(utf8.sub('abc', 2, 0) == '')
assert(utf8.sub('abc', 2, 1) == '')
assert(utf8.sub('abc', 3, 3) == 'c')

assert(utf8.sub('abçd', 2, 3) == 'bç')

assert(utf8.contains('abcde', 3, 'cd') == true)
assert(utf8.contains('abcde', 2, '') == true)
assert(utf8.contains('abcde', 5, 'x') == false)

assert(utf8.count('\n\r \n \r \r\n \n\r', '\n\r') == 2)
assert(utf8.count('', 'x') == 0)

assert(utf8.lower('') == '')
assert(utf8.upper('') == '')
assert(utf8.lower('aXbYcZd') == 'axbyczd')
assert(utf8.upper('AxByCzD') == 'AXBYCZD')

--validation
--source: http://www.cl.cam.ac.uk/~mgk25/ucs/examples/UTF-8-test.txt

local valid = utf8.validate

local function invalid(s)
	assert(not pcall(valid, s))
end

valid('κόσμε')
--2.1  First possible sequence of a certain length
valid(' ')
valid('')
valid('ࠀ')
valid('𐀀')
--valid('�����') --5 bytes
--valid('������') --6 bytes
--2.2  Last possible sequence of a certain length
valid('')
valid('߿')
--valid('￿') --non-char uFFFF
--valid('����') --4 bytes out of range
--valid('�����') --5 bytes
--valid('������') --6 bytes
--2.3  Other boundary conditions
valid('퟿')
valid('')
valid('�')
valid('􏿿')
--3.1  Unexpected continuation bytes
invalid('�')
invalid('�')
invalid('��')
invalid('���')
invalid('����')
invalid('�����')
invalid('������')
invalid('�������')
--3.1.9  Sequence of all 64 possible continuation bytes (0x80-0xbf):
invalid('����������������������������������������������������������������')
--3.2  Lonely start characters
--3.2.1  All 32 first bytes of 2-byte sequences (0xc0-0xdf), each followed by a space character:
invalid('� � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � ')
--3.2.2  All 16 first bytes of 3-byte sequences (0xe0-0xef), each followed by a space character:
invalid('� � � � � � � � � � � � � � � � ')
--3.2.3  All 8 first bytes of 4-byte sequences (0xf0-0xf7), each followed by a space character:
invalid('� � � � � � � � ')
--3.2.4  All 4 first bytes of 5-byte sequences (0xf8-0xfb), each followed by a space character:
invalid('� � � � ')
--3.2.5  All 2 first bytes of 6-byte sequences (0xfc-0xfd), each followed by a space character:
invalid('� � ')
--3.3  Sequences with last continuation byte missing
invalid('�')
invalid('��')
invalid('���')
invalid('����')
invalid('�����')
invalid('�')
invalid('�')
invalid('���')
invalid('����')
invalid('�����')
--3.4  Concatenation of incomplete sequences
invalid('�����������������������������')
--3.5  Impossible bytes
invalid('�')
invalid('�')
invalid('����')
--4.1  Examples of an overlong ASCII character
invalid('��')
invalid('���')
invalid('����')
invalid('�����')
invalid('������')
--4.2  Maximum overlong sequences
invalid('��')
invalid('���')
invalid('����')
invalid('�����')
invalid('������')
--4.3  Overlong representation of the NUL character
invalid('��')
invalid('���')
invalid('����')
invalid('�����')
invalid('������')
--5.1 Single UTF-16 surrogates
invalid('���')
invalid('���')
invalid('���')
invalid('���')
invalid('���')
invalid('���')
invalid('���')
--5.2 Paired UTF-16 surrogates
invalid('������')
invalid('������')
invalid('������')
invalid('������')
invalid('������')
invalid('������')
invalid('������')
invalid('������')
--5.3 Other illegal code positions
invalid('￾')
invalid('￿')

-- sanitization (same strings as above)

local function sanitize(s)
	valid(utf8.sanitize(s))
end

sanitize('�')
sanitize('�')
sanitize('��')
sanitize('���')
sanitize('����')
sanitize('�����')
sanitize('������')
sanitize('�������')
sanitize('� � � � � � � � � � � � � � � � ')
sanitize('� � � � � � � � ')
sanitize('� � � � ')
sanitize('� � ')
sanitize('�')
sanitize('��')
sanitize('���')
sanitize('����')
sanitize('�����')
sanitize('�')
sanitize('�')
sanitize('���')
sanitize('����')
sanitize('�����')
sanitize('�����������������������������')
sanitize('�')
sanitize('�')
sanitize('����')
sanitize('��')
sanitize('���')
sanitize('����')
sanitize('�����')
sanitize('������')
sanitize('��')
sanitize('���')
sanitize('����')
sanitize('�����')
sanitize('������')
sanitize('��')
sanitize('���')
sanitize('����')
sanitize('�����')
sanitize('������')
sanitize('���')
sanitize('���')
sanitize('���')
sanitize('���')
sanitize('���')
sanitize('���')
sanitize('���')
sanitize('������')
sanitize('������')
sanitize('������')
sanitize('������')
sanitize('������')
sanitize('������')
sanitize('������')
sanitize('������')
sanitize('￾')
sanitize('￿')

