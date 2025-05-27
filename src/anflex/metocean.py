import os
import json
from lupa import LuaRuntime

def read_wave_scatter(wave_data):
    """
    Reformata diagrama de dispersão a partir de um JSON da aplicação Metocean.
    
    Exemplo de uso:
    
    >>> from anflex import metocean
    >>> 
    >>> with open('ondas.json') as f:
    >>>     wave_data = json.loads(f.read())
    >>> 
    >>> wave_data = wave_data['data']
    >>> 
    >>> wave_data = metocean.read_extreme_waves(wave_data)

    :param list wave_data: Dados de um JSON da aplicação Metocean contendo um diagrama de dispersão.

    :return: Lista com diagrama de dispersão reformatado.
    :rtype: list
    """

    lua = LuaRuntime(unpack_returned_tuples=True)
    
    src_dir = os.path.dirname(__file__)
    json_lua_path = os.path.join(src_dir, "json.lua").replace('\\','\\\\')
    api_lua_path = os.path.join(src_dir, "import_loading_api.lua").replace('\\','\\\\')
    
    lua.execute('json = dofile("{0}")'.format(json_lua_path))
    lua.execute('dofile("{0}")'.format(api_lua_path))
    
    wave_data_string = json.dumps(wave_data)
    
    lua_func = lua.eval('function(pystr) lua_str = pystr end')
    lua_func(wave_data_string)
    
    lua.execute('lua_table = json.decode(lua_str)')
    lua.execute('lua_result = api_read_wave_scatter(lua_table)')
    lua.execute('lua_out = json.encode(lua_result)')
    
    return json.loads(lua.globals().lua_out)

def read_extreme_waves(wave_data):
    """
    Reformata ondas extremas a partir de um JSON da aplicação Metocean.
    
    Exemplo de uso:
    
    >>> from anflex import metocean
    >>> 
    >>> with open('ondas.json') as f:
    >>>     wave_data = json.loads(f.read())
    >>> 
    >>> wave_data = wave_data['data']
    >>> 
    >>> wave_data = metocean.read_extreme_waves(wave_data)

    :param list wave_data: Dados de um JSON da aplicação Metocean contendo os contornos ambientais com ondas extremas.

    :return: Lista com dados das ondas extremas.
    :rtype: list
    """

    lua = LuaRuntime(unpack_returned_tuples=True)
    
    src_dir = os.path.dirname(__file__)
    json_lua_path = os.path.join(src_dir, "json.lua").replace('\\','\\\\')
    api_lua_path = os.path.join(src_dir, "import_loading_api.lua").replace('\\','\\\\')
    
    lua.execute('json = dofile("{0}")'.format(json_lua_path))
    lua.execute('dofile("{0}")'.format(api_lua_path))
    
    wave_data_string = json.dumps(wave_data)
    
    lua_func = lua.eval('function(pystr) lua_str = pystr end')
    lua_func(wave_data_string)
    
    lua.execute('lua_table = json.decode(lua_str)')
    lua.execute('lua_result = api_read_extreme_waves(lua_table)')
    lua.execute('lua_out = json.encode(lua_result)')
    
    return json.loads(lua.globals().lua_out)

def read_fatigue_profiles(current_data):
    """
    Reformata perfis de corrente a partir de um JSON da aplicação Metocean.
    
    Exemplo de uso:
    
    >>> from anflex import metocean
    >>> 
    >>> with open('corrente.json') as f:
    >>>     current_data = json.loads(f.read())
    >>> 
    >>> current_data = current_data['data']
    >>> 
    >>> current_data = metocean.read_fatigue_profiles(current_data)

    :param list current_data: Dados de um JSON da aplicação Metocean com perfis de corrente de fadiga.

    :return: Perfis de corrente reformatados.
    :rtype: list
    """

    lua = LuaRuntime(unpack_returned_tuples=True)
    
    src_dir = os.path.dirname(__file__)
    json_lua_path = os.path.join(src_dir, "json.lua").replace('\\','\\\\')
    api_lua_path = os.path.join(src_dir, "import_loading_api.lua").replace('\\','\\\\')
    
    lua.execute('json = dofile("{0}")'.format(json_lua_path))
    lua.execute('dofile("{0}")'.format(api_lua_path))
    
    current_data_string = json.dumps(current_data)
    
    lua_func = lua.eval('function(pystr) lua_str = pystr end')
    lua_func(current_data_string)
    
    lua.execute('lua_table = json.decode(lua_str)')
    lua.execute('lua_result = api_read_fatigue_profiles(lua_table)')
    lua.execute('lua_out = json.encode(lua_result)')
    
    return json.loads(lua.globals().lua_out)

