-- Copyright 2020-2026 Mitchell. See LICENSE.

local scratch = require('scratch')
scratch.enabled = false -- do not interfere with tests that expect default quit behavior

test('scratch buffers should save on quit', function()
	local _<close> = test.mock(scratch, 'enabled', true)
	local _<close> = test.mock(textadept.session, 'save_on_quit', true)
	local text = test.lines{'scratch', ''}
	buffer:append_text(text)

	events.emit(events.QUIT) -- save default session
	local closed = not buffer.modify

	events.emit(events.ARG_NONE) -- load default session

	test.assert_equal(closed, true)
	test.assert_equal(buffer:get_text(), text)
	test.assert_equal(buffer.modify, true)
end)

test('scratch buffers should include typed buffers', function()
	local _<close> = test.mock(scratch, 'enabled', true)
	local _<close> = test.mock(textadept.session, 'save_on_quit', true)
	local text = 'print'
	ui.print(text)

	events.emit(events.QUIT) -- save default session
	local closed = not buffer.modify

	events.emit(events.ARG_NONE) -- load default session

	test.assert_equal(closed, true)
	test.assert_equal(buffer._type, _L['[Output Buffer]'])
	test.assert_equal(buffer:get_text(), text .. '\n')
	test.assert_equal(buffer.modify, false)
end)

test('scratch buffers should save undo history', function()
	local _<close> = test.mock(scratch, 'enabled', true)
	local _<close> = test.mock(textadept.session, 'save_on_quit', true)
	local text = test.lines{'scratch', ''}
	buffer:append_text(text)

	events.emit(events.QUIT) -- save default session
	events.emit(events.ARG_NONE) -- load default session
	local modify = buffer.modify
	buffer:undo()

	test.assert_equal(modify, true)
	test.assert_equal(buffer:get_text(), '')
end)

test('scratch buffers can be modified files', function()
	local _<close> = test.mock(scratch, 'enabled', true)
	local _<close> = test.mock(textadept.session, 'save_on_quit', true)
	local f<close> = test.tmpfile('.lua')
	io.open_file(f.filename)
	local text = 'scratch'

	buffer:append_text(text)
	events.emit(events.QUIT) -- save default session
	local closed = not buffer.modify

	events.emit(events.ARG_NONE) -- load default session

	test.assert_equal(closed, true)
	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(buffer:get_text(), text)
	test.assert_equal(buffer.modify, true)
end)

test('scratch buffers should save indicators', function()
	local _<close> = test.mock(scratch, 'enabled', true)
	local _<close> = test.mock(textadept.session, 'save_on_quit', true)
	local find = 'find'

	-- Simulate find in files results.
	ui.print_to(_L['[Files Found Buffer]'], 'file.lua:1:' .. find)
	buffer.indicator_current = ui.find.INDIC_FIND
	buffer:indicator_fill_range(buffer.line_end_position[1] - #find, #find)

	events.emit(events.QUIT) -- save default session
	events.emit(events.ARG_NONE) -- load default session

	local words = test.get_indicated_text(ui.find.INDIC_FIND)
	test.assert_equal(words, {find})
end)
