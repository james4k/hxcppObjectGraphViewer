# hxcppObjectGraphViewer

An experimental object graph viewer for hxcpp.

Will need this object-graph branch:
https://github.com/james4k/hxcpp/commits/object-graph

To use, build your app with `-DHXCPP_GC_DUMP_OBJECT_GRAPH`, which will cause the program to dump an object_graph.csv file in the working directory after every GC. Select this file in the file selection dialog when you run hxcppObjectGraphViewer.
