import os
import json
from lupa import LuaRuntime

class FloatingData:
    """
    Constrói objeto com dados da unidade flutuante utilizada como referência para a geração dos casos de carregamento.
    
    :param string label: Rótulo da unidade flutuante no modelo.
    :param float heading: Azimute de aproamento do flutuante (em graus).
    :param bool is_turret: Flag para indicação de unidade tipo Turret.
    """
    def tolist(self):
        return {
            'label': self.label,
            'heading': self.heading,
            'is_turret': self.is_turret,
        }
    def __init__(self, label, heading=None, is_turret=False):
        if type(label) != str:
            raise TypeError("Argumento label deve ser do tipo string.")
        elif heading != None and type(heading) != float:
            raise TypeError("Argumento heading deve ser do tipo float ou None.")
        elif type(is_turret) != bool:
            raise TypeError("Argumento hsmax deve ser do tipo bool.")
        self.label = label
        self.heading = heading
        self.is_turret = is_turret

class RaoData:
    """
    Constrói objeto com parâmetros para utilização dos RAOs na geração dos casos de carregamento.
    """
    drafts = {}
    def_raos = []
    def tolist(self):
        return [v for k,v in self.drafts.items()] + ([{'rao_selection': self.def_raos}] if self.def_raos else [])
    def add_draft(self, label, draft_dz):
        """
        Adiciona um novo calado ao objeto.
        
        :param string label: Rótulo do novo calado utilizado nos casos de carregamento.
        :param float draft_dz: Diferença de calado em relação ao valor default no modelo, aplicada ao flutuante como offset estático na direção vertical.
        """
        if type(label) != str:
            raise TypeError("Argumento label deve ser do tipo string.")
        elif type(draft_dz) != float:
            raise TypeError("Argumento draft_dz deve ser do tipo float.")
        self.drafts[label] = {
            'label': label,
            'draft': draft_dz,
            'rao_selection': []
        }
    def add_rao(self, label, draft_label=None, hsmin=0.0, hsmax=99.0):
        """
        Adiciona um RAO ao objeto.
        
        :param string label: Rótulo do RAO no modelo.
        :param string draft_label: Rótulo do calado ao qual o RAO deve ser adicionado (opcional).
        :param float hsmin: Limite inferior de altura de onda para o RAO adicionado.
        :param float hsmax: Limite superior de altura de onda para o RAO adicionado.
        """
        if type(label) != str:
            raise TypeError("Argumento label deve ser do tipo string.")
        elif draft_label != None and type(draft_label) != str:
            raise TypeError("Argumento draft_label deve ser do tipo string.")
        elif type(hsmin) != float:
            raise TypeError("Argumento hsmin deve ser do tipo float.")
        elif type(hsmax) != float:
            raise TypeError("Argumento hsmax deve ser do tipo float.")
        if draft_label:
            try:
                self.drafts[draft_label]['rao_selection'].append({
                    'label': label,
                    'hsmin': hsmin,
                    'hsmax': hsmax,
                })
            except KeyError:
                raise KeyError("Calado {} não encontrado. Utilize a função RaoData.add_draft()".format(draft_label))
        else:
            self.def_raos.append({
                'label': label,
                'hsmin': hsmin,
                'hsmax': hsmax,
            })

class DirectionData:
    """
    Constrói objeto com dados para os casos de carregamento de cada direção do diagrama de dispersão.
    """
    all_dirs = []
    class _InvalidDir(Exception):
        def __init__(self):
            super().__init__("Rótulo de direção inválido. Opções: 'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'")
    class _InvalidOffsetType(Exception):
        def __init__(self):
            super().__init__("Argumento offset_type inválido. Opções: 'm', '% WD', 'Ref. Wave'")
    def tolist(self):
        return self.all_dirs
    def add(self, label, current=None, offset_value=0.0, offset_type="m", addx_offset=0.0, addy_offset=0.0):
        """
        Adiciona uma nova direção de onda e seus parâmetros ao objeto.
        
        :param string label: Direção das ondas / diagrama de dispersão. Opções: 'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'.
        :param string current: Rótulo do perfil de correnteza para os casos de carregamento dessa direção. Aceita None para montar casos sem correnteza.
        :param float offset_value: Valor de offset colinear.
        :param string offset_type: Método utilizado para calcular o offset colinear. Opções: 'm', '% WD', 'Ref. Wave'.
        :param float addx_offset: Valor de offset fixo alinhado com a direção X do sistema de referência global.
        :param float addy_offset: Valor de offset fixo alinhado com a direção Y do sistema de referência global.
        """
        if type(label) != str or label not in ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW']:
            raise self._InvalidDir
        elif current != None and type(current) != str:
            raise TypeError("Argumento current deve ser do tipo string ou None.")
        elif type(offset_value) != float:
            raise TypeError("Argumento offset_value deve ser do tipo float.")
        elif type(offset_type) != str or offset_type not in ['m', '% WD', 'Ref. Wave']:
            raise self._InvalidOffsetType
        elif type(addx_offset) != float:
            raise TypeError("Argumento addx_offset deve ser do tipo float.")
        elif type(addy_offset) != float:
            raise TypeError("Argumento addy_offset deve ser do tipo float.")
        self.all_dirs.append({
            'name': label,
            'current': current,
            'offset_value': offset_value,
            'offset_type': offset_type,
            'addx_offset': addx_offset,
            'addy_offset': addy_offset,
        })

