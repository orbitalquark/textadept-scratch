-- Copyright 2023 Mitchell. See LICENSE.

--- Treat untitled buffers as scratch buffers.
--
-- Scratch buffers persist between sessions (e.g. closing and re-opening Textadept will re-open
-- any scratch buffers) unless Textadept is in "no session" mode (the `-n` or `--no-session`
-- flag was passed).
--
-- Install this module by copying it into your *~/.textadept/modules/* directory or Textadept's
-- *modules/* directory, and then putting the following in your *~/.textadept/init.lua*:
--
--	require('scratch')
-- @module scratch
local M = {}

--- The directory to temporarily save scratch files to.
-- The default value is *~/.textadept/scratch/*.
M.scratch_directory = _USERHOME .. '/scratch'
if WIN32 then M.scratch_directory = M.scratch_directory:gsub('/', '\\') end

--- Returns the current scratch directory, creating it if necessary.
local function get_scratch_directory()
	local scratch_dir = M.scratch_directory
	local mode = lfs.attributes(scratch_dir, 'mode')
	assert(not mode or mode == 'directory', 'scratch_directory must be a directory')
	if not mode then assert(lfs.mkdir(scratch_dir)) end
	return scratch_dir
end

-- Save scratch buffers on exit.
events.connect(events.QUIT, function()
	if not textadept.session.save_on_quit then return end
	local scratch_dir = get_scratch_directory()
	local i = 0
	for _, buffer in ipairs(_BUFFERS) do
		if buffer.filename or buffer._type or buffer.length == 0 then goto continue end
		local filename
		repeat
			i = i + 1
			filename = scratch_dir .. (not WIN32 and '/' or '\\') .. i
		until not lfs.attributes(filename)
		buffer:save_as(filename)
		::continue::
	end
end, 1)

-- Mark scratch buffers as Untitled after loading them from a session.
events.connect(events.SESSION_LOAD, function()
	local scratch_dir = get_scratch_directory()
	for _, buffer in ipairs(_BUFFERS) do
		if buffer.filename and buffer.filename:sub(1, #scratch_dir) == scratch_dir then
			os.remove(buffer.filename)
			buffer.filename, buffer.tab_label = nil, _L['Untitled']
			buffer:set_lexer('text') -- in case it was changed based on filename
			events.emit(events.SAVE_POINT_LEFT) -- update titlebar/tabbar as necessary
		end
	end
end)

-- Delete scratch buffers when they are closed.
events.connect(events.BUFFER_DELETED, function(buffer)
	local scratch_dir = get_scratch_directory()
	if buffer.filename and buffer.filename:sub(1, #scratch_dir) == scratch_dir then
		os.remove(buffer.filename)
	end
end)

return M
