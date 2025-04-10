# pwdgen-zig

## Introduction

A simple password generator tool that generates passwords meeting typical requirements, e.g. upper and lower case letters, numbers and special characters.
Can also receive a wordlist file to pick a reference word to generate a password from.

## Interface

```bash

> pwdgen-zig --help

Usage pwdgen [options]

Options:
    -v, --verbose       Output extra information
    -h, --help          Show this help message
    -l, --length        Length of the generated password
    -w, --wordlist      Wordlist file
    -S, --no-special    Do not use special characters
    -N, --no-numbers    Do not use numbers
    -U, --no-uppercase  Do not use uppercase letters
```

## Build

The project was written in Zig 0.15.0. Make sure you have this version installed.

```bash

# To build the executable stored in the `zig-out/bin` folder
> zig build install --release=fast

# To build the executable stored in the custom path <path>/bin:
> zig build install --release=fast -p <path>

# To build the executable stored in the custom path <path>:
> zig build install --release=fast -p <path> --prefix-exe-dir <path>

```