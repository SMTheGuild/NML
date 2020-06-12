dofile "$CONTENT_e4f2e55e-de59-4268-a512-3d02b9b69d16/Scripts/MenuLib.lua"

MenuPart = class()

function MenuPart.client_onCreate( self )
    self:client_onRefresh()
end

function MenuPart.client_onRefresh( self )
	dofile "$CONTENT_e4f2e55e-de59-4268-a512-3d02b9b69d16/Scripts/MenuLib.lua"
    -- To get rid of old layout, if there is one
    if self.layout then self.layout:destroy() end

    -- Create a new layout, all the options are listed in the library
    self.layout = sm.menu.create( self,
    { -- Menu parameters
        projection = "standard",
        p_params = {},
        selector = "standard",
        s_params = {},
        canceler = "standard",
        c_params = {}
    },
    { -- Node sets
        {
            distribution = "radial",
            d_params = {},
            nodes = {
                {name = "node0", template = "leftClick", overwrite = {color = sm.color.new(0xffa50000), hl_color = sm.color.new(0xffc52000)}},
                {name = "node1", template = "leftClick", overwrite = {color = sm.color.new(0x18369300), hl_color = sm.color.new(0x3856b300)}},
                {name = "node2", template = "leftClick", overwrite = {color = sm.color.new(0x63d50c00), hl_color = sm.color.new(0x83f52c00)}}
            }
        },
        {
            distribution = "radial",
            d_params = {
                offset = 0.5
            },
            nodes = {
                {name = "node5", template = "leftClick", overwrite = {color = sm.color.new(0xffa50000), hl_color = sm.color.new(0xffc52000)}},
                {name = "node6", template = "leftClick", overwrite = {color = sm.color.new(0x18369300), hl_color = sm.color.new(0x3856b300)}},
                {name = "node7", template = "leftClick", overwrite = {color = sm.color.new(0x63d50c00), hl_color = sm.color.new(0x83f52c00)}},
                {name = "node8", template = "leftClick", overwrite = {color = sm.color.new(0xc0000000), hl_color = sm.color.new(0xe0202000)}},
                {name = "node9", template = "leftClick", overwrite = {color = sm.color.new(0x30303000), hl_color = sm.color.new(0x50505000)}},
                {name = "node10", template = "leftClick", overwrite = {color = sm.color.new(0xffa50000), hl_color = sm.color.new(0xffc52000)}},
                {name = "node11", template = "leftClick", overwrite = {color = sm.color.new(0x18369300), hl_color = sm.color.new(0x3856b300)}},
                {name = "node12", template = "leftClick", overwrite = {color = sm.color.new(0x63d50c00), hl_color = sm.color.new(0x83f52c00)}},
                {name = "node13", template = "leftClick", overwrite = {color = sm.color.new(0xc0000000), hl_color = sm.color.new(0xe0202000)}},
            }
        }
    },
    { -- Node defaults
    })
end

-- \/ Just copy paste this \/ --

function MenuPart.client_onFixedUpdate( self, dt )
    sm.menu.onFixedUpdate()
end

function MenuPart.client_onInteract( self, character, state )
    if state then
        self.layout:toggle()
    end
end

function MenuPart.client_onDestroy( self )
	self.layout:destroy()
end

function MenuPart.client_onAction( self, action, state )
	sm.menu.updateActions( action, state )
	return false
end