class AnaCaseData:
    """
    Constrói objeto com casos de análise contendo as definições para os carregamentos gerados.
    """
    combs = []
    class _InvalidPosition(Exception):
        def __init__(self):
            super().__init__("Argumento position inválido. Opções: 'Near', 'Far', 'Cross', 'Transverse'")
    class _InvalidAlignment(Exception):
        def __init__(self):
            super().__init__("Argumento alignment inválido. Opções: 'Colinear', 'Crossed', 'Beam Seas'")
    class _InvalidOffsetType(Exception):
        def __init__(self):
            super().__init__("Argumento offset_type inválido. Opções: 'm', '% WD', 'Ref. Wave'")
    def tolist(self):
        return self.combs
    def add(self, label, wave_rp, curr_rp=None, position="Near", alignment="Colinear", offset_value=0.0, offset_type="m", fpu_tilt=0.0):
        """
        Adiciona ao objeto um novo caso de análise e seus parâmetros.
        
        :param string label: Rótulo do caso de análise.
        :param int wave_rp: Período de retorno das ondas.
        :param int curr_rp: Período de retorno das correntes. Aceita None para montar caso de análise sem correnteza.
        :param string position: Alinhamento do offset com o riser de referência (utilizado apenas no método "Riser Azimuth"). Opções: 'Near', 'Far', 'Cross', 'Transverse'.
        :param string alignment: Alinhamento dos carregamentos com o offset. Opções: 'Colinear', 'Crossed', 'Beam Seas'.
        :param float offset_value: Valor de offset colinear.
        :param string offset_type: Método utilizado para calcular o offset colinear. Opções: 'm', '% WD', 'Ref. Wave'.
        :param float fpu_tilt: Valor de adernamento do flutuante (em graus).
        """
        if type(label) != str:
            raise TypeError("Argumento label deve ser do tipo string.")
        elif type(wave_rp) != int:
            raise TypeError("Argumento wave_rp deve ser do tipo int.")
        elif curr_rp != None and type(curr_rp) != int:
            raise TypeError("Argumento curr_rp deve ser do tipo int ou None.")
        elif type(position) != str or position not in ['Near', 'Far', 'Cross', 'Transverse']:
            raise self._InvalidPosition
        elif type(alignment) != str or alignment not in ['Colinear', 'Crossed', 'Beam Seas']:
            raise self._InvalidAlignment
        elif type(offset_value) != float:
            raise TypeError("Argumento offset_value deve ser do tipo float.")
        elif type(offset_type) != str or offset_type not in ['m', '% WD', 'Ref. Wave']:
            raise self._InvalidOffsetType
        elif type(fpu_tilt) != float:
            raise TypeError("Argumento fpu_tilt deve ser do tipo float.")
        self.combs.append({
            'label': label,
            'wave_rp': wave_rp,
            'curr_rp': curr_rp,
            'position': position,
            'wave_x_current': alignment,
            'offset_value': offset_value,
            'offset_type': offset_type,
            'fpu_tilt': fpu_tilt,
        })


