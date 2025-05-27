local SM_NULL_HEADING = "SM"

function get_data_from_scatter(sctable, lc_directions, is_turret)
  
  local data = {}
  
  local direction_labels = {}
  for idir, dir_data in ipairs(lc_directions) do
  
    local dir_label = dir_data.name
    if sctable[dir_label] then
    
      local headings = {}
      if is_turret then
        for heading_key, dummy in pairs(sctable[dir_label]) do
          table.insert(headings, tonumber(heading_key))
        end
        table.sort(headings)
        for i = 1, #headings do
          headings[i] = tostring(headings[i])
        end
      else
        headings[1] = SM_NULL_HEADING
      end
      
      for ihea = 1, #headings do
        
        local hea_label = headings[ihea]
        local nrow = #sctable[dir_label][hea_label]
        local ncol = #sctable[dir_label][hea_label][1]
      
        for irow = 1, nrow do
        for icol = 1, ncol do
        
            occur = tonumber(sctable[dir_label][hea_label][irow][icol])
            if occur and occur > 0 then
              local new_data = {
                wave_hei = sctable.inc_height * irow,
                wave_per = sctable.inc_period * (icol - .5),
                wave_dir = dir_label,
                wave_occ = occur,
                current_label = dir_data.current,
                offset_value = dir_data.offset_value,
                offset_type = dir_data.offset_type,
                offset_href = dir_data.href,
                addx_offset = dir_data.addx_offset,
                addy_offset = dir_data.addy_offset,
                ship_wave_angle = tonumber(hea_label)
              }
              data[#data+1] = new_data
            end
            
        end
        end
        
      end
      
    end
  end
  
  return data
end

function api_get_loadings(method, lc_directions, floating_data, rao_data, wave_data, current_data)

  local loadings = nil
  local data = get_data_from_scatter(wave_data, lc_directions, floating_data.is_turret)
  
  if #data > 0 then
    
    if method == "Irregular" then
      data = nwaves_to_occurrence(data)
    end
  
    loadings = {
      waves = {},
      currents = {},
      lcases = {}
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
          addz_offset = draft_data.draft
        })
      end
      return wave_raos
    end
    
    local wcount = 0
    for i = 1, #data do
      
      local wave_raos = get_rao_from_hs(data[i].wave_hei)
      for irao, wave_rao in ipairs(wave_raos) do
      
        local wav_per = data[i].wave_per
        if wave_rao.rao.prd_by_dir then
          local aux_per = math.ceil(data[i].wave_per / wave_data.inc_period)
          wav_per = wave_rao.rao.prd_by_dir[data[i].wave_dir][aux_per]
        end
        
        if wav_per then
          
          wcount = wcount + 1
        
          local aux_hea = ""
          if data[i].ship_wave_angle then
            aux_hea = data[i].ship_wave_angle
          end
        
          local wave_label = "O"..match_zeros(wcount, #data)..
                            "_"..data[i].wave_dir..aux_hea..
                            "_H"..data[i].wave_hei..
                            "_T"..data[i].wave_per
                            --.."_N"..waves[i].occ
          
          local wdata = {
            label = wave_label,
            hs1 = data[i].wave_hei,
            tp1 = wav_per,
            dir1 = get_azim_from_dir(data[i].wave_dir),
            occ = data[i].wave_occ
          }
          
          table.insert(loadings.waves, wdata)
          
          local current_label = data[i].current_label
          if current_label == "None" then
            current_label = nil
          end
          
          if aux_hea == "" then
            aux_hea = nil
          end
          
          local lclabel = "LC_"..wave_label
          if wave_rao.draft_label then
            lclabel = wave_rao.draft_label.."_"..lclabel
          end
          table.insert(loadings.lcases, {
            label = lclabel,
            floating_label = floating_data.label,
            rao_label = wave_rao.rao.label,
            wave_label = wave_label,
            curr_label = current_label,
            offset_value = data[i].offset_value,
            offset_azim = (wdata.dir1 + 180.0) % 360.0,
            offset_type = data[i].offset_type,
            offset_href = data[i].offset_href,
            addx_offset = data[i].addx_offset,
            addy_offset = data[i].addy_offset,
            addz_offset = wave_rao.addz_offset,
            ship_wave_angle = data[i].ship_wave_angle-- + 180.0
          })
          
        end
      end
      
    end
    
    -- Insere dados das correntes que nao estao no modelo
    if current_data then
      local currents_map = {}
      for dir_key, dir_data in pairs(current_data) do
        for lvl_key, lvl_data in pairs(dir_data) do
          for ip, profile in ipairs(lvl_data) do
            currents_map[profile.lbl] = {dir = dir_key, lvl = lvl_key, pos = ip}
          end
        end
      end
      for idir = 1, #lc_directions do
        local current_label = lc_directions[idir].current
        local map = currents_map[current_label]
        if map then
          table.insert(loadings.currents, current_data[map.dir][map.lvl][map.pos])
          currents_map[current_label] = nil
        end
      end
    end
    
  end
  
  return loadings
  
end

function nwaves_to_occurrence(data)
  local total_nwaves = 0
  for i = 1, #data do
    total_nwaves = total_nwaves + data[i].wave_occ
  end
  for i = 1, #data do
    data[i].wave_occ = data[i].wave_occ / total_nwaves
  end
  return data
end

function get_azim_from_dir(wave_dir_label)
  local wave_azim = {
    N   =   0.0,
    NNE =  22.5,
    NE  =  45.0,
    ENE =  67.5,
    E   =  90.0,
    ESE = 112.5,
    SE  = 135.0,
    SSE = 157.5,
    S   = 180.0,
    SSW = 202.5,
    SW  = 225.0,
    WSW = 247.5,
    W   = 270.0,
    WNW = 292.5,
    NW  = 315.0,
    NNW = 337.5,
  }
  return wave_azim[wave_dir_label]
end

function match_zeros(value,maxvalue)
  local max_digits = string.len(tostring(maxvalue))
  local digits     = string.len(tostring(value))
  for i = 1, max_digits - digits do value = "0"..value end
  return value
end
