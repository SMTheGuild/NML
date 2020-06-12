--[[
Node Menu Library by Mini. All rights reserved.
This library is still WORK IN PROGRESS, big changes can be made in the future. They may break your dependant mods.
Do NOT modify and reshare the library on workshop for compatibility reasons.
If there is a change you'd like to see, let me know, I'm trying to make this library as open as possible anyways.
]]--


-- #pragma once
--if sm.menu then return end

sm.menu = {}

-- Buffer with all inputs
local actions = {}
local reset_actions = function()
    actions[sm.interactable.actions.left] = sm.tool.interactState.null
    actions[sm.interactable.actions.right] = sm.tool.interactState.null
    actions[sm.interactable.actions.forward] = sm.tool.interactState.null
    actions[sm.interactable.actions.backward] = sm.tool.interactState.null
    actions[sm.interactable.actions.item0] = sm.tool.interactState.null
    actions[sm.interactable.actions.item1] = sm.tool.interactState.null
    actions[sm.interactable.actions.item2] = sm.tool.interactState.null
    actions[sm.interactable.actions.item3] = sm.tool.interactState.null
    actions[sm.interactable.actions.item4] = sm.tool.interactState.null
    actions[sm.interactable.actions.item5] = sm.tool.interactState.null
    actions[sm.interactable.actions.item6] = sm.tool.interactState.null
    actions[sm.interactable.actions.item8] = sm.tool.interactState.null
    actions[sm.interactable.actions.item7] = sm.tool.interactState.null
    actions[sm.interactable.actions.item9] = sm.tool.interactState.null
    actions[sm.interactable.actions.use] = sm.tool.interactState.null
    actions[sm.interactable.actions.jump] = sm.tool.interactState.null
    actions[sm.interactable.actions.attack] = sm.tool.interactState.null
    actions[sm.interactable.actions.create] = sm.tool.interactState.null
end
reset_actions()

-- Update management
local last_update = sm.game.getCurrentTick()

local active_menus = {}
local active_counter = 0

local action_host = nil

-- Instance indexing
local index = 0

-- Abort management
local abort_counter = 0


local empty_function = function( ... ) end



--[[
Distributors are responsible for arranging the nodes locally.
]]--

local std_distributors = {}



--[[
Name:
    Custom distribution

Description:
    Custom distributing function.
    Allows for custom placement of each node.

Global parameters:
    None

Local parameters:
    Key:        Type:       Default:    Description:

    position    Vec3        0, 0, 0     Local position of the node.
]]--
std_distributors.custom = function( node_count, parameters )
    return function()
        return nil
    end
end



--[[
Name:
    Radial distribution

Description:
    Radial distributing function.
    Distributes the nodes on a circle equally.

Global parameters:
    Key:        Type:       Default:    Description:

    offset      Number      0           Angular position offset. 1 meaning nodes changing places 1 position clockwise.
    node_spread Number      2           Distance between the center of the nodes.
    min_radius  Number      nil         Smallest possible radius for node centers.
    max_radius  Number      nil         Biggest possible radius for node centers.
    radius      Number      nil         Forced radius for node centers.

Local parameters:
    None
]]--
std_distributors.radial = function( node_count, parameters )
    local offset = parameters.offset or 0
    local node_spread = parameters.node_spread or 1

    local increment = 6.28318530718 / node_count
    local radius = math.sqrt( node_spread * node_spread / ( 2 * ( 1 - math.cos( increment ) ) ) )

    if parameters.radius then radius = parameters.radius
    elseif parameters.min_radius and radius < parameters.min_radius then radius = parameters.min_radius
    elseif parameters.max_radius and parameters.max_radius < radius then radius = parameters.max_radius end

    local index = 0
        
    return function()
        local position = ( index - 1 + offset ) * increment
        index = index + 1
        return sm.vec3.new( math.sin( position ) * radius, math.cos( position ) * radius, 0 ), sm.quat.identity()
    end
end



--[[
Projections are responsible for translating local positions into global positions.
]]--

local std_projections = {}



