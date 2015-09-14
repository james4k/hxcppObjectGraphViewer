# hxcppObjectGraphViewer

An experimental object graph viewer for hxcpp.

Will need this object-graph branch:
https://github.com/james4k/hxcpp/commits/object-graph

To use, build your app with `-DHXCPP_GC_DUMP_OBJECT_GRAPH`,
which will cause the program to dump an `object_graph.csv` file
in the working directory after every GC. Select this file in
the file selection dialog when you run hxcppObjectGraphViewer.

The user interface is extremely crude right now. Here is how to use it:

* Click on a row in the overview table to see a list of each object in that
  group.
* Click on an object address to browse via its references and see the object's roots.
* Use the up and down arrow keys to adjust the `incl_walk_depth` value for
  computing `incl_size`.
* `incl_walk_depth` is inclusive walk depth. `incl_size` is inclusive size, or
  the size of the object and any of the objects it refers to, recursively, up
  to a depth of `incl_walk_depth`. `excl_size` is exclusive size, or the size of
  the object alone. `n_inst` is number of instances.
* There is no scrolling yet, sorry. Will be done when scrollRect is usable.