def read_extreme_profiles(current_data):
    """
    Reformata perfis de corrente a partir de um JSON da aplicação Metocean.
    
    Exemplo de uso:
    
    >>> from anflex import metocean
    >>> 
    >>> with open('corrente.json') as f:
    >>>     current_data = json.loads(f.read())
    >>> 
    >>> current_data = current_data['data']
    >>> 
    >>> current_data = metocean.read_extreme_profiles(current_data)

    :param list current_data: Dados de um JSON da aplicação Metocean com perfis de corrente extremos.

    :return: Perfis de corrente reformatados.
    :rtype: list
    """

    lua = LuaRuntime(unpack_returned_tuples=True)
    
    src_dir = os.path.dirname(__file__)
    json_lua_path = os.path.join(src_dir, "json.lua").replace('\\','\\\\')
    api_lua_path = os.path.join(src_dir, "import_loading_api.lua").replace('\\','\\\\')
    
    lua.execute('json = dofile("{0}")'.format(json_lua_path))
    lua.execute('dofile("{0}")'.format(api_lua_path))
    
    current_data_string = json.dumps(current_data)
    
    lua_func = lua.eval('function(pystr) lua_str = pystr end')
    lua_func(current_data_string)
    
    lua.execute('lua_table = json.decode(lua_str)')
    lua.execute('lua_result = api_read_extreme_profiles(lua_table)')
    lua.execute('lua_out = json.encode(lua_result)')
    
    return json.loads(lua.globals().lua_out)

def read_clusters(cluster_data):
    """
    Reformata dados de clusters para análise de fadiga a partir de um JSON da aplicação Metocean.
    
    Exemplo de uso:
    
    >>> from anflex import metocean
    >>> 
    >>> with open('clusters.json') as f:
    >>>     cluster_data = json.loads(f.read())
    >>> 
    >>> cluster_data = cluster_data['data']
    >>> 
    >>> cluster_data = metocean.read_clusters(cluster_data)

    :param list cluster_data: Dados de um JSON da aplicação Metocean com clusters para análise de fadiga.

    :return: Clusters reformatados.
    :rtype: list
    """

    lua = LuaRuntime(unpack_returned_tuples=True)
    
    src_dir = os.path.dirname(__file__)
    json_lua_path = os.path.join(src_dir, "json.lua").replace('\\','\\\\')
    api_lua_path = os.path.join(src_dir, "import_loading_api.lua").replace('\\','\\\\')
    
    lua.execute('json = dofile("{0}")'.format(json_lua_path))
    lua.execute('dofile("{0}")'.format(api_lua_path))
    
    cluster_data_string = json.dumps(cluster_data)
    
    lua_func = lua.eval('function(pystr) lua_str = pystr end')
    lua_func(cluster_data_string)
    
    lua.execute('lua_table = json.decode(lua_str)')
    lua.execute('lua_result = api_read_wave_cluster(lua_table)')
    lua.execute('lua_out = json.encode(lua_result)')
    
    return json.loads(lua.globals().lua_out)

__all__ = [
    'read_wave_scatter',
    'read_extreme_waves',
    'read_fatigue_profiles',
    'read_extreme_profiles',
    'read_clusters',
]
