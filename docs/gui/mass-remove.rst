gui/mass-remove
===============

.. dfhack-tool::
    :summary: Mass select buildings and constructions to suspend or remove.
    :tags: untested fort productivity buildings stockpiles

This tool lets you remove buildings/constructions or suspend/unsuspend
construction jobs using a mouse-driven box selection.

The following marking modes are available.

:Suspend: Suspend the construction of a planned building/construction.
:Unsuspend: Resume the construction of a suspended planned
    building/construction.
:Remove Construction: Designate a construction (wall, floor, etc.) for removal.
    This is similar to the native Designate->Remove Construction menu in DF.
:Unremove Construction: Cancel removal of a construction (wall, floor, etc.).
:Remove Building: Designate a building (door, workshop, etc) for removal.
    This is similar to the native Set Building Tasks/Prefs->Remove Building menu
    in DF.
:Unremove Building: Cancel removal of a building (door, workshop, etc.).
:Remove All: Designate both constructions and buildings for removal, and deletes
    planned buildings/constructions.
:Unremove All: Cancel removal designations for both constructions and buildings.

Usage
-----

::

    gui/mass-remove
