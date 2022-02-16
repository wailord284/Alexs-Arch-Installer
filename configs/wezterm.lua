local wezterm = require 'wezterm';

wezterm.on("update-right-status", function(window, pane)
  -- "Wed Mar 3 08:14"
  local date = wezterm.strftime("%a %b %-d %H:%M ");

  local bat = ""
  for _, b in ipairs(wezterm.battery_info()) do
    bat = "🔋 " .. string.format("%.0f%%", b.state_of_charge * 100)
  end

  window:set_right_status(wezterm.format({
    {Text=bat .. "   "..date},
  }));
end)

return {
	color_scheme = "Dracula",
	enable_scroll_bar=true,
	scrollback_lines = 8192,
	window_background_opacity = 0.95,
	text_background_opacity = 1.0,
	font_size = 14.0,
	font = wezterm.font("IBM Plex Mono", {weight="Medium"}),
	initial_cols = 90,
	initial_rows = 26,
}
