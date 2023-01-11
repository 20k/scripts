stripcaged
==========

.. dfhack-tool::
    :summary: Remove items from caged prisoners.
    :tags: untested fort productivity items

This tool helps with the tedious task of going through all your cages and
marking the items inside for dumping. This lets you get leftover seeds out of
cages after you tamed the animals inside. The most popular use of this tool,
though, is to strip the weapons and armor from caged prisoners. After you run
this tool, your dwarves will come and take the items to the garbage dump,
leaving your cages clean and your prisoners stripped bare.

If you don't want to wait for your dwarves to dump all the items, you can use
`autodump` to speed the process along.

Usage
-----

``stripcaged list``
    Display a list of all cages and their item contents.
``stripcaged items|weapons|armor|all [here|<cage id> ...]``
    Dump the given type of item. If ``here`` is specified, only act on the
    in-game selected cage (or the cage under the game cursor). Alternately, you
    can specify the item ids of specific cages that you want to target.

Examples
--------

``stripcaged all``
    For all cages, dump all items, equipped by a creature or not.
``stripcaged items``
    Dump loose items in all cages, such as seeds left over from animal training.
``stripcaged weapons``
    Dump weapons equipped by caged creatures.
``stripcaged armor here``
    Dumps the armor equipped by the caged creature under the cursor.
``stripcaged all 25321 34228``
    Dumps all items out of the specified cages.
