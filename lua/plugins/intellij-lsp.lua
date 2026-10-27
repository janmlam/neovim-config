vim.pack.add({ "https://github.com/JetBrains/intellij-lsp.nvim" })

require("intellij-lsp").setup({
	-- Server
	accept_eula = true,
	region = "europe",
	data_sharing = "none",
	filetypes = { "java" },

	-- Project
	default_sdk = "/usr/lib/jvm/default", -- Arch symlink, follows archlinux-java

	-- Completion is handled by blink.cmp
	autotrigger = false,
	word_triggers = false,
	completeopt = false,
	enter_accepts_completion = false,

	-- Handled elsewhere in this config
	keymaps = false,
	colorscheme = false, -- catppuccin
	document_highlight = false, -- kickstart-lsp-attach
	inlay_hints = false, -- <leader>th
	references = false, -- telescope gr
	signature_help = false, -- blink.cmp
	progress = false, -- fidget.nvim
	format_on_save = false, -- <leader>f via conform

	rename_files = true, -- <leader>rf
})

-- Java-only keymaps, run/debug context keys live in plugins/dap.lua
local function toggle_debug_panel()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == "intellij-lsp://debug" then
			vim.api.nvim_win_close(win, false)
			return
		end
	end
	require("intellij-lsp.debug").open()
end

local function toggle_output()
	local output = require("intellij-lsp.output")
	if output.is_open() then
		output.close()
	else
		output.open()
	end
end

local function rename_file()
	vim.ui.input({ prompt = "New path: ", default = vim.api.nvim_buf_get_name(0), completion = "file" }, function(path)
		if path and path ~= "" then
			require("intellij-lsp").rename_file(path)
		end
	end)
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("intellij-lsp-attach", { clear = true }),
	callback = function(event)
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if not client or client.name ~= "intellij" then
			return
		end

		local map = function(keys, func, desc, mode)
			vim.keymap.set(mode or "n", keys, func, { buffer = event.buf, desc = desc })
		end
		local debug = require("intellij-lsp.debug")
		local editor = require("intellij-lsp.editor")

		map("<LocalLeader>v", toggle_debug_panel, "Debug: Toggle debug [V]iew")
		map("<LocalLeader>O", toggle_output, "Toggle [O]utput panel")
		map("<LocalLeader>e", debug.evaluate_at_cursor, "[E]valuate expression", { "n", "x" })
		map("<LocalLeader>w", debug.watch_at_cursor, "[W]atch expression", { "n", "x" })

		map("<leader>ci", function()
			editor.call_hierarchy("incoming")
		end, "[C]alls [I]ncoming")
		map("<leader>co", function()
			editor.call_hierarchy("outgoing")
		end, "[C]alls [O]utgoing")
		map("<leader>cs", function()
			editor.type_hierarchy("subtypes")
		end, "[C]lass [S]ubtypes")
		map("<leader>cS", function()
			editor.type_hierarchy("supertypes")
		end, "[C]lass [S]upertypes")

		map("<leader>rf", rename_file, "[R]ename [F]ile")
	end,
})
