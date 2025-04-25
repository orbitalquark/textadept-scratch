-- Copyright 2020-2025 Mitchell. See LICENSE.

local scratch = require('scratch')
scratch.enabled = false -- do not interfere with tests that expect default quit behavior

test('scratch buffers should save on quit', function()
	local _<close> = test.mock(scratch, 'enabled', true)
	local _<close> = test.mock(textadept.session, 'save_on_quit', true)
	local text = test.lines{'scratch', ''}
	buffer:append_text(text)

	events.emit(events.QUIT)
	local closed = not buffer.modify

	events.emit(events.SESSION_LOAD)

	test.assert_equal(closed, true)
	test.assert_equal(buffer:get_text(), text)
	test.assert_equal(buffer.modify, true)
end)

test('scratch buffers should include typed buffers', function()
	local _<close> = test.mock(scratch, 'enabled', true)
	local _<close> = test.mock(textadept.session, 'save_on_quit', true)
	local text = 'print'
	ui.print(text)

	events.emit(events.QUIT)
	local closed = not buffer.modify

	events.emit(events.SESSION_LOAD)

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

	events.emit(events.QUIT)
	local closed = not buffer.modify

	events.emit(events.SESSION_LOAD)
	local can_undo = buffer:can_redo()
	buffer:undo()

	test.assert_equal(can_undo, true)
	test.assert_equal(buffer:get_text(), '')
end)

test('scratch buffers can be modified files', function()
	local _<close> = test.mock(scratch, 'enabled', true)
	local _<close> = test.mock(textadept.session, 'save_on_quit', true)
	local f<close> = test.tmpfile('.lua')
	io.open_file(f.filename)
	local text = 'scratch'

	buffer:append_text(text)
	events.emit(events.QUIT)
	local closed = not buffer.modify

	events.emit(events.SESSION_LOAD)

	test.assert_equal(closed, true)
	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(buffer:get_text(), text)
	test.assert_equal(buffer.modify, true)
end)
