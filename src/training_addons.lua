require("src/menu_widgets")
require("src/tools")

training_addons_path = "src/training_addons/"

function get_module_list()
  print("Loading modules")
  local module_list = {module_id = 1, module_name = {"none"}, module_entry_point = {""}, module_config = {{}}}
  local _cmd = "dir /b /a:d "..string.gsub(training_addons_path, "/", "\\")
  local _f = io.popen(_cmd)

  if _f == nil then
    print(string.format("Error: Failed to execute command \"%s\"", _cmd))
    return module_list
  end

  local _str = _f:read("*all")

  for _line in string.gmatch(_str, '([^\r\n]+)') do -- List all folders in training_addons

    local _config = read_object_from_json_file(training_addons_path.._line.."/config.json")

    if _config ~= nil then
      if _config.entry_point ~= nil then

        local entry_point_with_ext = string.gsub(_config.entry_point, ".lua", "")..".lua"
        local _entry_point_path = training_addons_path.._line.."/"..entry_point_with_ext
        local _f = io.open(_entry_point_path, "r")

        if _f ~= nil then
          print(string.format('Module: %s found', _config.module_name or _line))
          table.insert(module_list["module_name"], _config.module_name or _line)
          table.insert(module_list["module_entry_point"], ""..string.gsub(_entry_point_path, ".lua", ""))
          table.insert(module_list["module_config"], _config)
        else
          print(string.format('Warning: Entry point %s/%s not found', _line, entry_point_with_ext))
          print("-- Will skip module --")
        end
      else
        print(string.format('Warning: No entry point found in %s/config.json', _line))
        print("-- Will skip module --")
      end
    else
      print(string.format('Warning: No config.json found in %s folder', _line))
      print("-- Will skip module --")
    end
  end

  return module_list
end

function open_addon_menu(modules)
  if modules.module_id == 1 then return end
  local _module = require(modules.module_entry_point[modules.module_id])
  if _module == nil then return end

  _module.set_config(modules.module_config[modules.module_id])
  _current_module = _module
  _module.open_menu()
end

