Documentação da API Metocean
============================

A API é composta por dois módulos: **metocean** e **loading**.

O módulo **metocean** contém funções de leitura dos JSONs que vêm da aplicação Metocean do SubWeb.

* **Funções**

  * :py:func:`metocean.read_extreme_waves`
  * :py:func:`metocean.read_wave_scatter`
  * :py:func:`metocean.read_extreme_profiles`
  * :py:func:`metocean.read_fatigue_profiles`
  * :py:func:`metocean.merge_extreme_profiles`
  * :py:func:`metocean.merge_fatigue_profiles`
  * :py:func:`metocean.read_clusters`

O módulo **loading** tem o objetivo de montar os casos de carregamento para diferentes tipos de análises extremas e de fadiga.

* **Funções**

  * :py:func:`loading.extreme_loadings`
  * :py:func:`loading.fatigue_scatter`
  * :py:func:`loading.fatigue_clusters`

* **Classes**

  * :py:class:`loading.FloatingData`
  * :py:class:`loading.RaoData`
  * :py:class:`loading.DirectionData`
  * :py:class:`loading.AnaCaseData`

Funções
-------

.. autofunction:: metocean.read_extreme_waves

.. autofunction:: metocean.read_wave_scatter

.. autofunction:: metocean.read_extreme_profiles

.. autofunction:: metocean.read_fatigue_profiles

.. autofunction:: metocean.merge_extreme_profiles

.. autofunction:: metocean.merge_fatigue_profiles

.. autofunction:: metocean.read_clusters
   
Funções
-------

.. autofunction:: loading.extreme_loadings

.. autofunction:: loading.fatigue_scatter

.. autofunction:: loading.fatigue_clusters
   
Classes
-------

.. autoclass:: loading.FloatingData

.. autoclass:: loading.RaoData
   :members:

.. autoclass:: loading.DirectionData
   :members:

.. autoclass:: loading.AnaCaseData
   :members:
