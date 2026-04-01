local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"Symbols Nerd Font Mono",
})
config.font_size = 14.0

config.leader = { key = " ", mods = "CTRL", timeout_milliseconds = 1000 }

config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.hide_tab_bar_if_only_one_tab = false

wezterm.on("update-status", function(window, pane)
	window:set_left_status(wezterm.format({
		{ Background = { Color = "#7E56C0" } },
		{ Foreground = { Color = "#ffffff" } },
		{ Text = " [" .. window:active_workspace() .. "] " },
	}))
end)

config.keys = {
	{ key = "Enter", mods = "OPT", action = wezterm.action.DisableDefaultAssignment },
	{
		key = "%",
		mods = "LEADER|SHIFT",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = '"',
		mods = "LEADER|SHIFT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "x",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			local tab = pane:tab()
			if #tab:panes() > 1 then
				win:perform_action(wezterm.action.CloseCurrentPane({ confirm = true }), pane)
			else
				win:perform_action(wezterm.action.CloseCurrentTab({ confirm = true }), pane)
			end
		end),
	},
	{ key = "h", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "j", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "l", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Right") },
	{
		key = "s",
		mods = "LEADER",
		action = wezterm.action.ShowLauncherArgs({ flags = "WORKSPACES" }),
	},
	{
		key = "n",
		mods = "LEADER",
		action = wezterm.action.PromptInputLine({
			description = "Project path",
			action = wezterm.action_callback(function(win, pane, line)
				if not line or line == "" then
					return
				end

				local clean = line:gsub("/+$", "")
				local name = clean:match("([^/]+)$") or clean

				win:perform_action(
					wezterm.action.SwitchToWorkspace({
						name = name,
						spawn = { cwd = line },
					}),
					pane
				)
			end),
		}),
	},
	{ key = "m", mods = "LEADER", action = wezterm.action.ToggleFullScreen },
	{ key = "1", mods = "LEADER", action = wezterm.action.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = wezterm.action.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = wezterm.action.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = wezterm.action.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = wezterm.action.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = wezterm.action.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = wezterm.action.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = wezterm.action.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = wezterm.action.ActivateTab(8) },
}

return config
