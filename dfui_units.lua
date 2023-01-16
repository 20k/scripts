--@ module = true
imgui = dfhack.imgui
render = reqscript('dfui_render')

function display_unit_list(units)
    for _,v in ipairs(units) do
        local name = render.get_user_facing_name(v)
        local col = render.get_unit_colour(v)

        if imgui.ButtonColored(col, name) then
            render.centre_camera(v.pos.x, v.pos.y, v.pos.z)
        end

        if imgui.IsItemHovered() then
            render.render_absolute_text('X', COLOR_YELLOW, COLOR_BLACK, v.pos)
        end
    end
end

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

    if imgui.BeginTabBar("UnitTabs", 0) then
        if imgui.BeginTabItem("Citizens") then
            display_unit_list(citizens)

            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Pets/Livestock") then
            display_unit_list(pets)

            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Others") then
            display_unit_list(others)

            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Dead/Missing") then
            display_unit_list(dead)

            imgui.EndTabItem()
        end

        imgui.EndTabBar()
    end
end