--[[
Name:
    Standard projection

Description:
    Standard projecting function.
    Displays the nodes based on the player's position, constant distance away from him.

Global parameters:
    Key:        Type:       Default:    Description:

    distance    Number      2           The distance away from the player (for node's Z = 0).

Local parameters:
    None
]]--
std_projections.standard = function( part, parameters )
    local distance = parameters.distance or 2

    local delta = part.shape:getWorldPosition() - sm.localPlayer.getPosition()
    local delta_length = delta:length()
    local at = delta / delta_length

    local right = at:cross( sm.vec3.new( 0, 0, 1 ) ):normalize()
    local up = right:cross( at ):normalize()

    local position = part.shape:getWorldPosition() + at * ( distance - delta_length )

    return {
        position = position,
        base = { x = right, y = up, z = at }
    }
end



--[[
Selectors are responsible for deciding whether a node is selected or not.
]]--

local std_selectors = {}



--[[
Name:
    Standard selection

Description:
    Standard selecting function.
    Considers the nodes that are close enough to camera ray as selected.

Global parameters:
    Key:        Type:       Default:    Description:

    distance    Number      0.125       The distance below which node is selected. Bigger than 0.

Local parameters:
    None
]]--
std_selectors.standard = function( part, parameters )
    local distance = parameters.distance or 0.125

    return function( position )
        local delta = position - sm.camera.getPosition()
        local dot = sm.camera.getDirection():dot( delta )
        return math.sqrt( delta:length2() - dot * dot ) < distance
    end
end



--[[
Cancelers are responsible for closing the menu under certain conditions.
]]--

local std_cancelers = {}



--[[
Name:
    Standard cancelation

Description:
    Standard canceling function.
    Closes the menu if the player is too far away or looks away from the center too far.

Global parameters:
    Key:        Type:       Default:    Description:

    distance    Number      4           The distance above which menu closes. Bigger than 0.
    angle       Number      90          The angle (away from interactable) above which menu closes. Degrees from 0, 180 range.

Local parameters:
    None
]]--
std_cancelers.standard = function( part, parameters )
    local distance = parameters.distance or 6
    local angle = ( parameters.angle or 30 ) * math.pi / 180

    return function( parameters )
        local delta = part.shape:getWorldPosition() - sm.localPlayer.getPosition()
        return ( angle < math.acos( delta:normalize():dot( sm.camera.getDirection() ) ) ) or ( distance < delta:length() )
    end
end



--[[
Predefined callbacks.
]]--

local shallowCopy = function( tab_in, tab_out )
    tab_out = tab_out or {}
    for key, value in pairs(tab_in) do
        tab_out[key] = value
    end
    return tab_out
end

local std_nodes = {}

std_nodes.empty = {
    -- Definition  -- No touching!
    name = {},
    position = sm.vec3.new( 0, 0, 0 ),
    rotation = sm.quat.new( 0, 0, 0, 1 ),
    -- Events
    onCreate = empty_function, -- function( node ) end
    open = empty_function, -- function( node )  end
    close = empty_function, -- function( node )  end
    onUpdate = empty_function, -- function( selected, actions, node, menu, part )  end
    onProject = empty_function, -- function( node, projection )  end
    onDestroy = empty_function -- function( node )  end
}

std_nodes.leftClick = {
    -- Definition -- No touching!
    name = {},
    position = sm.vec3.new( 0, 0, 0 ),
    rotation = sm.quat.new( 0, 0, 0, 1 ),
    -- Properties -- Things that will get changed only by overwriting it with another value (or reference to another userdata/table).
    color = sm.color.new(0x44444400),
    hl_color = sm.color.new(0xbbbbbb00),
    scale = 1,
    hl_scale = 1.2,
    -- Events
    onCreate = function( node ) -- Everything that has the risk of being shared between nodes with a reference
        node.shape = sm.effect.createEffect( "ShapeRenderable" )
        node.shape:setParameter( "uuid", sm.uuid.new("7c318eed-e91a-4a24-b3c8-67918258b80c") )
        node.shape:setParameter( "color", node.color )
        node.shape:setScale( sm.vec3.new( 1, 1, 1 ) * node.scale )

        node.text = sm.gui.createNameTagGui()
        node.text:setRequireLineOfSight( true )
        node.text:setText( "Text", node.name )
        node.text:setMaxRenderDistance(100)
    end,
    open = function( node ) -- Display ON
        node.shape:start()
        node.text:open()
    end,
    close = function( node ) -- Dispay OFF
        node.shape:stop()
        node.text:close()
    end,
    onUpdate = function( node, selected, actions, menu, part ) -- Called every tick
        if selected > 0 then
            if actions[19] == sm.tool.interactState.start then node.onClick( node, menu, part ) end
        end
        if selected == sm.tool.interactState.start then
            node.shape:setScale( sm.vec3.new( 1, 1, 1 ) * node.hl_scale )
            node.shape:setParameter( "color", node.hl_color )
        elseif selected == sm.tool.interactState.stop then
            node.shape:setScale( sm.vec3.new( 1, 1, 1 ) * node.scale )
            node.shape:setParameter( "color", node.color )
        end
    end,
    onClick = empty_function, -- function( node, menu, part )  end -- Called when LMB is clicked
    onProject = function( node, pro ) -- Updates the node's position
        local position = pro.position +
        pro.base.x * node.position.x +
        pro.base.y * node.position.y +
        pro.base.z * node.position.z
        node.shape:setPosition( position )
        node.text:setWorldPosition( position )
        return position
    end,
    onDestroy = function( node ) -- Cleanup
        node.shape:destroy()
        node.text:destroy()
    end
}



-- MAIN

--[[
Name:
    Menu creator

Description:
    Creates the menu instance.
    Global parameters apply to the whole menu.
    Local parameters apply to specific nodes.

Parameters:
    Key:            Type:               Default:    Description:

    projection      string / function   "standard"  Projection function. Accepts either a name of a registered one or a custom made function.
    p_params        table               {}          Table of additional global parameters.

    selector        string / function   "standard"  Selection function. Accepts either a name of a registered one or a custom made function.
    s_params        table               {}          Table of additional global parameters.

    canceler        string / function   "standard"  Cancelation function. Accepts either a name of a registered one or a custom made function.
    c_params        table               {}          Table of additional global parameters.

Node sets - naturally indexed table of
Node set:
    Key:            Type:               Default:    Description:

    distributor     string / function   "custom"    Distribution function. Accepts either a name of a registered one or a custom made function.
    d_params        table               {}          Table of additional global parameters.
    nodes           table               nil         Table of nodes.

Node:
    Key:            Type:               Default:    Description:

    name            string              nil         Reference name of the node.
    template        string / table      nil         Name of predefined node template or a reference to a custom template table.
    overwrite       table               {}          Table of node properties to overwrite

Node defaults - table of default node properties.
]]--
sm.menu.create = function( part, parameters, node_sets, node_defaults )
    -- Instance variables
    local id = index
    index = index + 1
    local state = false
    -- General parameters
    local create_projection = (parameters.projection and type(parameters.projection) == "string" and std_projections[parameters.projection] or parameters.projection) or std_projections["standard"]
    local p_params = parameters.p_params or {}
    local create_selector = (parameters.selector and type(parameters.selector) == "string" and std_selectors[parameters.selector] or parameters.selector) or std_selectors["standard"]
    local s_params = parameters.s_params or {}
    local create_canceler = (parameters.canceler and type(parameters.canceler) == "string" and std_cancelers[parameters.canceler] or parameters.canceler) or std_cancelers["standard"]
    local c_params = parameters.c_params or {}
    -- Table setup
    local nodes = {}
    -- Distributions
    for _, node_set in pairs(node_sets) do
        local create_distribution = (node_set.distribution and type(node_set.distribution) == "string" and std_distributors[node_set.distribution] or node_set.distribution) or std_distributors["custom"]
        local d_params = node_set.d_params or {}
        local distributor = create_distribution( #node_set.nodes , d_params )
        for index, properties in pairs(node_set.nodes) do
            local name = properties.name or "_index_"..tostring( index )
            nodes[name] = shallowCopy( properties.overwrite, shallowCopy( node_defaults , shallowCopy((properties.template and type(properties.template) == "string" and std_nodes[properties.template] or properties.template) or std_nodes["leftClick"]) ) )
            nodes[name].name = name
            nodes[name].position, nodes[name].rotation = distributor() or nodes[name].position, nodes[name].rotation
            nodes[name]:onCreate()
        end
    end

    -- Selection
    local selector = create_selector( part, s_params )
    local canceler = create_canceler( part, c_params )

    return {
        -- Starts displaying the menu
        open = function( menu )
            if active_menus[id] ~= nil then return end
            -- Start input gathering
            if active_counter == 0 then -- No existing host case
                action_host = part
                sm.localPlayer.getPlayer():getCharacter():setLockingInteractable( action_host.interactable )
            end
            -- Add to active menus
            active_menus[id] = {menu = menu, part = part}
            active_counter = active_counter + 1
            -- Change state
            state = true
            -- Turn ON display
            for _, node in pairs(nodes) do
                node:open()
            end
        end,

        -- Called every fixed frame, for functional purposes
        update = function( menu, part )
            local projector = create_projection( part, p_params )
            for _, node in pairs( nodes ) do
                -- Update position
                local bool_selected = selector( node:onProject( projector ) )
                -- Selected buffer
                local selected
                if bool_selected then
                    if node.prev_selected then selected = sm.tool.interactState.hold
                    else selected = sm.tool.interactState.start end
                else
                    if node.prev_selected then selected = sm.tool.interactState.stop
                    else selected = sm.tool.interactState.null end
                end
                --
                node:onUpdate( selected, actions, menu, part )
                -- Selected buffer
                node.prev_selected = bool_selected
            end
            if canceler() then
                menu:close()
            end
        end,

        -- Stops displaying the menu
        close = function( menu )
            if active_menus[id] == nil then return end
            -- Remove from active menus
            active_menus[id] = nil
            active_counter = active_counter - 1
            -- Stop input gathering
            if active_counter == 0 then -- No more active menus case
                action_host = nil
                sm.localPlayer.getPlayer():getCharacter():setLockingInteractable( nil )
                abort_counter = 0
                reset_actions()
            elseif action_host == part then -- Change host case
                for _, data in pairs( active_menus ) do
                    action_host = data.part
                    sm.localPlayer.getPlayer():getCharacter():setLockingInteractable( action_host.interactable )
                    break
                end
            end
            -- Change state
            state = false
            -- Turn OFF display
            for _, node in pairs( nodes ) do
                node:close()
            end
        end,

        -- Destroys the data
        destroy = function( menu )
            menu:close()
            for _, node in pairs( nodes ) do
                node:onDestroy()
                node = nil
            end
            menu = nil
        end,

        -- Toggles between start and stop
        toggle = function( menu )
            if state then
                menu:close()
            else
                menu:open()
            end
        end
    }
end

sm.menu.open = function( menu )
    return menu:open()
end

sm.menu.update = function( menu )
    return menu:update()
end

sm.menu.close = function( menu )
    return menu:close()
end

sm.menu.destroy = function( menu )
    return menu:destroy()
end

sm.menu.toggle = function( menu )
    return menu:toggle()
end

sm.menu.updateActions = function( action, state )
    if active_menus == 0 then return end
    if actions[action] then
        actions[action] = state and sm.tool.interactState.start or sm.tool.interactState.stop
    end
end

sm.menu.onFixedUpdate = function()
	if active_counter == 0 then return end
    if last_update == sm.game.getCurrentTick() then return end
    last_update = sm.game.getCurrentTick()
    -- Emergency abort
    if sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() ~= action_host.interactable then
        abort_counter = abort_counter + 1
    elseif abort_counter > 0 then
        abort_counter = 0
    end
    if abort_counter > 1 then
        for _, data in pairs( active_menus ) do
            --data.menu:close()
        end
        return
    end
    -- Display all active menus
    for _, data in pairs( active_menus ) do
        data.menu:update( data.part )
    end
    -- Buffer inputs
    for index, state in pairs( actions ) do
        if state == sm.tool.interactState.start then actions[index] = sm.tool.interactState.hold
        elseif state == sm.tool.interactState.stop then actions[index] = sm.tool.interactState.null end
    end
end