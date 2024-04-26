# OmiLibrary
OmiLibrary is a Lua utility library created with [Project Zomboid](https://projectzomboid.com) modding in mind.
The following modules are available:

| Module        | Purpose                                   |
| ------------- | ----------------------------------------- |
| class         | Create lightweight classes                |
| sandbox       | Create sandbox option helpers for modding |
| fmt           | String parsing and handling               |
| interpolate   | String interpolation                      |
| utils         | Common utility functions                  |
| DelimitedList | Manage delimited string lists             |

## Installation
Installation requires `npm`.
To build the bundler, run the `build` script in the [scripts](./scripts/) folder.

## Creating a Bundle
Creating a bundle requires `node`.

By default, only the `class`, `sandbox`, and `utils` modules are included.
To build the entire library, use:

```
scripts/bundle --all -o OmiLibrary.lua
```

To build a bundle including a subset of the modules, use:

```
scripts/bundle --modules utils fmt -o OmiLibrary.lua
```
