local _ = {
  is_enabled = false,
  has_ended = false
}

local _config

function _template.set_menu()
  _config = _current_module.config
  return {
    name = "Template",
    entries = {
      -- integer_menu_item(),
      -- list_menu_item(),
      -- checkbox_menu_item(),
      -- button_menu_item(),
      -- etc... @menu_widgets.lua
    }
  }
end

function _template.start()
  _config = _current_module.config

  -- This snippet allows for a fast character pick
  -- local p1 = {
  --   character = character_select_data.alex,
  --   color = 0,
  --   sa = 0,
  -- }
  -- local p2 = {
  --   character = character_select_data.ryu,
  --   color = 0,
  --   sa = 0,
  -- }
  -- character_select(p1, p2)

  _template.has_ended = false
end

-- If you want to add graphics over screen
local function _draw_overlay()
  -- To draw a PNG on screen
  -- gui.gdoverlay(_x, _y, _image_path)

  -- To draw text on screen
  -- gui.text(_x, _y, _text, _color, _outline_color)
end

function _template.update()
  -- Remove if you want your module to do stuff outside of match
  if not is_in_match then return end

  -- Happens at the frame you gain control over your character
  if has_match_just_started then
    -- Stuff to init for the session
  end

  -- Here goes your update logic

  -- if end_condition then
    _template.has_ended = true
  --end
end

return _template