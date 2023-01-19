--@ module = true
imgui = dfhack.imgui
render = reqscript('dfui_render')

function render_units()
    render.set_can_window_pop(true)

    local citizens = {}
    local pets = {}
    local others = {}
    local dead = {}

    for k,v in ipairs(df.global.world.units.active) do
        if dfhack.units.isHidden(v) then
            goto hidden
        end

        if dfhack.units.isKilled(v) then
            dead[#dead+1] = v
        elseif dfhack.units.isFortControlled(v) then
            if dfhack.units.isAnimal(v) then
                pets[#pets+1] = v
            else
                citizens[#citizens + 1] = v
            end
        else
            others[#others+1] = v
        end

        ::hidden::
    end

    local opts = {center_on_click = true}

    if imgui.BeginTabBar("UnitTabs", 0) then
        if imgui.BeginTabItem("Citizens") then
            imgui.NewLine()
            render.display_unit_list(citizens, opts)

            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Pets/Livestock") then
            imgui.NewLine()
            render.display_unit_list(pets, opts)

            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Others") then
            imgui.NewLine()
            render.display_unit_list(others, opts)

            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Dead/Missing") then
            imgui.NewLine()
            render.display_unit_list(dead, opts)

            imgui.EndTabItem()
        end

        imgui.EndTabBar()
    end
end