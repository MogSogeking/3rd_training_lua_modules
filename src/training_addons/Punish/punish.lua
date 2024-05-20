local _punish = {
  is_enabled = false,
  has_ended = false,
  json_folder_path = "src/training_addons/Punish/data/",
  training_menu = make_menu(100, 49, 283, 170, -- screen size 383,223
    {}
  ),
}

local _config
local _addresses = {
  gill =       {},
  alex =       {},
  ryu =        {},
  yun =        {},
  dudley =     {},
  necro =      read_object_from_json_file("data/sfiii3nr1/moves_hex/necro_moves_hex.json"),
  hugo =       {},
  ibuki =      {},
  elena =      {},
  oro =        {},
  yang =       {},
  ken =        {},
  sean =       {},
  urien =      {},
  gouki =      {},
  shinGouki =  {},
  chunli =     {},
  makoto =     {},
  q =          {},
  twelve =     {},
  remy =       {}
}

local _collection = {
  character = 1,
  character_list = {},
  continue = false,
  offset = 0,
}

local _characters = {
    "Favorite",
    "Alex",
    "ChunLi",
    "Dudley",
    "Elena",
    "Gill",
    "Gouki",
    "Hugo",
    "Ibuki",
    "Ken",
    "Makoto",
    "Necro",
    "Oro",
    "Q",
    "Remy",
    "Ryu",
    "Sean",
    "Twelve",
    "Urien",
    "Yang",
    "Yun",
}

local side = {
  "Left",
  "Right",
}

local swap_side = {
  "No",
  "Halfway",
  "Random",
}

local _current_character_adresses = {}
local _current_punish_combo = {}
local _current_combo_step = 1
local _current_side = 0
local _punished = 0
local _miss_punished = 0
local _guard_punished = 0
local _state = "Idle"
local restart_sequence = true
local swapped = false

local _character_select = list_menu_item("Character", _collection, "character", _collection.character_list)
_character_select.is_disabled = function ()
  return #_collection.character_list < 2
end

local _tmp_config = {
  character = 1,
  opponent = 1,
  punish = 1,
  total_punished = 5,
  side = 1,
  swap_side = 1,
  continue = false,
  offset = 0,
}

local function TableConcat(t1,t2)
    for _key, _value in pairs(t2) do
        t1[_key] = _value
    end
    return t1
end

local function get_punishes_array(character_index, opponent_index)
  local _result = {}
  local _character_name = _collection.character_list[character_index]
  local _opponent_name = _collection[_character_name].opponent_list[opponent_index]
  for _key, _value in pairs(_collection[_character_name][_opponent_name]) do
    if _key ~= "punish" then
      table.insert(_result, _key)
    end
  end
  return _result
end

local function get_opponent_list(_list)
  if _list == nil or #_list == 0 or string.lower(_list[1]) == "any" then return _characters end
  local _result = TableConcat({}, _list)
  table.insert(_result, 1, "Favorite")
  return _result
end

local function get_selected_punish(_character, _opponent)
  _character = _character or _collection.character
  local _p1 = _collection.character_list[_character]
  _opponent = _opponent or _collection[_p1].opponent
  local _opponent_name = _collection[_p1].opponent_list[_opponent]
  local _punishes_array = get_punishes_array(_character, _opponent)
  local _punish_index = _collection[_p1][_opponent_name].punish
  return _collection[_p1][_opponent_name][_punishes_array[_punish_index]]
end

