local _elbow_cannon = {
  is_enabled = false,
  has_ended = false
}

local opponent = {
  "Alex",
  "Hugo",
  "Urien",
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

local side_coordinates = {
  { 260, 240, 110 },
  { 770, 780, 920 },
}

local addresses = {
  EC_anim_id = 0xE01C
}

local _config

local current_attempt = 1
local current_score = 0
local current_side = 0
local high_score = 0
local scores_history = {}
local swapped = false

function _elbow_cannon.set_menu()
  _config = _current_module.config
  print(opponent, swap_side, side)
  return {
    name = "Elbow cannon",
    entries = {
      integer_menu_item("Attempts", _config.elbow_cannon, "attempts", 1, 100, true, 10),
      list_menu_item("Side", _config.elbow_cannon, "side", side),
      list_menu_item("Swap side", _config.elbow_cannon, "swap_side", swap_side),
      checkbox_menu_item("Enabled in routine", _config.elbow_cannon, "enabled", true),
      list_menu_item("Opponent", _config.elbow_cannon, "opponent", opponent),
      button_menu_item("Start", function() end),
    }
  }
end

function draw_text(_text, _y, _color, _outline)
  local _text_width = get_text_width(_text)
  local _x = (screen_width / 2) - _text_width - 20
  gui.text(_x, _y, _text, _color, _outline)
end

local function _manage_timer(tenths, units)
  local _time_to_display = 11
  if tenths >= 3 and tenths <= 7 then
    if units >= 3 and units <= 7 then
      _time_to_display = 44
    else
      _time_to_display = 41
    end
  elseif units >= 3 and units <= 7 then
    _time_to_display = 14
  end

  memory.writebyte(0x02011377, _time_to_display + 1)
end

function get_average_score(_scores_history)
  if _scores_history == nil or #_scores_history == 0 then return 0 end

  local _acc = 0

  for _i, _j in pairs(_scores_history) do
    _acc = _acc + _j
  end
  return _acc / #_scores_history
end

function _elbow_cannon.start()
  _config = _current_module.config
  local p1 = {
    character = character_select_data.necro,
    color = _config.color_button,
    sa = 3
  }
  local p2 = {
    character = character_select_data[string.lower(opponent[_config.elbow_cannon.opponent])],
    color = 3,
    sa = 3
  }
  character_select(p1, p2)
  current_attempt = 1
  high_score = 0
  scores_history = {}
  swapped = false
  _elbow_cannon.has_ended = false
end

local function _draw_overlay(tenths, units)
  local nc = _current_module.constants

  gui.gdoverlay(168, 12, _current_module.images.timer_frame)
  gui.gdoverlay(176, 6, _current_module.images.timer_cyphers, tenths*nc.timer_cyphers_width, 2*nc.timer_cyphers_height, nc.timer_cyphers_width, nc.timer_cyphers_height)
  gui.gdoverlay(192, 6, _current_module.images.timer_cyphers, units*nc.timer_cyphers_width, 2*nc.timer_cyphers_height, nc.timer_cyphers_width, nc.timer_cyphers_height)

  draw_text(string.format("Attempts: %s/%s", current_attempt, _config.elbow_cannon.attempts), 49, "teal", "black")
  draw_text(string.format("High score: %s", high_score), 59, "teal", "black")
  draw_text(string.format("Average: %.1f", get_average_score(scores_history)), 69, "teal", "black")
end

function _elbow_cannon.update()
  if not is_in_match then return end

  if has_match_just_started then

    -- Set mutable side for the session
    current_side = _config.elbow_cannon.side

    -- Teleport both players to one side of the screen
    memory.writeword(0x02026CB0, side_coordinates[current_side][1])
    memory.writeword(player_objects[2].base + 0x64, side_coordinates[current_side][3])
    memory.writeword(player_objects[1].base + 0x64, side_coordinates[current_side][2])

    -- Take control over the timer
    training_settings.infinite_time = false
    -- Set it to 11 to hide the real timer as much as possible
    memory.writebyte(0x02011377, 12)
  end

  -- Set Necro's damage output to 0 to not have to deal with it
  memory.writebyte(0x020691A7, 0)

  memory.writebyte(0x020694C7, 0x00) -- Infinite juggle
  memory.writebyte(0x020694C9, 0xFE) -- Infinite juggle timer

  local tenths = math.floor(current_score/10)
  local units = current_score%10

  _draw_overlay(tenths, units)
  _manage_timer(tenths, units)

  if player_objects[2].has_just_been_hit then
    if player_objects[1].animation == bit.tohex(addresses.EC_anim_id, 4) then
      current_score = current_score + 1
    end
  end

  high_score = math.max(high_score, current_score)

  if player_objects[2].has_just_started_wake_up or player_objects[2].has_just_started_fast_wake_up then
    table.insert(scores_history, current_score)
    current_score = 0
    emu.speedmode("turbo")
  end

  if player_objects[2].has_just_woke_up then
    if swap_side[_config.elbow_cannon.swap_side] == "Random" then
      current_side = math.random(1, 2)
    elseif swap_side[_config.elbow_cannon.swap_side] == "Halfway" and not swapped and (current_attempt * 2) >= _config.elbow_cannon.attempts then
      swapped = true
      current_side = (current_side - 3) * -1
    end

    current_attempt = current_attempt + 1

    if current_attempt > _config.elbow_cannon.attempts then
      _elbow_cannon.has_ended = true
    end
    memory.writeword(0x02026CB0, side_coordinates[current_side][1])
    memory.writeword(player_objects[2].base + 0x64, side_coordinates[current_side][3])
    memory.writeword(player_objects[1].base + 0x64, side_coordinates[current_side][2])
    emu.speedmode("normal")
  end
end

return _elbow_cannon

-- player_objects[2].base + 0x9F -> P2 Life (byte)
-- player_objects[2].base + 0x64 -> P2 pos_x (word)
-- 0x020691A7 -> P1 damage of next hit (byte)
-- 0x02026CB0 -> Screen center X (word)
-- 0x02011377 -> Time (byte)

-- require('luacom').CreateObject("wmplayer.ocx").URL="my.mp3" -> Attempt to play sound

-- test = gui.gdscreenshot() -> Testing the gd features
-- gui.gdoverlay(0, 0, test)
-- local im = gd.create(220, 190)
-- local back = im:colorAllocateAlpha(30, 30, 200, 127)
-- local black = im:colorAllocate(0, 0, 0)
-- local blue = im:colorAllocate(30, 30, 200)
-- im:colorTransparent(black)
-- gd.useFontConfig(true)
-- im:string(gd.FONT_MEDIUM, _x, 49, _text, blue)
-- gui.image(im:gdStr())
-- gd.stringFT("teal", "Times-12", 20, 0, _x, 49, _text)