def extreme_loadings(method, combs, floating_data, rao_data, wave_data, current_data, riser_azim=None):
    """
    Função que monta os casos de carregamento para análises de extremos.
    
    Exemplo de uso:
    
    >>> from anflex import loading, metocean
    >>> 
    >>> with open('ondas.json') as f:
    >>>     wave_data = json.loads(f.read())
    >>> with open('corrente.json') as f:
    >>>     current_data = json.loads(f.read())
    >>> 
    >>> wave_data = wave_data['data']
    >>> current_data = current_data['data']
    >>> 
    >>> wave_data = metocean.read_extreme_waves(wave_data)
    >>> current_data = metocean.read_extreme_profiles(current_data)
    >>> 
    >>> method = "Riser Azimuth"
    >>> 
    >>> floating_data = loading.FloatingData('FPSO', heading=190.0)
    >>> 
    >>> rao_data = loading.RaoData()
    >>> rao_data.add_rao("RAO1", hsmin=0.0, hsmax=2.5)
    >>> rao_data.add_rao("RAO2", hsmin=2.5, hsmax=4.5)
    >>> rao_data.add_rao("RAO3", hsmin=4.5, hsmax=99.)
    >>> 
    >>> combs = loading.AnaCaseData()
    >>> combs.add("GA-01", wave_rp=100, curr_rp=10, offset_value=9.0, offset_type="% WD", position="Near", alignment="Colinear")
    >>> # [...]
    >>> combs.add("GA-20", wave_rp=1, curr_rp=1, offset_value=9.0, offset_type="% WD", position="Transverse", alignment="Beam Seas")
    >>> 
    >>> riser_azim = 60.0
    >>> 
    >>> lcdata = loading.extreme_loadings(method, combs, floating_data, rao_data, wave_data, current_data, riser_azim)

    :param string method: Flag do tipo de método: "Compass Directions" ou "Riser Azimuth".
    :param combs: Objeto com definições dos casos de análise (ver exemplo).
    :type combs: :class:`anflex.loading.AnaCaseData`
    :param floating_data: Objeto com definições da unidade flutuante (ver exemplo).
    :type floating_data: :class:`anflex.loading.FloatingData`
    :param rao_data: Objeto com seleção de RAO por altura de onda (ver exemplo).
    :type rao_data: :class:`anflex.loading.RaoData`
    :param list wave_data: Lista reformatada previamente pela função :py:meth:`anflex.metocean.read_extreme_waves` .
    :param list current_data: Lista reformatada previamente pela função :py:meth:`anflex.metocean.read_extreme_profiles` .
    :param string riser_azim: Azimute do riser de referência para método "Riser Azimuth" (opcional).

    :return: Lista com os casos de carregamento montados.
    :rtype: list
    """

    lua = LuaRuntime(unpack_returned_tuples=True)
    
    src_dir = os.path.dirname(__file__)
    json_lua_path = os.path.join(src_dir, "json.lua").replace('\\','\\\\')
    api_lua_path = os.path.join(src_dir, "extreme_loading_cases_api.lua").replace('\\','\\\\')
    
    lua.execute('json = dofile("{0}")'.format(json_lua_path))
    lua.execute('dofile("{0}")'.format(api_lua_path))
    
    lua.execute('lua_str1 = "{0}"'.format(method))
    combs_string = json.dumps(combs.tolist())
    floating_data_string = json.dumps(floating_data.tolist())
    rao_data_string = json.dumps(rao_data.tolist())
    wave_data_string = json.dumps(wave_data)
    current_data_string = json.dumps(current_data)
    lua.execute('lua_str7 = {0}'.format(riser_azim if riser_azim else 'nil'))
    
    lua_func = lua.eval('function(pystr2, pystr3, pystr4, pystr5, pystr6) lua_str2, lua_str3, lua_str4, lua_str5, lua_str6 = pystr2, pystr3, pystr4, pystr5, pystr6 end')
    lua_func(combs_string, floating_data_string, rao_data_string, wave_data_string, current_data_string)
    
    lua.execute('lua_table2 = json.decode(lua_str2)')
    lua.execute('lua_table3 = json.decode(lua_str3)')
    lua.execute('lua_table4 = json.decode(lua_str4)')
    lua.execute('lua_table5 = json.decode(lua_str5)')
    lua.execute('lua_table6 = json.decode(lua_str6)')
    
    #method,
    #combs,
    #floating_data,
    #rao_data,
    #added_waves,
    #added_currs,
    #riser_azim,
    
    lua.execute('lua_result = api_return_lc_table(lua_str1, lua_table2, lua_table3, lua_table4, lua_table5, lua_table6, lua_str7)')
    
    lua.execute('lua_out = json.encode(lua_result)')
    
    return json.loads(lua.globals().lua_out)