local function build_collection(json_path_list)

  local _saved_collection = read_object_from_json_file("src/training_addons/Punish/punishes_collection.json")
  if _saved_collection ~= nil and #_saved_collection > 0 then
    _collection = _saved_collection
  end

  for _key, _value in pairs(json_path_list) do
    local _json = read_object_from_json_file(_value)
    if _json ~= nil and _json.character ~= nil and _json.opponent ~= nil and _json.list ~= nil then
      if _collection[_json.character] == nil then
        _collection[_json.character] = {}
        _collection[_json.character].opponent = 1
        _collection[_json.character][_json.opponent] = _json.list
        _collection[_json.character][_json.opponent].punish = 1
        _collection[_json.character]["opponent_list"] = {_json.opponent}
        table.insert(_collection["character_list"], _json.character)
      elseif _collection[_json.character][_json.opponent] == nil then
        _collection[_json.character][_json.opponent] = _json.list
        _collection[_json.character][_json.opponent].punish = 1
        table.insert(_collection[_json.character]["opponent_list"], _json.opponent)
      else
        _collection[_json.character][_json.opponent] = TableConcat(_collection[_json.character][_json.opponent], _json.list)
      end
    end
  end

  for _key, _value in pairs(_collection) do
    if _key ~= "character" and _key ~= "character_list" and _key ~= "continue" and _key ~= "offset" then
      for _key_2, _value_2 in pairs(_value) do
        if _key_2 ~= "opponent" and _key_2 ~= "opponent_list" then
          for _key_3, _value_3 in pairs(_value_2) do
            if _key_3 ~= "punish" then
              _value_3.side = _value_2.side or 1
              _value_3.swap_side = _value_2.swap_side or 1
              _value_3.enabled = _value_2.enabled or true
              _value_3.total_punished = _value_2.total_punished or 5
              table.insert(_value_3.p1_rec, {""})
              table.insert(_value_3.p2_rec, {""})
            end
          end
        end
      end
    end
  end
end

local function build_entries(_character_index, _opponent_index, _character_object, _menu_type)
  local _punishes_array = get_punishes_array(_character_index, _opponent_index)
  local _current_punish = get_selected_punish()
  local _opponent_object = _character_object[_character_object.opponent_list[_opponent_index]]

  local _opponent_select = list_menu_item("Opponent", _character_object, "opponent", _character_object.opponent_list)
  _opponent_select.is_disabled = function ()
    return #_character_object.opponent_list < 2
  end

  _character_select.list = _collection.character_list

  if _menu_type == "Contextual" then
    local _character_select = list_menu_item("Character", _tmp_config, "character", _collection.character_list)
    _character_select.is_disabled = function ()
      return #_collection.character_list < 2
    end

    local _p1 = _collection.character_list[_tmp_config.character]
    _punishes_array = get_punishes_array(_tmp_config.character, _tmp_config.opponent)

    local _opponent_select = list_menu_item("Opponent", _tmp_config, "opponent", _collection[_p1].opponent_list)
    _opponent_select.is_disabled = function ()
      return #_collection[_p1].opponent_list < 2
    end

    if #_punishes_array < _tmp_config.punish then
      _tmp_config.punish = 1
    end

    return {
      _character_select,
      _opponent_select,
      list_menu_item("punish", _tmp_config, "punish", _punishes_array),
      integer_menu_item("Total punishes", _tmp_config, "total_punished", 0, 100, true, 5),
      list_menu_item("Side", _tmp_config, "side", side),
      list_menu_item("Swap side", _tmp_config, "swap_side", swap_side),
      integer_menu_item("Offset frames before replay", _tmp_config, "offset", 0, 180, true, 0),
      checkbox_menu_item("Continue beyond total punishes", _tmp_config, "continue", false),
      button_menu_item("Restart", function()
        _punish.apply_changes()
      end),
      button_menu_item("Quit", function()
        _current_module.quit_training()
      end),
    }
  end

  return {
      _character_select,
      _opponent_select,
      list_menu_item("punish", _opponent_object, "punish", _punishes_array),
      checkbox_menu_item("Enabled in routine", _current_punish, "enabled", true),
      integer_menu_item("Total punishes", _current_punish, "total_punished", 0, 100, true, 5),
      list_menu_item("Side", _current_punish, "side", side),
      list_menu_item("Swap side", _current_punish, "swap_side", swap_side),
      integer_menu_item("Offset frames before replay", _collection, "offset", 0, 180, true, 0),
      checkbox_menu_item("Continue beyond total punishes", _collection, "continue", false),
      button_menu_item("Start", function()
        _current_module.start()
      end),
    }
end



