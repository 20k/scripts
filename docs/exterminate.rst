exterminate
===========

.. dfhack-tool::
    :summary: Kills things.
    :tags: fort armok units

Kills any unit, or all units of a given race. You can target any unit on a
revealed tile of the map, including ambushers, but caged/chained creatures are
ignored.

Usage
-----

``exterminate``
    List the available targets.
``exterminate this|him|her|it [magma|butcher]``
    Kills the selected unit.
``exterminate <race>[:<caste>] [magma|butcher]``
    Kills all available units of the specified race, or all undead units.
``exterminate undead [magma|butcher]``
    Kills all available undead units, regardless of race.

If ``magma`` is specified, a column of 7/7 magma is generated on top of the
targets until they die. Warning: do not try this on magma-safe creatures! Also,
using this mode on flyers is not recommended unless you like magma rain.

Alternately, if ``butcher`` is specified, ``exterminate`` will mark the units
for butchering but does not kill them. A dwarf will take the creature to a
butcher's shop and do the deed there. This mode is, of course, useful for pets
and not for armed enemies.

Examples
--------

``exterminate this``
    Kill the selected unit.
``exterminate``
    List the targets on your map.
``exterminate BIRD_RAVEN:male``
    Kill the ravens flying around the map (but only the male ones).
``exterminate undead magma``
    Kill all undead on the map by pouring magma on them.

Technical details
-----------------

This tool kills by setting a unit's ``blood_count`` set to 0, which means
immediate death at the next game tick. For creatures where this is not enough,
such as vampires, it also sets animal.vanish_countdown to 2.