def fatigue_scatter(method, directions, floating_data, rao_data, wave_data, current_data):
    """
    Função que monta os casos de carregamento para análises de fadiga com diagramas de dispersão.
    
    Exemplo de uso:
    
    >>> from anflex import loading, metocean
    >>> 
    >>> with open('ondas.json') as f:
    >>>     wave_data = json.loads(f.read())
    >>> with open('corrente.json') as f:
    >>>     current_data = json.loads(f.read())
    >>> 
    >>> wave_data = wave_data['data']
    >>> current_data = current_data['data']
    >>> 
    >>> wave_data = metocean.read_wave_scatter(wave_data)
    >>> current_data = metocean.read_fatigue_profiles(current_data)
    >>> 
    >>> method = "Irregular"
    >>> 
    >>> floating_data = loading.FloatingData('FPSO', is_turret=True)
    >>> 
    >>> rao_data = loading.RaoData()
    >>> rao_data.add_draft("Cheio", -10.0)
    >>> rao_data.add_rao("RAO1_Cheio", draft_label="Cheio", hsmin=0.0, hsmax=2.5)
    >>> rao_data.add_rao("RAO2_Cheio", draft_label="Cheio", hsmin=2.5, hsmax=4.5)
    >>> rao_data.add_rao("RAO3_Cheio", draft_label="Cheio", hsmin=4.5, hsmax=99.)
    >>> rao_data.add_draft("Medio", 0.0)
    >>> rao_data.add_rao("RAO1_Medio", draft_label="Medio", hsmin=0.0, hsmax=2.5)
    >>> rao_data.add_rao("RAO2_Medio", draft_label="Medio", hsmin=2.5, hsmax=4.5)
    >>> rao_data.add_rao("RAO3_Medio", draft_label="Medio", hsmin=4.5, hsmax=99.)
    >>> rao_data.add_draft("Vazio", 10.0)
    >>> rao_data.add_rao("RAO1_Vazio", draft_label="Vazio", hsmin=0.0, hsmax=2.5)
    >>> rao_data.add_rao("RAO2_Vazio", draft_label="Vazio", hsmin=2.5, hsmax=4.5)
    >>> rao_data.add_rao("RAO3_Vazio", draft_label="Vazio", hsmin=4.5, hsmax=99.)
    >>> 
    >>> directions = loading.DirectionData()
    >>> directions.add("N", offset_value=51.7, offset_type="m", current="C_S_0m_05")
    >>> # [...]
    >>> directions.add("S", offset_value=73.5, offset_type="m", current="C_N_0m_4")
    >>> 
    >>> lcases = loading.fatigue_scatter(method, directions, floating_data, rao_data, wave_data, current_data)

    :param string method: Flag do tipo de método (tipo de onda): "Regular" ou "Irregular".
    :param directions: Objeto com perfil de corrente e offsets por direção de onda (ver exemplo).
    :type directions: :class:`anflex.loading.DirectionData`
    :param floating_data: Objeto com definições da unidade flutuante (ver exemplo).
    :type floating_data: :class:`anflex.loading.FloatingData`
    :param rao_data: Objeto com seleção de RAO por altura de onda (ver exemplo).
    :type rao_data: :class:`anflex.loading.RaoData`
    :param list wave_data: Lista reformatada previamente pela função :py:meth:`anflex.metocean.read_waves_scatter` .
    :param list current_data: Lista reformatada previamente pela função :py:meth:`anflex.metocean.read_fatigue_profiles` .

    :return: Lista com os casos de carregamento montados.
    :rtype: list
    """

    lua = LuaRuntime(unpack_returned_tuples=True)
    
    src_dir = os.path.dirname(__file__)
    json_lua_path = os.path.join(src_dir, "json.lua").replace('\\','\\\\')
    api_lua_path = os.path.join(src_dir, "fatigue_scatter_api.lua").replace('\\','\\\\')
    
    lua.execute('json = dofile("{0}")'.format(json_lua_path))
    lua.execute('dofile("{0}")'.format(api_lua_path))
    
    lua.execute('lua_str1 = "{0}"'.format(method))
    directions_string = json.dumps(directions.tolist())
    floating_data_string = json.dumps(floating_data.tolist())
    rao_data_string = json.dumps(rao_data.tolist())
    wave_data_string = json.dumps(wave_data)
    current_data_string = json.dumps(current_data)
    
    lua_func = lua.eval('function(pystr2, pystr3, pystr4, pystr5, pystr6) lua_str2, lua_str3, lua_str4, lua_str5, lua_str6 = pystr2, pystr3, pystr4, pystr5, pystr6 end')
    lua_func(directions_string, floating_data_string, rao_data_string, wave_data_string, current_data_string)
    
    lua.execute('lua_table2 = json.decode(lua_str2)')
    lua.execute('lua_table3 = json.decode(lua_str3)')
    lua.execute('lua_table4 = json.decode(lua_str4)')
    lua.execute('lua_table5 = json.decode(lua_str5)')
    lua.execute('lua_table6 = json.decode(lua_str6)')
    
    #api_get_loadings(method, lc_directions, floating_data, selected_rao, wave_data, current_data)
    
    lua.execute('lua_result = api_get_loadings(lua_str1, lua_table2, lua_table3, lua_table4, lua_table5, lua_table6)')
    
    lua.execute('lua_out = json.encode(lua_result)')
    
    return json.loads(lua.globals().lua_out)

