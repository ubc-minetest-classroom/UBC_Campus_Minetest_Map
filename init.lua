UBCMap = { path = minetest.get_modpath("ubc_campus_minetest_map"), storage = minetest.get_mod_storage() }

function UBCMap:placeSchematic(pos1, pos2, v, rotation, replacement, force_placement)

    -- Read data into LVM
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(pos1, pos2)
    local a = VoxelArea:new {
        MinEdge = emin,
        MaxEdge = emax
    }

    minetest.place_schematic_on_vmanip(vm, pos1, UBCMap.path .. "/schems/ubc_blocks_" .. tostring(v) .. ".mts", rotation, replacement, force_placement)
    minetest.chat_send_all("combined terrain tile " .. tostring(v))
    minetest.place_schematic_on_vmanip(vm, pos1, UBCMap.path .. "/schems/ubc_trees_" .. tostring(v) .. ".mts", rotation, replacement, force_placement)
    minetest.chat_send_all("combined trees tile " .. tostring(v))
    minetest.place_schematic_on_vmanip(vm, pos1, UBCMap.path .. "/schems/ubc_urban_" .. tostring(v) .. ".mts", rotation, replacement, force_placement)
    minetest.chat_send_all("combined urban tile " .. tostring(v))

    vm:write_to_map(true)
end

local inProgress = false

function UBCMap.place(startPosition)
    -- GC before we start placing the map
    collectgarbage("collect")

    if (inProgress == true) then
        return false, "Map placement already in progress. Try again later", 1
    end

    -- If we crash during world generation, we'll try again.
    local startingValue = UBCMap.storage:get_int("placementProgress")
    if (startingValue == nil or startingValue == 0) then
        startingValue = 1
        UBCMap.storage:set_string("startPosition", minetest.serialize(startPosition))
        UBCMap.storage:set_int("generating", 1)

        Debug.log(UBCMap.storage:get_int("generating"))
        minetest.chat_send_all("Placing UBC Map")
    else
        startPosition = UBCMap.storage:get_string(minetest.deserialize("startPosition"))
        minetest.chat_send_all("Previous minetest instance crashed while placing UBC Map... Trying again from position: " .. startingValue)
    end

    if (startPosition == nil) then
        startPosition = { x = 0, y = -3, z = 0 }
    else
        startPosition = { x = startPosition.x, y = startPosition.y, z = startPosition.z }
    end

    local coords = {}
    for xx = 0, 2500, 500 do
        for zz = 1, 7 do
            local z = 3500 - (zz * 500)
            table.insert(coords, { xx + startPosition.x, z + startPosition.z })
        end
    end

    if (startingValue <= 28) then
        for v = startingValue, 28 do
            --for _, v in pairs(tiles) do
            local coord = coords[v]
            -- y must always be -3 because the schematic pos starts here
            -- this maintains the true elevations across the map
            -- place terrain first


            local startPos = { x = coord[1], y = startPosition.y, z = coord[2] }
            local endPos = { x = startPos.x + 500, y = startPos.y + 500, z = startPos.z + 500 }

            UBCMap:placeSchematic(startPos, endPos, v, "0", nil, false)
            minetest.chat_send_all("Placed combined tile: " .. tostring(v) .. " in world.")

            UBCMap.storage:set_int("placementProgress", v)

            local completion = tonumber(string.format("%.2f", (v / 28) * 100))

            Debug.log(completion .. " % done!")
            minetest.chat_send_all(completion .. " % done!")

            collectgarbage("collect")
        end

        -- Collect garbage again;
        collectgarbage("collect")
    end

    UBCMap.storage:set_int("generating", 0)
    UBCMap.storage:set_string("placementPos", "")

    Debug.log("Finished placing UBC Map!")
    minetest.chat_send_all("Finished generating!")

    inProgress = false
    return true, "Map placed succesfully", 0

end

dofile(UBCMap.path .. "/integration.lua")

minetest.after(0, function()
    Debug.log("Checking if the UBC map placement needs to resume...")
    local status = UBCMap.storage:get_int("generating")
    Debug.log("Status: " .. tostring(status))
    if (status == 1) then
        Debug.log(tostring(status) .. ": Resuming UBC map placement...")
        local pos = minetest.deserialize(UBCMap.storage:get_string("placementPos"))
        UBCMap.place(pos)
    else
        Debug.log(tostring(status) .. ": No UBC map placement in progress.")
    end
end)




