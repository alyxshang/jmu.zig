# JMU.ZIG

![JMU.ZIG CI](https://github.com/alyxshang/jmu.zig/actions/workflows/zig.yml/badge.svg)

***An implementation in Zig for a parser and deserializer for a data markup language with a syntax inspired by Jirai Kei internet slang.***

## ABOUT

This repository contains the source code for an implementation in Zig 
for a parser and deserializer for a data markup language with a syntax 
inspired by Jirai Kei internet slang. This implementation is a library
and does not use any external dependencies. The data language is called
JMU. This name is an abbreviation for the words ***J***irai Data
***M***ark***U***p language. This language is meant to be an alternative
to formats like YAML, JSON, and TOML.

## SPECIFICATION

The ***J***irai Data ***M***ark***U***p language's specification can be
found [here](https://alyxshang.boo/specs/jmu/).

## INSTALLATION

This Zig library uses Zig version `0.17.0`.
To add this library to your project, use the following command:

```Bash
zig fetch --save git+https://github.com/alyxshang/jmu.zig.git#v.0.1.0
```

The following module must also be declared in your project's `build.zig`:

```Zig
const jmu_dep = b.dependency(
    "jmu", 
    .{
        .target = target,
        .optimize = optimize,
    }
);
your_main_module.root_module.addImport("jmu", jmu_dep.module("jmu"));
```

`your_main_module` is the module you want to add *JMU.ZIG* to.

## USAGE

You would use this library and JMU together in the same way they have
been used in this library's unit tests. The unit tests file can be found
[here](src/tests.zig).

More information on the entities inside this library 
can be obtained by cloning this repository and running the `zig build docs` 
command from the repository's root.

## CHANGELOG

### Version 0.1.0

- Initial release.
- Upload to Forgejo.

## NOTE

- *JMU.ZIG* by *Alyx Shang*.
- Licensed under the [FSL v1](https://alyxshang.boo/content/fair-software-license).
