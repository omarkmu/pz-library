# OmiLib

OmiLib is a Lua utility library created with [Project Zomboid](https://projectzomboid.com) modding in mind.
As of now, all of its modules are usable from a regular Lua environment, with the exception of `sandbox`.
The following modules are available:

| Module      | Purpose                                    |
| ----------- | ------------------------------------------ |
| class       | Create lightweight classes                 |
| sandbox     | Create sandbox option helpers for modding  |
| fmt         | String parsing and handling                |
| interpolate | String interpolation                       |
| utils       | Common utility functions                   |
| test        | Lua testing                                |

This library is meant to be be bundled into a single file using [luabun](https://github.com/omarkmu/luabun).

By default, only the `class`, `sandbox`, and `utils` modules are included.
To build the entire library, use:

```
node luabun OmiLib --all -o OmiLib.lua
```

To build with specific modules, use:

```
node luabun OmiLib --modules test fmt -o OmiLib.lua
```
