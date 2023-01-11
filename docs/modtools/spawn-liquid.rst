modtools/spawn-liquid
=====================

.. dfhack-tool::
    :summary: Spawn water or lava.
    :tags: untested dev

This script spawns liquid at the given coordinates.

Usage
-----

::

    modtools/spawn-liquid <height> water|magma <x> <y> <z> [<xOff> <yOff> <zOff>]

Options
-------

``<height>``
    The height of the water/magma (1 to 7)
``<x>``, ``<y>``, ``<z>``
    The location to spawn liquid at (replacing any preexisting liquid).
``<xOff>``, ``<yOff>``, ``<zOff>``
    Optional convenience offsets, added to ``<x>``, ``<y>``, and ``<z>``.
