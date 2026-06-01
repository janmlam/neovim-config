return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	keys = {
		{ "<leader>cc", "<cmd>CodeCompanionChat<cr>", desc = "CodeCompanion Chat" },
		{ "<leader>ca", "<cmd>CodeCompanionAction<cr>", desc = "CodeCompanion Action" },
	},
	opts = {
		adapters = {
			http = {
				-- This name ("openwebui") must match interactions.chat.adapter
				openwebui = function()
					return require("codecompanion.adapters").extend("openai_compatible", {
						env = {
							-- Base URL for your server
							url = "https://gpt.uio.no",
							-- Paths for OpenAI-compatible endpoints
							chat_url = "/api/v1/chat/completions",
							models_endpoint = "/api/v1/models", -- or leave as default if unused
							api_key = "GPTUIOKEY",
						},

						-- Default parameters
						parameters = {
							model = "gpt-oss-120b",
						},

						-- IMPORTANT: override schema.model so it doesn't auto-call /models
						schema = {
							model = {
								order = 1,
								mapping = "parameters",
								type = "string",
								desc = "Model ID",
								default = "gpt-oss-120b",
								choices = { "gpt-oss-120b" }, -- adjust to your available models
							},
						},
					})
				end,
			},
		},

		interactions = {
			chat = {
				adapter = "openwebui", -- must match the key under adapters.http
				model = "gpt-oss-120b",
			},
			inline = {
				adapter = "openwebui",
				model = "gpt-oss-120b",
			},
		},
	},
}
