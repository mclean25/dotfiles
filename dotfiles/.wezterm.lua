local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

local home = wezterm.home_dir
local wt_script = home .. "/bin/wt"

local function notify(window, title, message)
	window:toast_notification(title, message, nil, 4000)
end

local function parse_metadata(output)
	local metadata = {}

	for line in output:gmatch("[^\r\n]+") do
		local key, value = line:match("^([%w_]+)=(.*)$")
		if key and value then
			metadata[key] = value
		end
	end

	if metadata.workspace and metadata.path then
		return metadata
	end

	return nil
end

local function run_wt(args)
	local command = { wt_script }

	for _, arg in ipairs(args) do
		table.insert(command, arg)
	end

	local success, stdout, stderr = wezterm.run_child_process(command)
	if not success then
		return nil, (stderr ~= "" and stderr) or stdout
	end

	local metadata = parse_metadata(stdout)
	if not metadata then
		return nil, (stdout ~= "" and stdout) or "missing metadata from wt"
	end

	return metadata
end

local function pane_cwd(pane)
	local cwd = pane:get_current_working_dir()
	if not cwd then
		return nil
	end

	if cwd.file_path then
		return cwd.file_path
	end

	return tostring(cwd):gsub("^file://", "")
end

local function format_pane_title(title)
	if title:match("^OC%s+|%s+") then
		return "OC"
	end

	return title
end

local function switch_to_worktree(window, pane, metadata)
	window:perform_action(
		act.SwitchToWorkspace({
			name = metadata.workspace,
			spawn = { cwd = metadata.path },
		}),
		pane
	)
end

local function prompt_for_branch(description, callback)
	return act.PromptInputLine({
		description = description,
			action = wezterm.action_callback(function(window, pane, line)
			if not line or line == "" then
				return
			end

			callback(window, pane, line)
		end),
	})
end

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
config.show_tab_index_in_tab_bar = false

wezterm.on("update-status", function(window, pane)
	window:set_left_status(wezterm.format({
		{ Background = { Color = "#7E56C0" } },
		{ Foreground = { Color = "#ffffff" } },
		{ Text = " " .. window:active_workspace() .. " " },
	}))
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
	local title = tab.tab_title
	if title == "" then
		title = format_pane_title(tab.active_pane.title)
	end

	local index = tab.tab_index + 1
	local title_text = string.format("%d: %s", index, title)
	local title_width = math.max(max_width - 4, 0)

	local bg = "#2b2b2b"
	local fg = "#a0a0a0"
	local border = "#5a5a5a"

	if tab.is_active then
		bg = "#1f1f28"
		fg = "#ffffff"
		border = "#ffffff"
	elseif hover then
		bg = "#333333"
		fg = "#d0d0d0"
	end

	return {
		{ Background = { Color = bg } },
		{ Foreground = { Color = border } },
		{ Text = "[" },
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Text = " " },
		{ Text = wezterm.truncate_right(title_text, title_width) },
		{ Text = " " },
		{ Background = { Color = bg } },
		{ Foreground = { Color = border } },
		{ Text = "]" },
	}
end)

config.keys = {
	{ key = "Enter", mods = "OPT", action = act.DisableDefaultAssignment },
	{
		key = "%",
		mods = "LEADER|SHIFT",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = '"',
		mods = "LEADER|SHIFT",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "c",
		mods = "LEADER",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "x",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			local tab = pane:tab()
			if #tab:panes() > 1 then
				win:perform_action(act.CloseCurrentPane({ confirm = true }), pane)
			else
				win:perform_action(act.CloseCurrentTab({ confirm = true }), pane)
			end
		end),
	},
	{ key = "h", mods = "CTRL", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "CTRL", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CTRL", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "CTRL", action = act.ActivatePaneDirection("Right") },
	{
		key = "s",
		mods = "LEADER",
		action = act.ShowLauncherArgs({ flags = "WORKSPACES" }),
	},
	{
		key = "w",
		mods = "LEADER",
		action = prompt_for_branch("New client-app branch", function(window, pane, branch)
			local metadata, err = run_wt({ "new", branch })
			if not metadata then
				notify(window, "wt new failed", err)
				return
			end

			switch_to_worktree(window, pane, metadata)
		end),
	},
	{
		key = "w",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			local cwd = pane_cwd(pane)
			if not cwd then
				notify(window, "wt handoff failed", "could not determine pane working directory")
				return
			end

			local shell_command = string.format("cd %q && %q handoff", cwd, wt_script)
			local success, stdout, stderr = wezterm.run_child_process({ "/bin/zsh", "-lc", shell_command })
			if not success then
				notify(window, "wt handoff failed", (stderr ~= "" and stderr) or stdout)
				return
			end

			local metadata = parse_metadata(stdout)
			if not metadata then
				notify(window, "wt handoff failed", (stdout ~= "" and stdout) or "missing metadata from wt")
				return
			end

			switch_to_worktree(window, pane, metadata)
		end),
	},
	{
		key = "o",
		mods = "LEADER",
		action = prompt_for_branch("Open existing client-app worktree", function(window, pane, branch)
			local metadata, err = run_wt({ "open", branch })
			if not metadata then
				notify(window, "wt open failed", err)
				return
			end

			switch_to_worktree(window, pane, metadata)
		end),
	},
	{
		key = "r",
		mods = "LEADER",
		action = prompt_for_branch("Remove client-app worktree", function(window, pane, branch)
			local metadata, err = run_wt({ "remove", branch })
			if not metadata then
				notify(window, "wt remove failed", err)
				return
			end

			if window:active_workspace() == metadata.workspace then
				window:perform_action(
					act.SwitchToWorkspace({
						name = "default",
						spawn = { cwd = home },
					}),
					pane
				)
			end

			notify(window, "wt remove", "Removed " .. metadata.branch)
		end),
	},
	{
		key = "n",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Project path",
			action = wezterm.action_callback(function(win, pane, line)
				if not line or line == "" then
					return
				end

				local clean = line:gsub("/+$", "")
				local name = clean:match("([^/]+)$") or clean

				win:perform_action(
					act.SwitchToWorkspace({
						name = name,
						spawn = { cwd = line },
					}),
					pane
				)
			end),
		}),
	},
	{ key = "m", mods = "LEADER", action = act.ToggleFullScreen },
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = act.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = act.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = act.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = act.ActivateTab(8) },
}

return config
