# How to Assemble Toolbox

!["preview"](https://i.imgur.com/3gd5T7J.png)

## Introduction

A simple ADV game in console with assembly language.

## Motivation

This is the final project of *Assembly Language and System Programming* in NCU CSIE, Taiwan.

## Installation

Assemble [main.asm](main.asm) with [Irvine32 Library](http://kipirvine.com/asm/gettingStartedVS2017/index.htm#tutorial32).

## Story Script Format

### Standard Form

```
[function, arg1, arg2, arg3, arg4]
```

### Text (2 Arguments)

```
[t, NAME, CONTENT]
```

### Option (3 or 4 Arguments)

```
[o, OPTION_CODE, 2, FIRST, SECOND]
[o, OPTION_CODE, 3, FIRST, SECOND, THIRD]
```

### Conditions

```
[c, OPTION_CODE|WHICH_OPTION]
...
[cend]
```

### Figure (1 Argument)

```
[f, 01]
```

### Ending. Back to Main Menu (1 Argument)

```
[e]
```
