----------------------------------------------------------------------------
----------------------------------------------------------------------------
------------------------------   FADIGA   ----------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------

function api_read_wave_scatter(wave_data)

  wave_data = wave_data.reference_level[1]
  
  local ini_period = wave_data.sector[1].column_class[1].lower_value
  local inc_period = wave_data.sector[1].column_class[1].upper_value - ini_period
  local ini_height = wave_data.sector[1].line_class[1].lower_range
  local inc_height = wave_data.sector[1].line_class[1].upper_range - ini_height
  
  local zero_nlin = ini_height / inc_height
  local zero_ncol = ini_period / inc_period
  
  local init_sctable = {inc_period = inc_period, inc_height = inc_height}
  for isec, sector in ipairs(wave_data.sector) do
    local new_block = {}
    for ilin, line in ipairs(sector.scatter[1].lines) do
      new_block[zero_nlin+ilin] = {}
      for icol = 1, zero_ncol do
        new_block[zero_nlin+ilin][icol] = 0
      end
      for icol, column in ipairs(line.columns) do
        new_block[zero_nlin+ilin][zero_ncol+icol] = column.value
      end
    end
    local ncol = #new_block[zero_nlin+1]
    for ilin = 1, zero_nlin do
      new_block[ilin] = {}
      for icol = 1, ncol do
        new_block[ilin][icol] = 0
      end
    end
    init_sctable[sector.direction] = {["SM"] = new_block, ["0"] = new_block}
  end
  
  return init_sctable
  
end

function api_read_fatigue_profiles(curr_data, keep_metadata)

  local init_curr_data = {metadata = {}}
  for ilev, level_data in pairs(curr_data.reference_level) do
  
    local typ_label = tostring(level_data.depth)
    
    local freq_sum = 0
    for isec, sector in ipairs(level_data.sectors) do
      for ip, profile in ipairs(sector.class_range) do
        freq_sum = freq_sum + profile.frequency
      end
    end
    init_curr_data.freq_sum = freq_sum -- precisa ser deletado pela funcao merge
    
    local function match_zeros(value, maxvalue)
      local max_digits = string.len(tostring(maxvalue))
      local digits     = string.len(tostring(value))
      for i = 1, max_digits - digits do value = "0"..value end
      return value
    end
    
    for isec, sector in ipairs(level_data.sectors) do
    
      local dir_label = sector.direction
      local new_block_data = {}
      
      local ndirprofiles = #sector.class_range
      for ip, profile in ipairs(sector.class_range) do
        new_block_data[ip] = {}
        new_block_data[ip].occ = profile.frequency / freq_sum
        new_block_data[ip].pct = profile.percentile
        new_block_data[ip].lbl = "C_"..dir_label.."_"..typ_label.."m_"..match_zeros(ip, ndirprofiles)
        new_block_data[ip].points = {}
        for ipt, point in ipairs(profile.level) do
          new_block_data[ip].points[ipt] = {
            dpt = point.depth,
            vel = point.speed,
            azi = point.direction
          }
        end
      end
      if init_curr_data[dir_label] == nil then
        init_curr_data[dir_label] = {}
      end
      init_curr_data[dir_label][typ_label] = new_block_data
      table.insert(init_curr_data.metadata, {dir = dir_label, typ = typ_label})
    end
  end
  
  if not keep_metadata then
    init_curr_data.metadata = nil
  end
  
  return init_curr_data
  
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------- CLUSTERIZACAO --------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------

