# Scratch

Treat untitled, unsaved, and typed buffers as scratch buffers.

Scratch buffers persist between sessions (e.g. closing and re-opening Textadept will re-open
any scratch buffers) unless Textadept is in "no session" mode (the `-n` or `--no-session`
flag was passed).

Install this module by copying it into your *~/.textadept/modules/* directory or Textadept's
*modules/* directory, and then putting the following in your *~/.textadept/init.lua*:

```lua
local scratch = require('scratch')
```

<a id="scratch.enabled"></a>
## `scratch.enabled`

Enable this module.

The default value is `true`.

<a id="scratch.scratch_directory"></a>
## `scratch.scratch_directory`

The directory to temporarily save scratch files to.

The default value is *~/.textadept/scratch/*.



