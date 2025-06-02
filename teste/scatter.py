import json
from anflex import loading, metocean

with open('_J1_onda_scatter.json') as f:
    wave_data = json.loads(f.read())
with open('_J2_corrente_fadiga_50m.json') as f:
    current_data1 = json.loads(f.read())
with open('_J2_corrente_fadiga_800m.json') as f:
    current_data2 = json.loads(f.read())

wave_data = wave_data['data']
current_data1 = current_data1['data']
current_data2 = current_data2['data']

wave_data = metocean.read_wave_scatter(wave_data)
current_data1 = metocean.read_fatigue_profiles(current_data1)
current_data2 = metocean.read_fatigue_profiles(current_data2)
current_data = metocean.merge_fatigue_profiles([current_data1, current_data2])

method = "Irregular"

floating_data = loading.FloatingData('FPSO', is_turret=True)

rao_data = loading.RaoData()
rao_data.add_draft("Cheio", -10.0)
rao_data.add_rao("RAO1_Cheio", draft_label="Cheio", hsmin=0.0, hsmax=2.5)
rao_data.add_rao("RAO2_Cheio", draft_label="Cheio", hsmin=2.5, hsmax=4.5)
rao_data.add_rao("RAO3_Cheio", draft_label="Cheio", hsmin=4.5, hsmax=99.)
rao_data.add_draft("Medio", 0.0)
rao_data.add_rao("RAO1_Medio", draft_label="Medio", hsmin=0.0, hsmax=2.5)
rao_data.add_rao("RAO2_Medio", draft_label="Medio", hsmin=2.5, hsmax=4.5)
rao_data.add_rao("RAO3_Medio", draft_label="Medio", hsmin=4.5, hsmax=99.)
rao_data.add_draft("Vazio", 10.0)
rao_data.add_rao("RAO1_Vazio", draft_label="Vazio", hsmin=0.0, hsmax=2.5)
rao_data.add_rao("RAO2_Vazio", draft_label="Vazio", hsmin=2.5, hsmax=4.5)
rao_data.add_rao("RAO3_Vazio", draft_label="Vazio", hsmin=4.5, hsmax=99.)

directions = loading.DirectionData()
directions.add("N", offset_value=5.0, offset_type="% WD", current="C_S_50m_4")
# [...]
directions.add("S", offset_value=5.0, offset_type="% WD", current="C_N_50m_4")

lcases = loading.fatigue_scatter(method, directions, floating_data, rao_data, wave_data, current_data)

with open('lcases.json', 'w') as f:
    f.write(json.dumps(lcases, indent=2))
