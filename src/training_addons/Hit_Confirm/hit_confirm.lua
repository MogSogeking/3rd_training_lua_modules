local _hit_confirm = {
  is_enabled = false,
  has_ended = false,
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
local _current_hit_confirm_combo = {}
local _current_combo_step = 1
local _current_side = 0
local _is_blocking = false
local _hit_confirmed = 0
local _miss_confirmed = 0
local _guard_confirmed = 0
local _current_guard = false
local _state = "Idle"
local swapped = false

local _character_select = list_menu_item("Character", _collection, "character", _collection.character_list)
_character_select.is_disabled = function ()
  return #_collection.character_list < 2
end

local _tmp_config = {
  character = 1,
  confirm = 1,
  guard_weight = 1,
  dynamic = false,
  opponent_index = 1,
  total_confirmed = 5,
  side = 1,
  swap_side = 1,
  continue = false,
}

function TableConcat(t1,t2)
    for _key, _value in pairs(t2) do
        t1[_key] = _value
    end
    return t1
end

function build_collection(json_path_list)
  for _key, _value in pairs(json_path_list) do
    local _json = read_object_from_json_file(_value)
    if _json ~= nil and _json.character ~= nil and _json.list ~= nil then
      if _collection[_json.character] == nil then
        _collection[_json.character] = _json.list
        _collection[_json.character].confirm = 1
        table.insert(_collection["character_list"], _json.character)
      else
        _collection[_json.character] = TableConcat(_collection[_json.character], _json.list)
      end
    end
  end

  for _key, _value in pairs(_collection) do
    if _key ~= "character" and _key ~= "character_list" and _key ~= "continue" then
      for _key_2, _value_2 in pairs(_value) do
        if _key_2 ~= "confirm" then
          _value_2.guard_weight = 5
          _value_2.dynamic = false
          _value_2.opponent_index = 1
          _value_2.side = 1
          _value_2.swap_side = 1
          _value_2.enabled = true
          _value_2.total_confirmed = 5
        end
      end
    end
  end
end

function build_entries(_character_index, _character_object, _menu_type)
  local _confirms_array = get_confirms_array(_character_index)
  local _current_confirm = get_selected_confirm()

  if _menu_type == "Contextual" then
    local _character_select = list_menu_item("Character", _tmp_config, "character", _collection.character_list)
    _character_select.is_disabled = function ()
      return #_collection.character_list < 2
    end

    local _p1 = _collection.character_list[_tmp_config.character]
    _confirms_array = get_confirms_array(_tmp_config.character)

    if #_confirms_array < _tmp_config.confirm then
      _tmp_config.confirm = 1
    end

    return {
      _character_select,
      list_menu_item("Confirm", _tmp_config, "confirm", _confirms_array),
      integer_menu_item("Total confirms", _tmp_config, "total_confirmed", 0, 100, true, 5),
      integer_menu_item("Guard weight", _tmp_config, "guard_weight", 0, 9, true, 5),
      checkbox_menu_item("Dynamic", _tmp_config, "dynamic", false),
      list_menu_item("Opponent", _tmp_config, "opponent_index", get_opponent_list(_current_confirm.opponent)),
      list_menu_item("Side", _tmp_config, "side", side),
      list_menu_item("Swap side", _tmp_config, "swap_side", swap_side),
      checkbox_menu_item("Continue beyond total confirms", _tmp_config, "continue", false),
      button_menu_item("Restart", function()
        _hit_confirm.apply_changes()
      end),
      button_menu_item("Quit", function()
        _current_module.quit_training()
      end),
    }
  end

  return {
      _character_select,
      list_menu_item("Confirm", _character_object, "confirm", _confirms_array),
      checkbox_menu_item("Enabled in routine", _current_confirm, "enabled", true),
      integer_menu_item("Total confirms", _current_confirm, "total_confirmed", 0, 100, true, 5),
      integer_menu_item("Guard weight", _current_confirm, "guard_weight", 0, 9, true, 5),
      checkbox_menu_item("Dynamic", _current_confirm, "dynamic", false),
      list_menu_item("Opponent", _current_confirm, "opponent_index", get_opponent_list(_current_confirm.opponent)),
      list_menu_item("Side", _current_confirm, "side", side),
      list_menu_item("Swap side", _current_confirm, "swap_side", swap_side),
      checkbox_menu_item("Continue beyond total confirms", _collection, "continue", false),
      button_menu_item("Start", function()
        _current_module.start()
      end),
    }
end

function get_confirms_array(index)
  local _result = {}
  for _key, _value in pairs(_collection[_collection.character_list[index]]) do
    if _key ~= "confirm" then
      table.insert(_result, _key)
    end
  end
  return _result
end

function get_opponent_list(_list)
  if _list == nil or #_list == 0 or string.lower(_list[1]) == "any" then return _characters end
  local _result = TableConcat({}, _list)
  table.insert(_result, 1, "Favorite")
  return _result
end

function _hit_confirm.set_menu(json_path_list)
  build_collection(json_path_list)
  local _character_index = _collection.character
  local _character_object = _collection[_collection.character_list[_character_index]]
  write_object_to_json_file(_collection, "test_collection.json")
  _config = _current_module.config
  return {
    name = "Hit confirm",
    entries = build_entries(_character_index, _character_object),
  }
end

function get_selected_confirm(_character)
  _character = _character or _collection.character
  local _p1 = _collection.character_list[_collection.character]
  local _confirms_array = get_confirms_array(_collection.character)
  local _confirm_index = _collection[_p1].confirm
  return _collection[_p1][_confirms_array[_confirm_index]]
end

function next_confirm()
  local _p1 = _collection.character_list[_collection.character]
  local _confirms_array = get_confirms_array(_collection.character)
  local _confirm_index = _collection[_p1].confirm
  local found_next = false
  local character_changed = false

  while not found_next and not (_collection.character > #_collection.character_list) do
    repeat
      _confirm_index = _confirm_index + 1
      _collection[_p1].confirm = _confirm_index
    until _confirm_index > #_confirms_array or _collection[_p1][_confirms_array[_confirm_index]].enabled


    if _confirm_index > #_confirms_array then
      _confirm_index = 0
      _collection[_p1].confirm = 1
      _collection.character = _collection.character + 1
      if _collection.character <= #_collection.character_list then
        _p1 = _collection.character_list[_collection.character]
        _confirms_array = get_confirms_array(_collection.character)
        character_changed = true
      end
    else
      found_next = true
    end
  end

  return found_next, character_changed
end

function get_chars_data()
  local _p1 = _collection.character_list[_collection.character]

  local _confirm = get_selected_confirm()

  local _sa = _confirm.sa or 1

  local _opponent_list = get_opponent_list(_confirm.opponent)
  local _opponent_index = _confirm.opponent_index
  
  local _picked_opponent = _opponent_list[_opponent_index]

  if _picked_opponent == "Favorite" then
    _picked_opponent = _opponent_list[_config.favorite_opponent + 1]
  end

  local _p2 = string.lower(_picked_opponent)

  return _p1, _p2, _sa
end

function _hit_confirm.update_menu(_menu, _menu_type)
  local _character_index = _collection.character
  local _character_object = _collection[_collection.character_list[_character_index]]

  if(_menu_type == "Contextual") then
    _menu.content = build_entries(_character_index, _character_object, "Contextual")
  else
    _menu.content[_menu.main_menu_selected_index].entries = build_entries(_character_index, _character_object)

    _menu.sub_menu_selected_index = math.min(_menu.sub_menu_selected_index, #_menu.content[_menu.main_menu_selected_index].entries)
    while not(_menu.is_main_menu_selected or
        _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled == nil or
        not _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled()) do
      _menu.sub_menu_selected_index = _menu.sub_menu_selected_index - 1
    end
  end
end

function _hit_confirm.start()
  local _p1_char, _p2_char, _p1_sa = get_chars_data()
  local p1 = {
    character = character_select_data[_p1_char],
    color = _config.color_button or 1,
    sa = _p1_sa,
  }
  local p2 = {
    character = character_select_data[_p2_char],
    color = 1,
    sa = 1,
  }
  character_select(p1, p2)

  _hit_confirm.has_ended = false
  set_tmp_config()
  _hit_confirm.training_menu.on_toggle_entry = function (_menu)
    _hit_confirm.update_menu(_menu, "Contextual")
  end
  _hit_confirm.update_menu(_hit_confirm.training_menu, "Contextual")
end

function _hit_confirm.apply_changes()
  local _p1 = _collection.character_list[_collection.character]
  local _confirm_index = _collection[_p1].confirm
  local _current_confirm = get_selected_confirm()

  print("=================================================")
  print(_tmp_config.character, _collection.character)
  print(_tmp_config.confirm, _confirm_index, _collection[_p1].confirm)
  print(_tmp_config.guard_weight, _current_confirm.guard_weight)
  print(_tmp_config.dynamic, _current_confirm.dynamic)
  print(_tmp_config.opponent_index, _current_confirm.opponent_index)

  local restart

  if _tmp_config.character ~= _collection.character or _tmp_config.opponent_index ~= _current_confirm.opponent_index then
    _collection.character = _tmp_config.character
    _p1 = _collection.character_list[_collection.character]
    _current_confirm = get_selected_confirm()
    _current_confirm.opponent_index = _tmp_config.opponent_index

    restart = _hit_confirm.start
  else
    restart = _hit_confirm.init
  end

  _collection[_p1].confirm = _tmp_config.confirm
  _current_confirm.guard_weight = _tmp_config.guard_weight
  _current_confirm.dynamic = _tmp_config.dynamic
  _current_confirm.total_confirmed = _tmp_config.total_confirmed
  _current_confirm.side = _tmp_config.side
  _current_confirm.swap_side = _tmp_config.swap_side
  _collection.continue = _tmp_config.continue
  restart()
end

function draw_text(_text, _y, _color, _outline)
  local _text_width = get_text_width(_text)
  local _x = (screen_width / 2) - _text_width - 20
  gui.text(_x, _y, _text, _color, _outline)
end

function set_tmp_config()
  local _p1 = _collection.character_list[_collection.character]
  local _confirm_index = _collection[_p1].confirm
  local _current_confirm = get_selected_confirm()
  _tmp_config = {
    character = _collection.character,
    confirm = _confirm_index,
    guard_weight = _current_confirm.guard_weight,
    dynamic = _current_confirm.dynamic,
    opponent_index = _current_confirm.opponent_index,
    total_confirmed = _current_confirm.total_confirmed,
    side = _current_confirm.side,
    swap_side = _current_confirm.swap_side,
    continue = _collection.continue,
  }
end

-- If you want to add graphics over screen
local function _draw_overlay()
  -- To draw a PNG on screen
  -- gui.gdoverlay(_x, _y, _image_path)

  local _p1 = _collection.character_list[_collection.character]
  local _confirms_array = get_confirms_array(_collection.character)
  local _confirm_index = _collection[_p1].confirm

  -- To draw text on screen
  draw_text(string.format("Confirm: %s", _confirms_array[_confirm_index]), 39, "teal", "black")
  draw_text(string.format("Hit: %s/%s", _hit_confirmed, get_selected_confirm().total_confirmed), 49, "teal", "black")
  draw_text(string.format("Miss: %s", _miss_confirmed), 59, "teal", "black")
  draw_text(string.format("Guard: %s", _guard_confirmed), 69, "teal", "black")
end

local function _pick_guard()
  local weight = get_selected_confirm().guard_weight
  local rn = math.random(0, 9)
  print(weight, rn)
  return rn < weight
end

local function _on_hit(_animation)
  if _state == "Idle" then
    if _animation == _current_character_adresses[_current_hit_confirm_combo[1]] then
      _state = "Combo"
      _current_combo_step = 2
    else
      _current_guard = _pick_guard()
      emu.speedmode("turbo")
    end
  elseif _state == "Combo" then
    if _animation == _current_character_adresses[_current_hit_confirm_combo[_current_combo_step]] then
      _current_combo_step = _current_combo_step + 1
      if _current_combo_step > #_current_hit_confirm_combo then
        _hit_confirmed = _hit_confirmed + 1
        _current_combo_step = 1
        emu.speedmode("turbo")
      end
    else
      _state = "Idle"
      _current_guard = _pick_guard()
      _current_combo_step = 1
      _miss_confirmed = _miss_confirmed + 1
      emu.speedmode("turbo")
    end
  elseif _state == "Block" then
    _current_guard = _pick_guard()
    if _animation == _current_character_adresses[_current_hit_confirm_combo[1]] then
      _state = "Combo"
      _current_combo_step = 2
    elseif _animation == _current_character_adresses[_current_hit_confirm_combo[get_selected_confirm().hit_to_confirm]] then
      _state = "Idle"
      _current_combo_step = 1
      _guard_confirmed = _guard_confirmed + 1
      emu.speedmode("turbo")
    else
      local found_relevant_hit = false
      for i = 1, get_selected_confirm().hit_to_confirm do
        if _animation == _current_character_adresses[_current_hit_confirm_combo[i]] then
          found_relevant_hit = true
          break
        end
      end
      if not found_relevant_hit then
        _state = "Idle"
        _current_combo_step = 1
        emu.speedmode("turbo")
      end
    end
  end
end

local function _on_block(_animation)
  if _state == "Idle" and _animation == _current_character_adresses[_current_hit_confirm_combo[1]] then
    _state = "Block"
  elseif _state == "Block" and _animation == _current_character_adresses[_current_hit_confirm_combo[get_selected_confirm().hit_to_confirm]] then
    _state = "Idle"
    _current_combo_step = 1
    _guard_confirmed = _guard_confirmed + 1
    emu.speedmode("turbo")
  end 
  _current_guard = _pick_guard()
end

local function _on_no_combo()
  if _state == "Combo" then
    _state = "Idle"
    _current_guard = _pick_guard()

    if _current_combo_step > 1 then
      _current_combo_step = 1
      _miss_confirmed = _miss_confirmed + 1
    end
  end
end

function _hit_confirm.init()
  training_settings.meter_mode = 3
  training_settings.life_mode = 2
  training_settings.stun_mode = 2
  _current_combo_step = 1
  _is_blocking = false
  _hit_confirmed = 0
  _miss_confirmed = 0
  _guard_confirmed = 0
  _state = "Idle"
  _current_guard = _pick_guard()
  _current_character_adresses = _addresses[_collection.character_list[_collection.character]]

  local selected_confirm = get_selected_confirm()

  _current_hit_confirm_combo = selected_confirm.hits
  _current_side = selected_confirm.side

  local _p1_pos_x = math.random(110, 920 - selected_confirm.players_distance)
  local _p1_pos_x_sided
  local _p2_pos_x_sided

  if _current_side == 1 then
    _p1_pos_x_sided = _p1_pos_x
    _p2_pos_x_sided = _p1_pos_x + selected_confirm.players_distance
  else
    _p1_pos_x_sided = _p1_pos_x + selected_confirm.players_distance
    _p2_pos_x_sided = _p1_pos_x
  end

  memory.writeword(0x02026CB0, _p1_pos_x)
  memory.writeword(player_objects[2].base + 0x64, _p2_pos_x_sided)
  memory.writeword(player_objects[1].base + 0x64, _p1_pos_x_sided)
end

function get_stance(_name)
  if _name == "crouching" then return 2
  elseif _name == "jumping" then return 3
  elseif _name == "highjumping" then return 4
  end
  return 1
end

function _hit_confirm.update()
  if not is_in_match then return end

  if has_match_just_started then
    _hit_confirm.init()
  end

  local selected_confirm = get_selected_confirm()

  if player_objects[2].is_idle and player_objects[2].idle_time == 1 then

    local _stance = get_stance(selected_confirm.opponent_stance[math.random(1, #selected_confirm.opponent_stance)])

    training_settings.pose = _stance

    if swap_side[selected_confirm.swap_side] == "Random" then
      _current_side = math.random(1, 2)
    elseif swap_side[selected_confirm.swap_side] == "Halfway" then
      if (((_hit_confirmed + 1) % selected_confirm.total_confirmed) * 2) >= selected_confirm.total_confirmed and not swapped then
        swapped = true
        _current_side = (_current_side - 3) * -1
      elseif (_hit_confirmed % selected_confirm.total_confirmed) == 0 and swapped then
        swapped = false
        _current_side = (_current_side - 3) * -1
      end
    end

    local _p1_pos_x = math.random(110, 920 - selected_confirm.players_distance)
    local _p1_pos_x_sided
    local _p2_pos_x_sided

    if _current_side == 1 then
      _p1_pos_x_sided = _p1_pos_x
      _p2_pos_x_sided = _p1_pos_x + selected_confirm.players_distance
    else
      _p1_pos_x_sided = _p1_pos_x + selected_confirm.players_distance
      _p2_pos_x_sided = _p1_pos_x
    end

    memory.writeword(0x02026CB0, _p1_pos_x)
    memory.writeword(player_objects[2].base + 0x64, _p2_pos_x_sided)
    memory.writeword(player_objects[1].base + 0x64, _p1_pos_x_sided)
    emu.speedmode("normal")
  end

  _draw_overlay()

  memory.writebyte(0x02011377, 100) -- Infinite time

  if _current_guard then
    training_settings.blocking_style = 1
    training_settings.blocking_mode = 2
  else
    training_settings.blocking_style = 1
    training_settings.blocking_mode = 1
  end

  if player_objects[1].combo == 0 then
    _on_no_combo()
  end

  if player_objects[2].has_just_been_hit then
    _on_hit(player_objects[1].animation)
  elseif player_objects[2].has_just_blocked then
    _on_block(player_objects[1].animation)
  end
  
  if selected_confirm.total_confirmed > 0 and _hit_confirmed >= selected_confirm.total_confirmed and not _collection.continue then
    local found_next_confirm, character_changed = next_confirm()
    if not found_next_confirm then
      _hit_confirm.has_ended = true
    else
      if character_changed then
        _hit_confirm.start()
      else
        _hit_confirm.init()
      end
    end
  end

end

return _hit_confirm

-- TODO:

-- Refactor
-- Dynamic mode