def fatigue_clusters(cluster_data, rao_data):
    """
    Função que monta os casos de carregamento para análises de fadiga pelo método de clusterização.
    
    Exemplo de uso:
    
    >>> from anflex import loading, metocean
    >>> 
    >>> with open('clusters.json') as f:
    >>>     cluster_data = json.loads(f.read())
    >>> 
    >>> cluster_data = cluster_data['data']
    >>> cluster_data = metocean.read_clusters(cluster_data)
    >>> 
    >>> rao_data = loading.RaoData()
    >>> rao_data.add_draft("Cheio", -10.0)
    >>> rao_data.add_rao("RAO1_Cheio", draft_label="Cheio", hsmin=0.0, hsmax=2.5)
    >>> rao_data.add_rao("RAO2_Cheio", draft_label="Cheio", hsmin=2.5, hsmax=4.5)
    >>> rao_data.add_rao("RAO3_Cheio", draft_label="Cheio", hsmin=4.5, hsmax=99.)
    >>> rao_data.add_draft("Medio", 0.0)
    >>> rao_data.add_rao("RAO1_Medio", draft_label="Medio", hsmin=0.0, hsmax=2.5)
    >>> rao_data.add_rao("RAO2_Medio", draft_label="Medio", hsmin=2.5, hsmax=4.5)
    >>> rao_data.add_rao("RAO3_Medio", draft_label="Medio", hsmin=4.5, hsmax=99.)
    >>> rao_data.add_draft("Vazio", 10.0)
    >>> rao_data.add_rao("RAO1_Vazio", draft_label="Vazio", hsmin=0.0, hsmax=2.5)
    >>> rao_data.add_rao("RAO2_Vazio", draft_label="Vazio", hsmin=2.5, hsmax=4.5)
    >>> rao_data.add_rao("RAO3_Vazio", draft_label="Vazio", hsmin=4.5, hsmax=99.)
    >>> 
    >>> lcases = loading.fatigue_clusters(cluster_data)

    :param list cluster_data: Dados de um JSON da aplicação Metocean com clusterizações.read_fatigue_profiles` .

    :return: Lista com os casos de carregamento montados.
    :rtype: list
    """

    lua = LuaRuntime(unpack_returned_tuples=True)
    
    src_dir = os.path.dirname(__file__)
    json_lua_path = os.path.join(src_dir, "json.lua").replace('\\','\\\\')
    api_lua_path = os.path.join(src_dir, "fatigue_cluster_api.lua").replace('\\','\\\\')
    
    lua.execute('json = dofile("{0}")'.format(json_lua_path))
    lua.execute('dofile("{0}")'.format(api_lua_path))
    
    cluster_data_string = json.dumps(cluster_data)
    rao_data_string = json.dumps(rao_data.tolist())
    
    lua_func = lua.eval('function(pystr1, pystr2) lua_str1, lua_str2 = pystr1, pystr2 end')
    lua_func(cluster_data_string, rao_data_string)
    
    lua.execute('lua_table1 = json.decode(lua_str1)')
    lua.execute('lua_table2 = json.decode(lua_str2)')
    
    lua.execute('lua_result = api_cluster_lc_table(lua_table1, lua_table2)')
    
    lua.execute('lua_out = json.encode(lua_result)')
    
    return json.loads(lua.globals().lua_out)

__all__ = [
    'fatigue_clusters',
    'fatigue_scatter',
    'extreme_loadings',
    'FloatingData',
    'RaoData',
    'DirectionData',
    'AnaCaseData',
]
