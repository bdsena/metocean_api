import json
from anflex import loading, metocean

with open('_J1_clusters.json') as f:
    cluster_data = json.loads(f.read())

cluster_data = cluster_data['data']
cluster_data = metocean.read_clusters(cluster_data)

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

lcases = loading.fatigue_clusters(cluster_data, rao_data)

with open('lcases.json', 'w') as f:
    f.write(json.dumps(lcases, indent=2))
