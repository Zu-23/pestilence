# Pestilence

An experimental Linux executable-file infection project associated with the 42 security curriculum. The repository contains C code and assembly experiments for studying ELF64 executable structure and how binary modification changes program behavior.

## Repository overview

| Area | Contents |
| --- | --- |
| [main.c](main.c) | File-selection and mapping logic |
| [src](src) | ELF-related code and supporting routines |
| [stubs](stubs) | Assembly experiments |
| [pestilence.h](pestilence.h), [woody_elf.h](woody_elf.h) | Project data structures and declarations |
| Root C examples | Small exploratory and test sources |

## Scope

This is a work-in-progress source archive, not a packaged application. It includes logic that opens executable files for modification and marks infected files. The code and assembly files reflect ongoing experiments; their presence does not establish a complete or validated implementation.

## Reviewing the project

This README provides a source-level overview only. It intentionally does not provide build, infection, or execution procedures. Review the source as text to understand the project structure and the distinction between executable metadata, mapped file contents, and program control flow.

The implementation is Linux/ELF64-oriented and includes NASM assembly. No binaries were built or run while preparing this documentation.

## Concepts explored

Executable formats, ELF headers, memory mapping, C and assembly integration, binary modification, and recognizing file-infection behavior during security analysis.
