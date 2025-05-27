function return_inc_angle_for_position(pos_label)
  local inc_angle = {
    ["Near"]  = {180.0},
    ["Far"]   = {0.0},
    ["Cross"] = {22.5, 45.0, 67.5, 112.5, 135.0, 157.5, 202.5, 225.0, 247.5, 292.5, 315.0, 337.5},
    ["Transverse"] = {90.0, 270.0},
  }
  return inc_angle[pos_label]
end

function return_inc_angle_for_direction(wave_x_current)
  local inc_angle = {
    ["Colinear"] = {0.0},
    ["Crossed"]  = {-22.5, 22.5},
  }
  return inc_angle[wave_x_current]
end

function get_dir_from_azim(wave_azim, ndir)
  wave_azim = tonumber(wave_azim)
  if wave_azim == nil then return nil end
  
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

function ang_diff(a, b)
  local min = math.min(a, b)
  local max = math.max(a, b)
  return math.min(max-min, 360.0+min-max)
end

function api_assemble_loading_cases(method,
                                    position,
                                    wave_x_current,
                                    wave_rp,
                                    curr_rp,
                                    wave_ndir,
                                    curr_ndir,
                                    added_waves,
                                    added_currs,
                                    riser_azim,
                                    fpu_heading,
                                    is_turret)

  local wave_rp = tostring(wave_rp)
  local curr_rp = tostring(curr_rp)
  
  local possible_azims = {}
  
  if method == "Compass Directions" then
  
    local wave_inc = 22.5
    if wave_ndir == "8" then
      wave_inc = 45.0
    end
    local inc_direction = return_inc_angle_for_direction(wave_x_current)
    for azim = 0.0, 337.5, wave_inc do
      for iid = 1, #inc_direction do
        local new_azims = {
          wave   = (azim + inc_direction[iid]        ) % 360.0,
          curr   = (azim - inc_direction[iid] + 180.0) % 360.0,
          offset = (azim                      + 180.0) % 360.0
        }
        if is_turret then
          new_azims.ship_wave_angle = -inc_direction[iid]
        end
        table.insert(possible_azims, new_azims)
      end
    end
  
  elseif method == "Riser Azimuth" then
  
    local inc_iip = 1
    local ini_iip = 1
    if position == "Crossed" and wave_ndir == "8" then
      inc_iip = 3
      ini_iip = 2
    end
    local inc_position = return_inc_angle_for_position(position)
    
    if wave_x_current == "Beam Seas" then
    
      if is_turret then
        local inc_heading = {-90.0, 90.0}
        for iip = ini_iip, #inc_position, inc_iip do
          for iih = 1, #inc_heading do
            local new_azims = {
              wave   = (riser_azim + inc_position[iip] - inc_heading[iih]) % 360.0,
              curr   = (riser_azim + inc_position[iip] + 180.0) % 360.0,
              offset = (riser_azim + inc_position[iip] + 180.0) % 360.0,
              ship_wave_angle = inc_heading[iih]
            }
            table.insert(possible_azims, new_azims)
          end
        end
      
      else -- Spread Mooring Beam Seas
        local wave_azim1 = (fpu_heading + 90.0) % 360.0
        local wave_azim2 = (fpu_heading - 90.0) % 360.0
        for iip = ini_iip, #inc_position, inc_iip do
          local offset_azim = (riser_azim + inc_position[iip] + 180.0) % 360.0
          local diff1 = ang_diff(offset_azim, (wave_azim1 + 180.0) % 360.0)
          local diff2 = ang_diff(offset_azim, (wave_azim2 + 180.0) % 360.0)
          local wave_azims = {}
          if diff1 <= 90.0 then
            table.insert(wave_azims, wave_azim1)
          end
          if diff2 <= 90.0 then
            table.insert(wave_azims, wave_azim2)
          end
          for iwa = 1, #wave_azims do
            local new_azims = {
              wave   = wave_azims[iwa],
              curr   = offset_azim,
              offset = offset_azim
            }
            table.insert(possible_azims, new_azims)
          end
        end
      end
    
    else -- Colinear e Crossed
      local inc_direction = return_inc_angle_for_direction(wave_x_current)
      for iip = ini_iip, #inc_position, inc_iip do
        for iid = 1, #inc_direction do
          local new_azims = {
            wave   = (riser_azim + inc_position[iip] + inc_direction[iid]        ) % 360.0,
            curr   = (riser_azim + inc_position[iip] - inc_direction[iid] + 180.0) % 360.0,
            offset = (riser_azim + inc_position[iip]                      + 180.0) % 360.0
          }
          if is_turret then
            new_azims.ship_wave_angle = -inc_direction[iid]
          end
          table.insert(possible_azims, new_azims)
        end
      end
    end
  end
  
  local comb_cases = {}
  for i = 1, #possible_azims do
    
    local wave_dir = get_dir_from_azim(possible_azims[i].wave, wave_ndir)
    local curr_dir = get_dir_from_azim(possible_azims[i].curr, wave_ndir)
    
    local waves = {}
    local currs = {}
    
    if wave_dir and added_waves[wave_rp] and added_waves[wave_rp][wave_dir] then
      waves = added_waves[wave_rp][wave_dir]
    elseif wave_rp == 'None' or wave_rp == 'nil' then
      waves[1] = "None"
      wave_dir = nil
      possible_azims[i].wave = nil
    end

    if curr_rp == 'None' or curr_rp == 'nil' then
      currs[1] = "None"
      curr_dir = nil
      possible_azims[i].curr = nil
    elseif curr_dir then
      for level, level_currs in pairs(added_currs) do
        if level_currs[curr_rp] and level_currs[curr_rp][curr_dir] then
          for ic, curr in ipairs(level_currs[curr_rp][curr_dir]) do
            table.insert(currs, curr)
          end
        end
      end
    end

    for iw = 1, #waves do
      for ic = 1, #currs do
        local new_lc = {}
        new_lc.wave = waves[iw].label
        new_lc.wave_hs = waves[iw].hs
        new_lc.wave_dir = wave_dir
        new_lc.wave_azim = possible_azims[i].wave
        new_lc.curr = currs[ic].label
        new_lc.curr_dir = curr_dir
        new_lc.curr_azim = possible_azims[i].curr
        new_lc.offset_azim = possible_azims[i].offset
        new_lc.ship_wave_angle = possible_azims[i].ship_wave_angle
        if new_lc.wave_azim or new_lc.curr_azim then
          comb_cases[#comb_cases+1] = new_lc
        end
      end
    end
  end
  
  return comb_cases
  
end

function match_zeros(value, maxvalue)
  local max_digits = string.len(tostring(maxvalue))
  local digits     = string.len(tostring(value))
  for i = 1, max_digits - digits do value = "0"..value end
  return value
end

function api_return_lc_table(method,
                             combs,
                             floating_data,
                             rao_data,
                             added_waves,
                             added_currs,
                             riser_azim,
                             wave_ndir,
                             curr_ndir)
  
  wave_ndir = wave_ndir or "16"
  curr_ndir = curr_ndir or "16"
  
  local lc_table = {
    floating_label = floating_data.label,
    --rao_label = rao_label,
    waves = {},
    currs = {},
    anacases = {},
  }
  
  for dir, dir_waves in pairs(added_waves) do
    for rp, rp_dir_waves in pairs(dir_waves) do
      for i, params in pairs(rp_dir_waves) do
        table.insert(lc_table.waves, {
          label = params.label,
          hs = params.hs,
          tp = params.tp,
          azim = params.azim
        })
      end
    end
  end
  
  for level, level_currs in pairs(added_currs) do
    for rp, rp_currs in pairs(level_currs) do
      for dir, rp_dir_currs in pairs(rp_currs) do
        for i, params in pairs(rp_dir_currs) do
          table.insert(lc_table.currs, {
            label = params.label,
            points = params.points
          })
        end
      end
    end
  end
  
  local function get_rao_from_hs(hs)
    hs = hs or 0.1
    local labels = {}
    for idraft, draft_data in ipairs(rao_data) do
      local irao = 0
      local nraos = #draft_data.rao_selection
      local hsmax
      repeat
        irao = irao + 1
        hsmax = tonumber(draft_data.rao_selection[irao].hsmax) or math.huge
      until hs <= hsmax or irao == nraos
      table.insert(labels, {
        rao = draft_data.rao_selection[irao].label,
        draft_label = draft_data.label,
        addz_offset = draft_data.draft
      })
    end
    return labels
  end
  
  for iac = 1, #combs do
    local comb = combs[iac]
    local comb_cases = api_assemble_loading_cases(method,
                                                  comb.position,
                                                  comb.wave_x_current,
                                                  tostring(comb.wave_rp),
                                                  tostring(comb.curr_rp),
                                                  wave_ndir,
                                                  curr_ndir,
                                                  added_waves,
                                                  added_currs,
                                                  riser_azim,
                                                  floating_data.heading,
                                                  floating_data.is_turret)
    
    local lcases = {}
    local nlc = #comb_cases
    if nlc > 0 then
    
      local fpu_tilt = tonumber(comb.fpu_tilt)
      
      if fpu_tilt > 0.0 then
        local ac_suffix = {"_A", "_B"}
        local tilt_signal = {1, -1}
        for itilt = 1, 2 do
          for ilc = 1, nlc do
            local rao_labels = get_rao_from_hs(comb_cases[ilc].wave_hs)
            for irao = 1, #rao_labels do
              local lclabel = comb.label..ac_suffix[itilt].."_LC_"..match_zeros(ilc, nlc)
              if rao_labels[irao].draft_label then
                lclabel = rao_labels[irao].draft_label.."_"..lclabel
              end
              table.insert(lcases, {
                label = lclabel,
                rao_label = rao_labels[irao].rao,
                wave_label = comb_cases[ilc].wave,
                wave_azim = comb_cases[ilc].wave_azim,
                curr_label = comb_cases[ilc].curr,
                curr_azim = comb_cases[ilc].curr_azim,
                offset_value = tonumber(comb.offset_value),
                offset_type = comb.offset_type,
                offset_azim = comb_cases[ilc].offset_azim,
                ship_wave_angle = comb_cases[ilc].ship_wave_angle,
                fpu_tilt = tilt_signal[itilt]*fpu_tilt,
                addz_offset = rao_labels[irao].addz_offset
              })
            end
          end
        end
      
      else -- fpu_tilt == 0.0
        for ilc = 1, nlc do
          local rao_labels = get_rao_from_hs(comb_cases[ilc].wave_hs)
          for irao = 1, #rao_labels do
            local lclabel = comb.label.."_LC_"..match_zeros(ilc, nlc)
            if rao_labels[irao].draft_label then
              lclabel = rao_labels[irao].draft_label.."_"..lclabel
            end
            table.insert(lcases, {
              label = lclabel,
              rao_label = rao_labels[irao].rao,
              wave_label = comb_cases[ilc].wave,
              wave_azim = comb_cases[ilc].wave_azim,
              curr_label = comb_cases[ilc].curr,
              curr_azim = comb_cases[ilc].curr_azim,
              offset_value = tonumber(comb.offset_value),
              offset_type = comb.offset_type,
              offset_azim = comb_cases[ilc].offset_azim,
              ship_wave_angle = comb_cases[ilc].ship_wave_angle,
              addz_offset = rao_labels[irao].addz_offset
            })
          end
        end
      end
      
      table.insert(lc_table.anacases, {
        label = comb.label,
        lcases = lcases
      })
      
    end
    
  end
  
  return lc_table
  
end
