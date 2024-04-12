local _stun_juggles = {
  is_enabled = false,
  has_ended = false
}

local opponent = {}

local side = {
  "Left",
  "Right",
}

local swap_side = {
  "No",
  "Halfway",
  "Random",
}

local side_coordinates = {
  { 260, 240, 110 },
  { 770, 780, 920 },
}

local addresses = {
  EC_anim_id = 0xE01C
}

local _config

local current_attempt = 1
local current_side = 0
local swapped = false

function _stun_juggles.set_menu()
  _config = _current_module.config
  opponent = _current_module.constants.whole_cast
  return {
    name = "Stun juggles",
    entries = {
      integer_menu_item("Attempts", _config.stun_juggles, "attempts", 1, 100, true, 10),
      list_menu_item("Side", _config.stun_juggles, "side", side),
      list_menu_item("Swap side", _config.stun_juggles, "swap_side", swap_side),
      checkbox_menu_item("Enabled in routine", _config.stun_juggles, "enabled", true),
      list_menu_item("Opponent", _config.stun_juggles, "opponent", opponent),
      button_menu_item("Start", function() end),
    }
  }
end

function _stun_juggles.start()
  _config = _current_module.config
  local p1 = {
    character = character_select_data.necro,
    color = _config.color_button,
    sa = 3
  }
  local p2 = {
    character = character_select_data[string.lower(opponent[_config.stun_juggles.opponent])],
    color = 1,
    sa = 1
  }
  character_select(p1, p2)
  current_attempt = 1
  swapped = false
  _stun_juggles.has_ended = false
end

local function _draw_overlay(tenths, units)
  draw_text(string.format("Attempts: %s/%s", current_attempt, _config.stun_juggles.attempts), 49, "teal", "black")
end

function _stun_juggles.update()
  if not is_in_match then return end

  if has_match_just_started then

    -- Set mutable side for the session
    current_side = _config.stun_juggles.side

    -- Teleport both players to one side of the screen
    memory.writeword(0x02026CB0, side_coordinates[current_side][1])
    memory.writeword(player_objects[2].base + 0x64, side_coordinates[current_side][3])
    memory.writeword(player_objects[1].base + 0x64, side_coordinates[current_side][2])

    -- Take control over the timer
    training_settings.infinite_time = false
    -- Set it to 99
    memory.writebyte(0x02011377, 100)
  end

  if player_objects[2].has_just_been_hit then
    if player_objects[1].animation == bit.tohex(addresses.EC_anim_id, 4) then

    end
  end

  if player_objects[2].has_just_started_wake_up or player_objects[2].has_just_started_fast_wake_up then
    emu.speedmode("turbo")
  end

  if player_objects[2].has_just_woke_up then
    if swap_side[_config.stun_juggles.swap_side] == "Random" then
      current_side = math.random(1, 2)
    elseif swap_side[_config.stun_juggles.swap_side] == "Halfway" and not swapped and (current_attempt * 2) >= _config.stun_juggles.attempts then
      swapped = true
      current_side = (current_side - 3) * -1
    end

    current_attempt = current_attempt + 1

    if current_attempt > _config.stun_juggles.attempts then
      _stun_juggles.has_ended = true
    end
    memory.writeword(0x02026CB0, side_coordinates[current_side][1])
    memory.writeword(player_objects[2].base + 0x64, side_coordinates[current_side][3])
    memory.writeword(player_objects[1].base + 0x64, side_coordinates[current_side][2])
    emu.speedmode("normal")
  end
end

return _stun_juggles