lever
=====

.. dfhack-tool::
    :summary: Inspect and pull levers.
    :tags: fort armok inspection productivity buildings

Usage
-----

``lever list``
    Print out a list of your fort's levers, including their name, activation
    state, and what they are linked to (if anything).
``lever pull <id> [<options>]``
    Queue a job so a dwarf will pull the specified lever. This is the same as
    :kbd:`q` querying the building and queueing a :kbd:`P` pull job.

If your levers aren't named, you can find out a lever's ID with the
`bprobe <probe>` command.

Examples
--------

``lever pull 42 --priority``
    Queue a job to pull lever 42 at high priority.
``lever pull 42 --now``
    Skip the job and pull the lever with the hand of Armok!

Options
-------

``--priority``
    Queue a job at high priority.
``--now``
    Magically toggle the lever immediately.
