import json
from anflex import loading, metocean

with open('_J1_onda_extremos.json') as f:
    wave_data = json.loads(f.read())
with open('_J2_corrente_extremos.json') as f:
    current_data = json.loads(f.read())

wave_data = wave_data['data']
current_data = current_data['data']

wave_data = metocean.read_extreme_waves(wave_data)
current_data = metocean.read_extreme_profiles(current_data)

floating_data = loading.FloatingData('FPSO', heading=190.0)

rao_data = loading.RaoData()
rao_data.add_rao("RAO1", hsmin=0.0, hsmax=2.5)
rao_data.add_rao("RAO2", hsmin=2.5, hsmax=4.5)
rao_data.add_rao("RAO3", hsmin=4.5, hsmax=99.)

"""
method = "Riser Azimuth"
combs = loading.AnaCaseData()
combs.add("GA-01", wave_rp=100, curr_rp=10, offset_value=9.0, offset_type="% WD", position="Near")
combs.add("GA-20", wave_rp=1, curr_rp=None, offset_value=9.0, offset_type="% WD", position="Far")
riser_azim = 60.0
lcases = loading.extreme_loadings(method, combs, floating_data, rao_data, wave_data, current_data, riser_azim)
"""
method = "Compass Directions"
combs = loading.AnaCaseData()
combs.add("AC1", wave_rp=100, curr_rp=10, offset_value=9.0, offset_type="% WD")
combs.add("AC2", wave_rp=1, curr_rp=None, offset_value=9.0, offset_type="% WD")
lcases = loading.extreme_loadings(method, combs, floating_data, rao_data, wave_data, current_data)

with open('lcases.json', 'w') as f:
    f.write(json.dumps(lcases, indent=2))
