-- Copyright 2023-2026 Mitchell. See LICENSE.

--- Treat untitled, unsaved, and typed buffers as scratch buffers.
-- Scratch buffers persist between sessions (e.g. closing and re-opening Textadept will re-open
-- any scratch buffers) unless Textadept is in "no session" mode (the `-n` or `--no-session`
-- flag was passed).
--
-- Install this module by copying it into your *~/.textadept/modules/* directory or Textadept's
-- *modules/* directory, and then putting the following in your *~/.textadept/init.lua*:
--
-- ```lua
-- local scratch = require('scratch')
-- ```
-- @module scratch
local M = {}

--- Enable this module.
-- The default value is `true`.
M.enabled = true

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

-- Writes metadata for a given scratch file and its associated buffer.
-- Note that buffer state like selections, bookmarks, etc. is stored in the session file.
local function write_metadata(filename, buffer)
	local data = {
		filename = buffer.filename, _type = buffer._type, lexer = buffer.lexer_language,
		undo_collection = buffer.undo_collection, undo_actions = {}, undo_save = buffer.undo_save_point,
		undo_current = buffer.undo_current, undo_tentative = buffer.undo_tentative, indicators = {}
	}
	for i = 1, buffer.undo_actions do
		local action_type = buffer.undo_action_type[i]
		if action_type & 0xFF > 1 then goto continue end -- deletion is 0 and addition is 1
		local pos, text = buffer.undo_action_position[i], buffer.undo_action_text[i]
		table.insert(data.undo_actions, {action_type, pos, string.format('%q', text)})
		::continue::
	end
	if buffer._type == _L['[Files Found Buffer]'] then
		local find_indics = {}
		data.indicators[ui.find.INDIC_FIND] = find_indics
		local s = buffer:indicator_end(ui.find.INDIC_FIND, 1)
		while true do
			local e = buffer:indicator_end(ui.find.INDIC_FIND, s)
			if e == 1 or e == s then break end
			find_indics[#find_indics + 1], find_indics[#find_indics + 2] = s, e
			s = buffer:indicator_end(ui.find.INDIC_FIND, e)
		end
	end

	local f = assert(io.open(filename .. '.dat', 'wb'))
	f:write('return {')
	for k, v in pairs(data) do
		f:write(string.format('[%q]=', k))
		if type(v) == 'string' then
			f:write(string.format('%q,', v))
		elseif type(v) == 'table' then
			f:write('{')
			for k2, v2 in pairs(v) do
				local key_fmt = type(k2) == 'number' and '[%d]' or '[%q]'
				local value_fmt = type(v2) == 'table' and '{%s}' or '%s' -- TODO: write proper map
				local fmt = string.format('%s=%s,', key_fmt, value_fmt)
				v2 = type(v2) == 'table' and table.concat(v2, ',') or tostring(v2)
				f:write(string.format(fmt, k2, v2))
			end
			f:write('},')
		else
			f:write(tostring(v), ',')
		end
	end
	f:write('}'):close()
end

-- Save scratch, unsaved, and typed buffers on exit.
events.connect(events.QUIT, function()
	if not M.enabled or not textadept.session.save_on_quit then return end
	local scratch_dir = get_scratch_directory()
	local newline, strip_spaces = io.ensure_final_newline, textadept.editing.strip_trailing_spaces
	io.ensure_final_newline, textadept.editing.strip_trailing_spaces = false, false -- leave alone

	local i = 0
	for _, buffer in ipairs(_BUFFERS) do
		if (buffer.filename and not buffer.modify) or buffer.length == 0 then goto continue end
		local filename
		repeat
			i = i + 1
			filename = scratch_dir .. (not WIN32 and '/' or '\\') .. i
		until not lfs.attributes(filename)
		write_metadata(filename, buffer)
		buffer:save_as(filename)
		::continue::
	end

	io.ensure_final_newline, textadept.editing.strip_trailing_spaces = newline, strip_spaces
end, 1)

-- Restore a scratch buffer after loading it (most likely from a session).
events.connect(events.FILE_OPENED, function(filename)
	local scratch_dir = get_scratch_directory()
	if filename:sub(1, #scratch_dir) ~= scratch_dir then return end
	local metadata = filename .. '.dat'
	if lfs.attributes(metadata) then
		local data = assert(loadfile(metadata, 't', {}))()

		-- Restore buffer details (filename, typed, or Untitled) and lexer.
		buffer.filename, buffer._type = data.filename, data._type
		buffer:set_lexer(data.lexer)

		-- Restore undo history.
		buffer.undo_collection = data.undo_collection
		if buffer.undo_collection then
			for _, action in ipairs(data.undo_actions) do
				buffer:push_undo_action_type(action[1], action[2])
				buffer:change_last_undo_action_text(action[3])
			end
			buffer.undo_save_point = data.undo_save
			buffer.undo_current = data.undo_current
			buffer.undo_tentative = data.undo_tentative
		end

		events.emit(events.SAVE_POINT_LEFT) -- update titlebar and tab label

		-- Restore indicators.
		for indic, ranges in pairs(data.indicators or {}) do
			buffer.indicator_current = indic
			for i = 1, #ranges, 2 do
				buffer:indicator_fill_range(ranges[i], ranges[i + 1] - ranges[i])
			end
		end

		os.remove(metadata)
	end
	os.remove(filename)
end)

-- Do not enable this module if a startup error occurs.
local function disable() M.enabled = false end
events.connect(events.ERROR, disable)
events.connect(events.INITIALIZED, function() events.disconnect(events.ERROR, disable) end)

return M
