-- Copyright 2020-2024 Mitchell. See LICENSE.

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
	test.assert_equal(buffer.modify, false)
end)
