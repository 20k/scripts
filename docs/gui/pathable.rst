gui/pathable
============

.. dfhack-tool::
    :summary: Highlights reachable tiles.
    :tags: fort inspection map

This tool highlights each visible map tile to indicate whether it is possible to
path to that tile from the tile at the cursor. You can move the cursor around
and the highlight will change dynamically. The highlight is green if pathing is
possible and red if not, similar to the highlight DF uses to indicate which
tiles can reach the trade depot.

While the UI is active, you can use the following hotkeys to change the
behavior:

- :kbd:`l`: Lock cursor: when enabled, the movement keys move the map instead of
    moving the cursor. This is useful to check whether parts of the map far away
    from the cursor can be pathed to from the cursor.
- :kbd:`d`: Draw: allows temporarily disabling the highlighting entirely. This
    allows you to see the map in its regular shading, if desired.
- :kbd:`u`: Skip unrevealed: when enabled, unrevealed tiles will not be
    highlighted at all. (These would otherwise be highlighted in red.)

.. note::
    This tool uses a cache used by DF, which currently does *not* account for
    climbing. If an area of the map is only accessible by climbing, this tool
    may report it as inaccessible. Care should be taken when digging into the
    upper levels of caverns, for example.

Usage
-----

::

  gui/pathable
