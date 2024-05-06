local _elbow_cannon = require("src/training_addons/Necro_Collective/elbow_cannon")
local _stun_juggles = require("src/training_addons/Necro_Collective/stun_juggles")
local _hit_confirm = require("src/training_addons/Hit_Confirm/hit_confirm")

local necro = {}
local menu = nil
local current_training = 0
local is_routine = false

local routine = {
  _elbow_cannon,
  _stun_juggles,
  _hit_confirm,
}

local color_button = {
  "LP",
  "MP",
  "HP",
  "LK",
  "MK",
  "HK",
  "LP+MK+HP"
}

local selected_mode = {
  "elbow cannon",
  "stun juggles",
  "hit confirm",
}

local _routine_menu = make_menu(100, 79, 283, 160, -- screen size 383,223,
  {
    button_menu_item("Skip", function()
      necro.end_training()
    end),
    button_menu_item("Quit", function()
      necro.end_routine()
    end),
  }
)

necro.constants = {
  timer_cyphers_width = 16,
  timer_cyphers_height = 26,
  whole_cast = {
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
  },
  training_data_to_keep = {
    display_frame_advantage = true,
    music_volume = true,
    display_p1_input_history = true,
    display_distances = true,
    display_p1_input_history_dyanamic = true,
    display_input = true,
    display_gauges = true,
    display_attack_data = true,
    display_p2_input_history = true,
    display_hitboxes = true,
  }
}
necro.config = {}

necro.images = {
  timer_frame = gd.createFromPng("src/training_addons/Necro_Collective/images/timer_frame.png"):gdStr(),
  timer_cyphers = gd.createFromPng("src/training_addons/Necro_Collective/images/timer_cyphers.png"):gdStr(),
}


function necro.open_menu()
  --necro.start_routine()
  menu = menu or set_menu()
  gui.box(0,0,0,0,0,0)
  menu_stack_clear()
  menu_stack_push(menu)
  menu_stack_draw()
end

function necro.set_config(_config)
  necro.config = _config
end

function set_menu()
  return make_multitab_menu(
    23, 15, 360, 195, -- same as main menu / screen size 383,223
    {
      {
        name = "General",
        entries = {
          list_menu_item("Color", necro.config, "color_button", color_button),
          list_menu_item("Favorite opponent", necro.config, "favorite_opponent", necro.constants.whole_cast),
          checkbox_menu_item("Routine mode", necro.config, "routine"),
          list_menu_item("Selected mode", necro.config, "selected_mode", selected_mode),
          button_menu_item("Start", necro.start_routine)
        }
      },
      _elbow_cannon.set_menu(),
      _stun_juggles.set_menu(),
      _hit_confirm.set_menu({
        "src/training_addons/Necro_Collective/data/hit_confirm.json",
        "src/training_addons/Necro_Collective/data/hit_confirm_2.json",
        "src/training_addons/Necro_Collective/data/hit_confirm_3.json"
      }),
    },
    function (_menu)
      if _menu.content[_menu.main_menu_selected_index].name == "Hit confirm" then
        _hit_confirm.update_menu(_menu)
      end
    end
  )
end

function character_select(p1, p2)
  start_character_select_sequence()
  select_character(1, p1.character, p1.color - 1, p1.sa - 1)
  select_character(2, p2.character, p2.color - 1, p2.sa - 1)
  emu.speedmode("turbo")
end

function necro.start_routine()
  reset_training_data(necro.constants.training_data_to_keep)
  if necro.config.routine then
    current_training = 1
    is_routine = true
    current_menu = _routine_menu
  else
    current_training = necro.config.selected_mode
    is_routine = false
    current_menu = routine[current_training].training_menu
  end
  while current_training <= #routine and not routine[current_training].is_enabled do
    current_training = current_training + 1
  end

  if current_training > #routine then
    print("No training enabled in routine. Enable at least one training.")
  else
    routine[current_training].start()
  end
end

function necro.start()
  reset_training_data(necro.constants.training_data_to_keep)
  current_training = menu.main_menu_selected_index - 1
  is_routine = false
  current_menu = routine[current_training].training_menu
  routine[current_training].start()
end

function necro.update()
  if current_training > 0 and current_training <= #routine then
    routine[current_training].update()
    if routine[current_training].has_ended then
      necro.end_training()
    end
  end
  memory.writeword(0x0201543E, 0x10) -- Lock current screen timer
end

function necro.end_training()
  if not is_routine then
    necro.end_routine()
  else
    repeat
      current_training = current_training + 1
    until current_training > #routine or routine[current_training].is_enabled

    if current_training > #routine then
      necro.end_routine()
    else
      routine[current_training].start()
    end
  end
end

function necro.end_routine()
  current_training = 0
  savestate.load(savestate.create("data/"..rom_name.."/savestates/results.fs"))
end

function necro.quit_training()
  current_training = 0
  current_menu = main_menu
  _current_module = nil
  is_menu_open = false
  menu_stack_clear()
  load_training_data()
end

return necro