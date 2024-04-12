
character_select_coroutine = nil
secondary_character_select_coroutine = nil


-- 0 is out
-- 1 is waiting for input release for p1
-- 2 is selecting p1
-- 3 is waiting for input release for p2
-- 4 is selecting p2
character_select_sequence_state = 0

-- _input as a parameter to be able to write it back from yield
function co_wait_x_frames(_frame_count, _input)
  local _start_frame = frame_number
  while frame_number < _start_frame + _frame_count do
    _input = coroutine.yield()
  end
  return _input
end

function start_character_select_sequence()
  savestate.load(savestate.create("data/"..rom_name.."/savestates/character_select.fs"))
  character_select_sequence_state = 1
end

function create_character_select_coroutine(_coroutine)
  if character_select_coroutine == nil then
    character_select_coroutine = coroutine.create(_coroutine)
  elseif secondary_character_select_coroutine == nil then
    secondary_character_select_coroutine = coroutine.create(_coroutine)
  end
end

function select_gill()
  create_character_select_coroutine(co_select_gill)
end

function co_select_gill(_input)
  local _player_id = 0

  local _p1_character_select_state = memory.readbyte(adresses.players[1].character_select_state)
  local _p2_character_select_state = memory.readbyte(adresses.players[2].character_select_state)

  if _p1_character_select_state > 2 and _p2_character_select_state > 2 then
    return
  end

  if _p1_character_select_state <= 2 then
    _player_id = 1
  else
    _player_id = 2
  end

  memory.writebyte(adresses.players[_player_id].character_select_col, 3)
  memory.writebyte(adresses.players[_player_id].character_select_row, 1)

  make_input_empty(_input)
  _input[player_objects[_player_id].prefix.." Weak Punch"] = true
end

function select_shingouki()
  create_character_select_coroutine(co_select_shingouki)
end

function co_select_shingouki(_input)
  local _player_id = 0

  local _p1_character_select_state = memory.readbyte(adresses.players[1].character_select_state)
  local _p2_character_select_state = memory.readbyte(adresses.players[2].character_select_state)

  if _p1_character_select_state > 2 and _p2_character_select_state > 2 then
    return
  end

  if _p1_character_select_state <= 2 then
    _player_id = 1
  else
    _player_id = 2
  end

  memory.writebyte(adresses.players[_player_id].character_select_col, 0)
  memory.writebyte(adresses.players[_player_id].character_select_row, 6)

  make_input_empty(_input)
  _input[player_objects[_player_id].prefix.." Weak Punch"] = true

  co_wait_x_frames(20)

  memory.writebyte(adresses.players[_player_id].character_select_id, 0x0F)
end

function select_character(_player_id, _character, _color, _sa)
  create_character_select_coroutine(function(_input) co_select_character(_input, _player_id, _character, _color, _sa) end)
end

function co_select_character(_input, _player_id, character, _color, _sa)
  local character_select_state = memory.readbyte(adresses.players[_player_id].character_select_state)
  local make_input_empty_player

  if _player_id == 1 then
    make_input_empty_player = make_input_empty_p1
  else
    make_input_empty_player = make_input_empty_p2
  end

  if character_select_state > 2 then
    return
  end

  memory.writebyte(adresses.players[_player_id].character_select_col, character.col)
  memory.writebyte(adresses.players[_player_id].character_select_row, character.row)

  make_input_empty_player(_input)
  _input[player_objects[_player_id].prefix.." Weak Punch"] = true

  _input = co_wait_x_frames(20)

  memory.writebyte(adresses.players[_player_id].character_select_id, character.id)
  memory.writebyte(adresses.players[_player_id].character_select_color, _color)

  _input = co_wait_x_frames(30)

  make_input_empty_player(_input)
  _input[player_objects[_player_id].prefix.." Weak Punch"] = true

  memory.writebyte(adresses.players[_player_id].character_select_sa, _sa)
end

function update_character_select(_input, _do_fast_forward)

  -- Always false, what was its intended purpose ?
  -- if not character_select_sequence_state == 0 then
  --   return
  -- end

  -- Infinite select time
  --memory.writebyte(adresses.global.character_select_timer, 0x30)

  function check_coroutine(_coroutine, _input)
    if _coroutine == nil then return end

    local _status = coroutine.status(_coroutine)
    if _status == "suspended" then
      local _r, _error = coroutine.resume(_coroutine, _input)
      if not _r then
        print(_error)
      end
    elseif _status == "dead" then
      return nil
    end
    return _coroutine
  end

  if character_select_coroutine ~= nil or secondary_character_select_coroutine ~= nil then
    make_input_empty(_input)

    character_select_coroutine = check_coroutine(character_select_coroutine, _input)
    secondary_character_select_coroutine = check_coroutine(secondary_character_select_coroutine, _input)
    return
  end

  local _p1_character_select_state = memory.readbyte(adresses.players[1].character_select_state)
  local _p2_character_select_state = memory.readbyte(adresses.players[2].character_select_state)

  --print(string.format("%d, %d, %d", character_select_sequence_state, _p1_character_select_state, _p2_character_select_state))

  if _p1_character_select_state > 4 and not is_in_match then
    if character_select_sequence_state == 2 then
      character_select_sequence_state = 3
    end
    swap_inputs(_input)
  end

  -- wait for all inputs to be released
  if character_select_sequence_state == 1 or character_select_sequence_state == 3 then
    for _key, _state in pairs(_input) do
      if _state == true then
        make_input_empty(_input)
        return
      end
    end
    character_select_sequence_state = character_select_sequence_state + 1
  end

  if has_match_just_started then
    emu.speedmode("normal")
    character_select_sequence_state = 0
  elseif not is_in_match then
    if _do_fast_forward and _p1_character_select_state > 4 and _p2_character_select_state > 4 then
      emu.speedmode("turbo")
    elseif character_select_sequence_state == 0 and (_p1_character_select_state < 5 or _p2_character_select_state < 5) then
      emu.speedmode("normal")
      character_select_sequence_state = 1
    end
  else
    character_select_sequence_state = 0
  end

end

function draw_character_select()
  local _p1_character_select_state = memory.readbyte(adresses.players[1].character_select_state)
  local _p2_character_select_state = memory.readbyte(adresses.players[2].character_select_state)

  if _p1_character_select_state <= 2 or _p2_character_select_state <= 2 then
    gui.text(10, 10, "Alt+1 -> Return To Character Select Screen", text_default_color, text_default_border_color)
    if rom_name == "sfiii3nr1" then
      gui.text(10, 20, "Alt+2 -> Gill", text_default_color, text_default_border_color)
      gui.text(10, 30, "Alt+3 -> Shin Gouki", text_default_color, text_default_border_color)
    end
  end
end
