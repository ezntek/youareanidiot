#!/usr/bin/env python3

import sys

FILE = "assets/assets.odin"

def convert_file(varname: str, filename: str) -> str:
    contents = ",".join(str(b) for b in open(filename, "rb").read())
    return f"{varname} := []u8{{{contents}}}"

def main():
    with open(FILE, "w") as f:
        f.write("package assets\n")

        curr_varname = ""
        for i, arg in enumerate(sys.argv[1:]):
            if i % 2 == 0:
                curr_varname = arg
            else:
                f.write(f"{convert_file(curr_varname, arg)}\n")

if __name__ == "__main__":
    main()
