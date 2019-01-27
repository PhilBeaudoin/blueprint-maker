script.on_init(function(event)
    register_commands()
end)

script.on_load(function(event)
    register_commands()
end)

function register_commands()
    commands.add_command('field', 'Add some field details to the selected entity.', field)
    commands.add_command('getfield', 'Get the field details of the selected entity.', getfield)
    commands.add_command('filename', 'Set the filename for the next saved entity.', filename)
end

function field(command)
    global.fields = global.fields or {}
    local player = game.players[command.player_index]
    local entity = player.selected
    if not entity then
        player.print('You need to hover over an entity to apply a field to it.')
        return
    end
    global.fields[entity.unit_number] = command.parameter
    if command.parameter then
        player.print('Assigned field "' .. command.parameter .. '" to unit number ' .. entity.unit_number)
    else
        player.print('Cleard field for unit number ' .. entity.unit_number)
    end
end

function getfield(command)
    global.fields = global.fields or {}
    local player = game.players[command.player_index]
    local entity = player.selected
    if not entity then
        player.print('You need to hover over an entity to get its field.')
        return
    end
    local field = global.fields[entity.unit_number]
    if field then
        player.print('Unit number ' .. entity.unit_number .. ' has field "' .. field .. '"')
    else
        player.print('Unit number ' .. entity.unit_number .. ' does not have a field.')
    end
end

function filename(command)
    global.filename = command.parameter
    game.players[command.player_index].print('Set filename to "' .. command.parameter .. '"')
end

script.on_event(defines.events.on_player_setup_blueprint, function(event)
    global.fields = global.fields or {}
    local player = game.players[event.player_index]
    local entities = player.surface.find_entities(event.area)
    local tiles = player.surface.find_tiles_filtered{area = event.area, name = {
        'concrete', 'hazard-concrete-left', 'hazard-concrete-right', 'refined-concrete',
        'refined-hazard-concrete-left', 'refined-hazard-concrete-right', 'stone-path'
    }}
    local left_x = math.floor(event.area.left_top.x / 2) * 2
    local top_y = math.floor(event.area.left_top.y / 2) * 2
    local blueprint = {}
    for _, entity in ipairs(entities) do
        if entity.name ~= 'item-on-ground' and entity.name ~= 'stone' then
            local new_entity = {
                name = entity.name,
                direction = entity.direction,
                position = {
                    x = entity.position.x - left_x,
                    y = entity.position.y - top_y
                },
                field = global.fields[entity.unit_number]
            }
            if entity.type == 'underground-belt' then
                new_entity.type = entity.belt_to_ground_type
            end
            table.insert(blueprint, new_entity)
        end
    end
    local blueprint_tiles = {}
    for _, tile in ipairs(tiles) do
        local new_tile = {
            name = tile.name,
            position = {
                x = tile.position.x - left_x,
                y = tile.position.y - top_y
            }
        }
        table.insert(blueprint_tiles, new_tile)
    end

    game.write_file(global.filename, 'blueprint = \n' .. serpent.block(blueprint) .. ',\n\n')
    game.write_file(global.filename, 'blueprint_tiles = \n' .. serpent.block(blueprint_tiles), true)

end)