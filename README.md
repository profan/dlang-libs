[![Build Status](https://travis-ci.org/profan/dlang-libs.svg?branch=master)](https://travis-ci.org/profan/dlang-libs)

dlang-libs
===============
Collection of personal modules for dlang separated out into a separate project because several projects depend on them.

collections.d
---------------
Various collection implementations, made mainly for use in personal game development projects.

ecs.d
---------------
Base for entity component system, based on structs where each component is stored in a contiguous array and inter-component dependencies are meant to be handled by giving components pointers to eachother at instantiation time.

memory.d
---------------
...

util.d
---------------
Collection of utility functions, useful in random places, no clear place of belonging.
