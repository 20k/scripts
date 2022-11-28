gui/overlay
===========

.. dfhack-tool::
    :summary: Manage DFHack overlays and overlay widgets.
    :tags: dfhack interface

This is the configuration interface for the `overlay` framework. You can see
which overlays are available and which ones are enabled, either globally or just
for overlays and widgets associated with the current Dwarf Fortress screen. Each
overlay widget will be framed on the screen to identify which widget is which.
You can click on the frame highlight and drag the widget around the screen to
reposition it, or hit the indicated hotkey and reposition with the cursor keys.

The frame around the currently selected widget will show a highlight to indicate
which screen edge the widget is anchored to. For example, if the bottom and
right edges of the frame are highlighted, the widget will move relative to the
bottom and right screen edge when the DF window is resized.

Usage
-----

::

    gui/overlay