function _punish.set_menu()
  local _cmd = "dir /b "..string.gsub(_punish.json_folder_path, "/", "\\")
  local _f = io.popen(_cmd)
  if _f == nil then
    print(string.format("Error: Failed to execute command \"%s\"", _cmd))
    return
  end
  local _str = _f:read("*all")
  local json_path_list = {}
  for _line in string.gmatch(_str, '([^\r\n]+)') do -- Split all lines that have ".json" in them
    if string.find(_line, ".json") ~= nil then
      local _file = string.format("%s%s", _punish.json_folder_path, _line)
      table.insert(json_path_list, _file)
    end
  end

  build_collection(json_path_list)
  local _character_index = _collection.character
  local _character_object = _collection[_collection.character_list[_character_index]]
  local _opponent_index = _character_object.opponent
  _config = _current_module.config
  return {
    name = "Punish",
    entries = build_entries(_character_index, _opponent_index, _character_object),
  }
end



function next_punish()
  local _p1 = _collection.character_list[_collection.character]
  local _opponent_name = _collection[_p1].opponent_list[_collection[_p1].opponent]
  local _punishes_array = get_punishes_array(_collection.character, _collection[_p1].opponent)
  local _punish_index = _collection[_p1][_opponent_name].punish
  local found_next = false
  local character_changed = false

  while not found_next and not (_collection.character > #_collection.character_list) do
    while not found_next and not (_collection[_p1].opponent > #_collection[_p1].opponent_list) do
      repeat
        _punish_index = _punish_index + 1
        _collection[_p1][_opponent_name].punish = _punish_index
      until _punish_index > #_punishes_array or _collection[_p1][_opponent_name][_punishes_array[_punish_index]].enabled


      if _punish_index > #_punishes_array then
        _punish_index = 0
        _collection[_p1][_opponent_name].punish = 1
        _collection[_p1].opponent = _collection[_p1].opponent + 1
        if _collection[_p1].opponent <= #_collection[_p1].opponent_list then
          _opponent_name = _collection[_p1].opponent_list[_collection[_p1].opponent]
          _punishes_array = get_punishes_array(_collection.character, _collection[_p1].opponent)
          character_changed = true
        end
      else
        found_next = true
      end
    end

    if not found_next then
      _punish_index = 0
      _collection[_p1].opponent = 1
      _collection.character = _collection.character + 1
      if _collection.character <= #_collection.character_list then
        _p1 = _collection.character_list[_collection.character]
        _collection[_p1].opponent = 1
        _opponent_name = _collection[_p1].opponent_list[_collection[_p1].opponent]
        _punishes_array = get_punishes_array(_collection.character, _collection[_p1].opponent)
        character_changed = true
      end
    end
  end

  return found_next, character_changed
end

local function get_chars_data()
  local _p1 = _collection.character_list[_collection.character]

  local _punish = get_selected_punish()

  local _p1_sa = _punish.p1_sa or 1

  local _p2_sa = _punish.p2_sa or 1

  local _picked_opponent = _collection[_p1].opponent_list[_collection[_p1].opponent]  

  local _p2 = string.lower(_picked_opponent)

  return _p1, _p2, _p1_sa, _p2_sa
end

local function draw_text(_text, _y, _color, _outline, _center)
  local _text_width = get_text_width(_text)
  local _x = (screen_width / 2) - _text_width - 20
  if _center == true then
    _x = (screen_width / 2) - _text_width / 2
  end
  gui.text(_x, _y, _text, _color, _outline)
end

local function set_tmp_config()
  local _p1 = _collection.character_list[_collection.character]
  local _p2 = _collection[_p1].opponent_list[_collection[_p1].opponent]
  local _punish_index = _collection[_p1][_p2].punish
  local _current_punish = get_selected_punish()
  _tmp_config = {
    character = _collection.character,
    opponent = _collection[_p1].opponent,
    punish = _punish_index,
    total_punished = _current_punish.total_punished,
    side = _current_punish.side,
    swap_side = _current_punish.swap_side,
    continue = _collection.continue,
    offset = _collection.offset,
  }
end

-- If you want to add graphics over screen
local function _draw_overlay()
  -- To draw a PNG on screen
  -- gui.gdoverlay(_x, _y, _image_path)

  local _p1 = _collection.character_list[_collection.character]
  local _p2 = _collection[_p1].opponent_list[_collection[_p1].opponent]
  local _punish_index = _collection[_p1][_p2].punish
  local _punishes_array = get_punishes_array(_collection.character, _collection[_p1].opponent)

  -- To draw text on screen
  draw_text(string.format("punish: %s", _punishes_array[_punish_index]), 39, "teal", "black", true)
  draw_text(string.format("Hit: %s/%s", _punished, get_selected_punish().total_punished), 49, "teal", "black")
  draw_text(string.format("Miss: %s", _miss_punished), 59, "teal", "black")
end

function _punish.update_menu(_menu, _menu_type)
  local _character_index = _collection.character
  local _character_object = _collection[_collection.character_list[_character_index]]
  local _opponent_index = _character_object.opponent

  if(_menu_type == "Contextual") then
    _menu.content = build_entries(_character_index, _opponent_index, _character_object, "Contextual")
  else
    _menu.content[_menu.main_menu_selected_index].entries = build_entries(_character_index, _opponent_index, _character_object)

    _menu.sub_menu_selected_index = math.min(_menu.sub_menu_selected_index, #_menu.content[_menu.main_menu_selected_index].entries)
    while not(_menu.is_main_menu_selected or
        _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled == nil or
        not _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled()) do
      _menu.sub_menu_selected_index = _menu.sub_menu_selected_index - 1
    end
  end

  write_object_to_json_file(_collection, "src/training_addons/Punish/punishes_collection.json")
end

function _punish.start()
  local _p1_char, _p2_char, _p1_sa, _p2_sa = get_chars_data()
  local p1 = {
    character = character_select_data[_p1_char],
    color = _config.color_button or 1,
    sa = _p1_sa,
  }
  local p2 = {
    character = character_select_data[_p2_char],
    color = 1,
    sa = _p2_sa,
  }
  character_select(p1, p2)

  _punish.has_ended = false
  set_tmp_config()
  _punish.training_menu.on_toggle_entry = function (_menu)
    _punish.update_menu(_menu, "Contextual")
  end
  _punish.update_menu(_punish.training_menu, "Contextual")
end

function _punish.apply_changes()
  local _p1 = _collection.character_list[_collection.character]
  local _p2 = _collection[_p1].opponent_list[_collection[_p1].opponent]
  local _current_punish = get_selected_punish()
  local restart

  if _tmp_config.character ~= _collection.character or _tmp_config.opponent ~= _collection[_p1].opponent then
    _collection.character = _tmp_config.character
    _p1 = _collection.character_list[_collection.character]
    _collection[_p1].opponent = _tmp_config.opponent
    _current_punish = get_selected_punish()

    restart = _punish.start
  else
    restart = _punish.init
  end

  _collection[_p1][_p2].punish = _tmp_config.punish
  _current_punish.total_punished = _tmp_config.total_punished
  _current_punish.side = _tmp_config.side
  _current_punish.swap_side = _tmp_config.swap_side
  _collection.continue = _tmp_config.continue
  _collection.offset = _tmp_config.offset
  restart()
end



local function _on_hit(_animation)
  if _state == "Idle" then
    if _animation == _current_character_adresses[_current_punish_combo[1]] then
      _state = "Combo"
      _current_combo_step = 2
    else
      emu.speedmode("turbo")
    end
  elseif _state == "Combo" then
    if _animation == _current_character_adresses[_current_punish_combo[_current_combo_step]] then
      _current_combo_step = _current_combo_step + 1
      if _current_combo_step > #_current_punish_combo then
        emu.speedmode("turbo")
      end
    else
      _state = "Idle"
      _current_combo_step = 1
      emu.speedmode("turbo")
    end
  end
end

function _punish.init()
  training_settings.meter_mode = 3
  training_settings.life_mode = 3
  training_settings.stun_mode = 2
  training_settings.blocking_style = 1
  training_settings.blocking_mode = 2
  _current_combo_step = 1
  _punished = 0
  _miss_punished = 0
  _state = "Idle"
  _current_character_adresses = _addresses[_collection.character_list[_collection.character]]

  local selected_punish = get_selected_punish()

  _current_punish_combo = selected_punish.punish
  _current_side = selected_punish.side
  restart_sequence = true

  local _p1_pos_x = math.random(110, 920 - selected_punish.players_distance)
  local _p1_pos_x_sided
  local _p2_pos_x_sided

  if _current_side == 1 then
    _p1_pos_x_sided = _p1_pos_x
    _p2_pos_x_sided = _p1_pos_x + selected_punish.players_distance
  else
    _p1_pos_x_sided = _p1_pos_x + selected_punish.players_distance
    _p2_pos_x_sided = _p1_pos_x
  end

  memory.writeword(0x02026CB0, _p1_pos_x)
  memory.writeword(player_objects[2].base + 0x64, _p2_pos_x_sided)
  memory.writeword(player_objects[1].base + 0x64, _p1_pos_x_sided)
end

function _punish.update()
  if not is_in_match then return end

  if has_match_just_started then
    _punish.init()
  end

  local selected_punish = get_selected_punish()
  
  if restart_sequence then
    _current_combo_step = 1
    _state = "Idle"

    if swap_side[selected_punish.swap_side] == "Random" then
      _current_side = math.random(1, 2)
    elseif swap_side[selected_punish.swap_side] == "Halfway" then
      if (((_punished + 1) % selected_punish.total_punished) * 2) >= selected_punish.total_punished and not swapped then
        swapped = true
        _current_side = (_current_side - 3) * -1
      elseif (_punished % selected_punish.total_punished) == 0 and swapped then
        swapped = false
        _current_side = (_current_side - 3) * -1
      end
    end

    local _p1_pos_x = math.random(110, 920 - selected_punish.players_distance)
    local _p1_pos_x_sided
    local _p2_pos_x_sided

    if _current_side == 1 then
      _p1_pos_x_sided = _p1_pos_x
      _p2_pos_x_sided = _p1_pos_x + selected_punish.players_distance
    else
      _p1_pos_x_sided = _p1_pos_x + selected_punish.players_distance
      _p2_pos_x_sided = _p1_pos_x
    end

    memory.writeword(0x02026CB0, _p1_pos_x + selected_punish.players_distance / 2)
    memory.writeword(player_objects[2].base + 0x64, _p2_pos_x_sided)
    memory.writeword(player_objects[1].base + 0x64, _p1_pos_x_sided)
    clear_input_sequence(player_objects[1])
    clear_input_sequence(player_objects[2])
    queue_input_sequence(player_objects[1], selected_punish.p1_rec, _collection.offset)
    queue_input_sequence(player_objects[2], selected_punish.p2_rec, _collection.offset)
    emu.speedmode("normal")
  end

  restart_sequence = false

  if player_objects[2].has_just_started_wake_up or player_objects[2].has_just_started_fast_wake_up then
    emu.speedmode("turbo")
  end

  if player_objects[2].has_just_been_hit then
    _on_hit(player_objects[1].animation)
  end

  if (player_objects[2].is_idle and not is_playing_input_sequence(player_objects[2]) and player_objects[2].pending_input_sequence == nil) then
    if player_objects[2].idle_time == 1 then
      emu.speedmode("turbo")
    end
    clear_input_sequence(player_objects[1])
    queue_input_sequence(player_objects[1], {{"down", "back"},{"down", "back"}})
    if player_objects[1].is_idle and is_state_on_ground(player_objects[1].standing_state, player_objects[1]) then
      restart_sequence = true
      if _current_combo_step > #_current_punish_combo then
        _punished = _punished + 1
      else
        _miss_punished = _miss_punished + 1
      end
    end
  end

  _draw_overlay()

  memory.writebyte(0x02011377, 100) -- Infinite time
  
  if selected_punish.total_punished > 0 and _punished >= selected_punish.total_punished and not _collection.continue then
    local found_next_punish, character_changed = next_punish()
    if not found_next_punish then
     _punish.has_ended = true
     _collection.character = 1
    else
     if character_changed then
       _punish.start()
     else
       _punish.init()
     end
    end
  end

end

return _punish

-- TODO:

-- Refactor