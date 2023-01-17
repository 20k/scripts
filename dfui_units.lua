--@ module = true
imgui = dfhack.imgui
render = reqscript('dfui_render')
time = reqscript('dfui_libtime')

function migration_date_name(unit)
    local current_tick = df.global.cur_year_tick
    local current_year = df.global.cur_year
    local arrival_time = current_tick - unit.curse.time_on_site;

    local full_time = time.year_to_tick(current_year) + arrival_time

    local ymd = time.time_to_ymd(full_time)

    return time.months()[ymd.month+1] .. ", " .. tostring(ymd.year)
end

function display_unit_list(units)
    local last_migration_date_name = ""
    local active = false

    for _,v in ipairs(units) do
        local migration_name = migration_date_name(v)

        if migration_name ~= last_migration_date_name then
            --imgui.Text("Arrived:", migration_name)
            if active then
                imgui.TreePop()
            end

            imgui.Unindent()
            active = imgui.TreeNodeEx("Arrived: " .. migration_name, (1<<5))
            imgui.Indent()

            last_migration_date_name = migration_name
        end

        if active then
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

    if active then
        imgui.TreePop()
    end

    imgui.Unindent()
end

function sort_by_migration_wave(units)
    function cmp(a, b)
        return a.curse.time_on_site > b.curse.time_on_site
    end

    table.sort(units, cmp)
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

    sort_by_migration_wave(citizens)
    sort_by_migration_wave(pets)
    sort_by_migration_wave(others)
    sort_by_migration_wave(dead)

    if imgui.BeginTabBar("UnitTabs", 0) then
        if imgui.BeginTabItem("Citizens") then
            imgui.NewLine()
            display_unit_list(citizens)

            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Pets/Livestock") then
            imgui.NewLine()
            display_unit_list(pets)

            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Others") then
            imgui.NewLine()
            display_unit_list(others)

            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Dead/Missing") then
            imgui.NewLine()
            display_unit_list(dead)

            imgui.EndTabItem()
        end

        imgui.EndTabBar()
    end
end