function api_read_wave_cluster(data)
  
  local clusters = data.reference_level[1].clusters
  local to_dlg = {}
  
  for ic, cluster in ipairs(clusters) do
    
    local label = cluster.cluster_label
    
    to_dlg[label] = {
      ocorr = cluster.percentage / 100
    }
    
    local depth_table = nil
    local cspeed_table = nil
    local cdirection_table = nil
    
    for ivar, vardata in ipairs(cluster.values) do
      
      -- dados de onda
      if vardata.variable == "HS1" then
        to_dlg[label].Hs1m = tonumber(vardata.value)
      elseif vardata.variable == "TP" then
        to_dlg[label].Tpe1m = tonumber(vardata.value)
      elseif vardata.variable == "DIR" then
        to_dlg[label].Dir1m = tonumber(vardata.value)
      elseif vardata.variable == "HS2" then
        to_dlg[label].Hs2m = tonumber(vardata.value)
      elseif vardata.variable == "TP2" then
        to_dlg[label].Tpe2m = tonumber(vardata.value)
      elseif vardata.variable == "DIR2" then
        to_dlg[label].Dir2m = tonumber(vardata.value)
      
      -- dados de corrente
      elseif vardata.variable == "DEPTH" then
        depth_table = vardata.value
      elseif vardata.variable == "C_SPEED" then
        cspeed_table = vardata.value
      elseif vardata.variable == "C_DIRECTION" then
        cdirection_table = vardata.value
      end
    end
    
    local npts = #depth_table
    assert(npts == #cspeed_table, "Invalid current data for cluster "..label)
    assert(npts == #cdirection_table, "Invalid current data for cluster "..label)
    
    local current_data = {
      lbl = "C_"..label,
      occ = cluster.percentage / 100,
      points = {},
    }
    for i = 1, npts do
      current_data.points[i] = {
        dpt = tonumber(depth_table[i]),
        vel = tonumber(cspeed_table[i]),
        azi = tonumber(cdirection_table[i]),
      }
    end
    to_dlg[label].current_data = current_data
    
  end
  
  return to_dlg
  
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
------------------------------   EXTREMOS ----------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------

local dir_to_azim = {N = 0, NNE = 22.5, NE = 45.0, ENE = 67.5, E = 90.0, ESE = 112.5, SE = 135.0, SSE = 157.5, S = 180.0, SSW = 202.5, SW = 225.0, WSW = 247.5, W = 270.0, WNW = 292.5, NW = 315.0, NNW = 337.5}

-- Formata um numero inserindo zeros antes do mesmo
function zero_format(value, width)
   local nz = width - 1
   if value > 0 then
     nz = nz - math.floor(math.log(value,10))
   end
   return string.rep("0", nz)..value
end

function api_read_extreme_waves(wave_data)
  
  wave_data = wave_data.reference_level[1]

  local values = {}
  for i, sector in ipairs(wave_data.sector) do
  
    local dir = sector.direction
    values[dir] = {}
    
    for i, tpdata in ipairs(sector.tp) do
    
      local tpval = tonumber(tpdata.value)
      for i, ydata in ipairs(tpdata.return_period) do
      
        local rpval = tostring(ydata.time)
        for i, vardata in ipairs(ydata.variables) do
        
          if vardata.variable == "HS" then
          
            local hsval = tonumber(vardata.value) or 0
            if hsval > 0 then
              if values[dir][rpval] == nil then
                values[dir][rpval] = {}
              end
              table.insert(values[dir][rpval], {
                hs = hsval,
                tp = tpval
              })
            end
            
          end
        end
      end
    end
  end
  
  local waves = {}
  for dir, dir_waves in pairs(values) do
    for rp, rp_waves in pairs(dir_waves) do
      local width = tostring(#rp_waves):len()
      for i, params in ipairs(rp_waves) do
        local wave_data = {
          label = "O_"..rp.."y_"..dir.."_"..zero_format(i, width),
          hs = params.hs,
          tp = params.tp,
          azim = dir_to_azim[dir],
          occ = 1,
        }
        if waves[rp] == nil then
          waves[rp] = {}
        end
        if waves[rp][dir] == nil then
          waves[rp][dir] = {}
        end
        table.insert(waves[rp][dir], wave_data)
      end
    end
  end
  
  return waves
  
end

function api_read_extreme_profiles(curr_data)
  
  local values = {}
  for i, level_data in ipairs(curr_data.reference_level) do
    
    -- Detecta se json e' de rampa (depth) ou extremos 'comuns' (level)
    if level_data.depth then
    
      local level = tostring(level_data.depth)
      values[level] = {}
      
      for i, sector in ipairs(level_data.sector) do
      
        local dir = sector.direction
        values[level][dir] = {}
        
        for iramp, rampdata in ipairs(sector.ramp) do
        
          local ramplabel = rampdata.name
          
          values[level][dir][ramplabel] = {}
          for iprofile = 1, #rampdata.levels[1].profiles do
            local iprofile_label = tostring(rampdata.levels[1].profiles[iprofile].profile)
            values[level][dir][ramplabel][iprofile_label] = {}
          end
          
          for idepth, depthdata in ipairs(rampdata.levels) do
            local depth = math.abs(tonumber(depthdata.depth))
            for iprofile, profiledata in ipairs(depthdata.profiles) do
              local iprofile_label = tostring(profiledata.profile)
              --print(level, dir, ramplabel, iprofile, iprofile_label)
              local new_point = {depth = depth}
              for i, vardata in ipairs(profiledata.data) do
                if vardata.variable == "C_SPEED" then
                  new_point.vel = tonumber(vardata.value)
                elseif vardata.variable == "C_DIRECTION" then
                  new_point.dir = tostring(vardata.value)
                end
              end
              table.insert(values[level][dir][ramplabel][iprofile_label], new_point)
            end
          end
          
          for ramplabel, proflist in pairs(values[level][dir]) do
            for iprofile_label, profile in pairs(proflist) do
              table.sort(profile, function(a,b) return a.depth < b.depth end)
            end
          end
          
        end
      end
      
    elseif level_data.level then
      local level = tostring(level_data.level)
      values[level] = {}
      
      for i, sector in ipairs(level_data.sector) do
      
        local dir = sector.direction
        values[level][dir] = {}
        
        for i, leveldata in ipairs(sector.profile_level) do
        
          local depth = math.abs(tonumber(leveldata.depth))
          for i, ydata in ipairs(leveldata.return_period) do
          
            local new_point = {depth = depth}
            for i, vardata in ipairs(ydata.variables) do
              if vardata.variable == "C_SPEED" then
                new_point.vel = tonumber(vardata.value)
              elseif vardata.variable == "C_DIRECTION" then
                new_point.dir = tostring(vardata.value)
              end
            end
            
            local rpval = tostring(ydata.time)
            if values[level][dir][rpval] == nil then
              values[level][dir][rpval] = {nonramp = {}}
            end
            table.insert(values[level][dir][rpval].nonramp, new_point)
            
          end
          
          for rpval, points in pairs(values[level][dir]) do
            table.sort(points.nonramp, function(a,b) return a.depth < b.depth end)
          end
          
        end
      end
    else
      error("Unrecognized JSON format.")
    end
  end
  
  local currents = {}
  for level, level_profiles in pairs(values) do
    if currents[level] == nil then
      currents[level] = {}
    end
    for dir, dir_profiles in pairs(level_profiles) do
      for rp, aux in pairs(dir_profiles) do
        for iprofile_label, profile in pairs(aux) do
          local label = "C_"..rp.."y_"..level.."m_"..dir
          if not tonumber(rp) then -- perfil de rampa
            label = label.."_"..iprofile_label
          end
          local current_data = {
            label = label,
            occ = 1,
            points = {},
          }
          for i, point in ipairs(profile) do
            current_data.points[i] = {
              depth = tonumber(point.depth),
              vel = point.vel,
              azim = dir_to_azim[point.dir],
            }
          end
          if currents[level][rp] == nil then
            currents[level][rp] = {}
          end
          if currents[level][rp][dir] == nil then
            currents[level][rp][dir] = {}
          end
          table.insert(currents[level][rp][dir], current_data)
        end
      end
    end
  end
  
  return currents
  
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
-------------------------------  MERGES  -----------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------

function api_merge_fatigue_profiles(json_data_list)
  local json_data = {}
  local global_freq_sum = 0
  for i = 1, #json_data_list do
    global_freq_sum = global_freq_sum + json_data_list[i].freq_sum
  end
  for i = 1, #json_data_list do
    local local_freq_sum = json_data_list[i].freq_sum
    json_data_list[i].freq_sum = nil
    for dir_label, dir_profiles in pairs(json_data_list[i]) do
      if json_data[dir_label] == nil then
        json_data[dir_label] = {}
      end
      if dir_label == "metadata" then
        for iblock, block in ipairs(dir_profiles) do -- dir_profiles sao os blocos de metadado
          table.insert(json_data.metadata, block)
        end
      else
        for typ_label, typ_profiles in pairs(dir_profiles) do
          if json_data[dir_label][typ_label] == nil then
            json_data[dir_label][typ_label] = {}
          end
          for i, current_data in ipairs(typ_profiles) do
            current_data.occ = current_data.occ * local_freq_sum / global_freq_sum
            table.insert(json_data[dir_label][typ_label], current_data)
          end
        end
      end
    end
  end
  return json_data
end

function api_merge_extreme_profiles(json_data_list)
  local json_data = json_data_list[1]
  for i = 2, #json_data_list do
    for level, level_profiles in pairs(json_data_list[i]) do
      if json_data[level] == nil then
        json_data[level] = {}
      end
      for rp, rp_profiles in pairs(level_profiles) do
        if json_data[level][rp] == nil then
          json_data[level][rp] = {}
        end
        for dir, dir_profiles in pairs(rp_profiles) do
          if json_data[level][rp][dir] == nil then
            json_data[level][rp][dir] = {}
          end
          for i, current_data in ipairs(dir_profiles) do
            table.insert(json_data[level][rp][dir], current_data)
          end
        end
      end
    end
  end
  return json_data
end
