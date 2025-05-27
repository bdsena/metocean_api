function get_dir_from_azim(wave_azim, ndir)
  wave_azim = tonumber(wave_azim)
  if wave_azim == nil then return nil end
  ndir = tostring(ndir)
  
  local all_dirs = {
    ["8"] = {"N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"},
    ["16"] = {"N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N"},
  }
  
  local az_step = 22.5
  if ndir == "16" then
    az_step = az_step / 2
  end
  
  local wave_dir = nil
  local azim = 0
  for idir = 1, #all_dirs[ndir] do
    if (wave_azim > azim - az_step) and (wave_azim <= azim + az_step) then
      wave_dir = all_dirs[ndir][idir]
      break
    end
    azim = azim + 2 * az_step
  end
  return wave_dir
end

function api_cluster_lc_table(init_cluster_data, rao_data)
  
  local lc_table = {
    waves = {},
    currents = {},
    lcases = {},
  }
  
  local function get_rao_from_hs(hs)
    local wave_raos = {}
    for idraft, draft_data in ipairs(rao_data) do
      local irao = 0
      local nraos = #draft_data.rao_selection
      local hsmax
      repeat
        irao = irao + 1
        hsmax = tonumber(draft_data.rao_selection[irao].hsmax) or math.huge
      until hs <= hsmax or irao == nraos
      table.insert(wave_raos, {
        rao = draft_data.rao_selection[irao],
        draft_label = draft_data.label,
        addz_offset = draft_data.draft or 0.0
      })
    end
    return wave_raos
  end
  
  for label, cluster in pairs(init_cluster_data) do
    local wave_raos = get_rao_from_hs(cluster.Hs1m)
    for irao, wave_rao in ipairs(wave_raos) do
      table.insert(lc_table.waves, {
        label = label,
        hs1 = cluster.Hs1m,
        tp1 = cluster.Tpe1m,
        dir1 = cluster.Dir1m,
        hs2 = cluster.Hs2m,
        tp2 = cluster.Tpe2m,
        dir2 = cluster.Dir2m,
        occ = cluster.ocorr,
      })
      table.insert(lc_table.currents, cluster.current_data)
      local lclabel = "LC_"..label
      if wave_rao.draft_label then
        lclabel = wave_rao.draft_label.."_"..lclabel
      end
      table.insert(lc_table.lcases, {
        label = lclabel,
        rao_label = wave_rao.rao.label,
        mov_type = "Wave Related",
        wave_label = label,
        wave_azim = cluster.Dir1m,
        curr_label = cluster.current_data.lbl,
        offset_value = 0.0,
        offset_type = "% WD",
        offset_azim = (cluster.Dir1m + 180.0) % 360.0,
        addx_offset = 0.0,
        addy_offset = 0.0,
        addz_offset = wave_rao.addz_offset
      })
    end
  end
  table.sort(lc_table.waves, function(a,b) return a.label < b.label end)
  table.sort(lc_table.lcases, function(a,b) return a.label < b.label end)
  table.sort(lc_table.currents, function(a,b) return a.lbl < b.lbl end)
  
  return lc_table
  
end
