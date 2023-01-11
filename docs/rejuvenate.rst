rejuvenate
==========

.. dfhack-tool::
    :summary: Sets unit age to 20 years.
    :tags: untested fort armok units

If your most valuable citizens are getting old, this tool can save them. It
decreases the age of the selected dwarf to 20 years.

Usage
-----

::

    rejuvenate [<options>]

Examples
--------

``rejuvenate``
    Set the age of the selected dwarf to 20 (if they're older).
``rejuvenate --all``
    Set the age of all dwarves over 20 to 20.
``rejuvenate --all --force``
    Set the age of all dwarves (including babies) to 20.

Options
-------

``--all``
    Rejuvenate all citizens, not just the selected one.
``--force``
    Set age for units under 20 years old to 20 years.. Useful if there are too
    many babies around...
``--dry-run``
    Only list units that would be changed; don't actually change ages.
