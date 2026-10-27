vim.pack.add({
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/rcarriga/nvim-dap-ui",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/jay-babu/mason-nvim-dap.nvim",
	"https://github.com/leoluz/nvim-dap-go",
	"https://github.com/MunifTanjim/nui.nvim",
})

-- Basic debugging keymaps, feel free to change to your liking!
local dap = require("dap")

vim.keymap.set("n", "<LocalLeader>b", function()
	dap.toggle_breakpoint()
end, { desc = "Debug: Toggle Breakpoint" })

vim.keymap.set("n", "<LocalLeader>B", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Set Breakpoint" })

vim.keymap.set("n", "<LocalLeader>X", function()
	dap.clear_breakpoints()
end, { desc = "Debug: Clear all breakpoints" })

vim.keymap.set("n", "<LocalLeader>L", function()
	dap.list_breakpoints(true)
end, { desc = "Debug: [L]ist breakpoints" })

vim.keymap.set("n", "<LocalLeader>v", function()
	require("dapui").toggle()
end, { desc = "Debug: Toggle debug [V]iew" })

vim.keymap.set("n", "<LocalLeader>n", function()
	dap.step_over()
end, { desc = "Debug: Step over ([N]ext)" })

vim.keymap.set("n", "<LocalLeader>i", function()
	dap.step_into()
end, { desc = "Debug: Step [I]nto" })

vim.keymap.set("n", "<LocalLeader>o", function()
	dap.step_out()
end, { desc = "Debug: Step [O]ut" })

local dapui = require("dapui")

require("mason-nvim-dap").setup({
	-- Makes a best effort to setup the various debuggers with
	-- reasonable debug configurations
	automatic_installation = true,

	-- You can provide additional configuration to the handlers,
	-- see mason-nvim-dap README for more information
	handlers = {},

	-- You'll need to check that you have the required things installed
	-- online, please don't ask me how to install them :)
	ensure_installed = {
		-- Update this to ensure that you have the debuggers for the langs you want
		"delve",
	},
})

-- Dap UI setup
-- For more information, see |:help nvim-dap-ui|
---@diagnostic disable-next-line: missing-fields
dapui.setup({
	-- Set icons to characters that are more likely to work in every terminal.
	--    Feel free to remove or use ones that you like more! :)
	--    Don't feel like these are good choices.
	icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
	---@diagnostic disable-next-line: missing-fields
	controls = {
		icons = {
			pause = "⏸",
			play = "▶",
			step_into = "⏎",
			step_over = "⏭",
			step_out = "⏮",
			step_back = "b",
			run_last = "▶▶",
			terminate = "⏹",
			disconnect = "⏏",
		},
	},
})

-- Change breakpoint icons
vim.api.nvim_set_hl(0, "DapBreak", { fg = "#e51400" })
vim.api.nvim_set_hl(0, "DapStop", { fg = "#ffcc00" })
local breakpoint_icons = vim.g.have_nerd_font
		and {
			Breakpoint = "",
			BreakpointCondition = "",
			BreakpointRejected = "",
			LogPoint = "",
			Stopped = "",
		}
	or { Breakpoint = "●", BreakpointCondition = "⊜", BreakpointRejected = "⊘", LogPoint = "◆", Stopped = "⭔" }
for type, icon in pairs(breakpoint_icons) do
	local tp = "Dap" .. type
	local hl = (type == "Stopped") and "DapStop" or "DapBreak"
	vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
end

-- intellij-lsp has its own debug panel for Java sessions
local function unless_intellij(fn)
	return function(session)
		if session.config.type ~= "intellij_jvm" then
			fn()
		end
	end
end
dap.listeners.after.event_initialized["dapui_config"] = unless_intellij(dapui.open)
dap.listeners.before.event_terminated["dapui_config"] = unless_intellij(dapui.close)
dap.listeners.before.event_exited["dapui_config"] = unless_intellij(dapui.close)

-- Install golang specific config
require("dap-go").setup({
	delve = {
		detached = vim.fn.has("win32") == 0,
	},
})

dap.configurations.go = {
	{
		type = "delve",
		name = "Debug",
		request = "launch",
		program = "${file}",
	},
	{
		type = "delve",
		name = "Debug test", -- configuration for debugging test files
		request = "launch",
		mode = "test",
		program = "${file}",
	},
	-- works with go.mod packages and sub packages
	{
		type = "delve",
		name = "Debug test (go.mod)",
		request = "launch",
		mode = "test",
		program = "./${relativeFileDirname}",
	},
}

-- Context run/debug (IntelliJ's ContextRun, ContextDebug, Rerun)
-- Java goes through intellij-lsp, Go through dap-go/delve.
local last_run = nil

local function context(no_debug)
	local ft = vim.bo.filetype
	if ft == "java" then
		last_run = { lang = "java", uri = vim.uri_from_bufnr(0), no_debug = no_debug }
		require("intellij-lsp.run").run_at_cursor(no_debug)
	elseif ft == "go" then
		last_run = { lang = "go" }
		-- closest_test needs the go treesitter parser
		local ok, test = pcall(require("dap-go-ts").closest_test)
		if not ok then
			vim.notify("No go treesitter parser, running the file instead of the test", vim.log.levels.WARN)
		end
		if ok and test.name and test.name ~= "" then
			require("dap-go").debug_test({ noDebug = no_debug })
		else
			dap.run(vim.tbl_extend("force", dap.configurations.go[1], {
				name = no_debug and "Run" or "Debug",
				noDebug = no_debug,
			}))
		end
	else
		vim.notify(("No context run for %s"):format(ft), vim.log.levels.WARN)
	end
end

-- The main class is only known once intellij-lsp has resolved it
dap.listeners.after.event_initialized["context_rerun"] = function(session)
	if session.config.type == "intellij_jvm" and last_run and last_run.lang == "java" then
		last_run.main_class = session.config.mainClass
	end
end

local function rerun()
	if not last_run then
		vim.notify("Nothing to rerun", vim.log.levels.WARN)
	elseif last_run.lang == "java" then
		if not last_run.main_class then
			vim.notify("Nothing to rerun", vim.log.levels.WARN)
			return
		end
		-- Not dap.run_last(): launch() rebuilds before running
		require("intellij-lsp.run").launch(last_run.main_class, last_run.uri, last_run.no_debug)
	else
		dap.run_last()
	end
end

local function is_intellij(session)
	return session ~= nil and session.config.type == "intellij_jvm"
end

vim.keymap.set("n", "<LocalLeader>r", function()
	context(true)
end, { desc = "[R]un context" })

vim.keymap.set("n", "<LocalLeader>d", function()
	context(false)
end, { desc = "[D]ebug context" })

vim.keymap.set("n", "<LocalLeader>R", rerun, { desc = "[R]erun last run/debug" })

vim.keymap.set("n", "<LocalLeader>c", function()
	local session = dap.session()
	if is_intellij(session) then
		require("intellij-lsp.debug").continue()
	elseif session then
		dap.continue()
	else
		vim.notify("No debug session, start one with <LocalLeader>d", vim.log.levels.WARN)
	end
end, { desc = "Debug: [C]ontinue" })

vim.keymap.set("n", "<LocalLeader>q", function()
	local session = dap.session()
	-- intellij-lsp's stop also cancels a build that has not launched yet
	if is_intellij(session) or (not session and vim.bo.filetype == "java") then
		require("intellij-lsp.run").stop()
	elseif session then
		dap.terminate()
	end
end, { desc = "[Q]uit run/debug session" })
