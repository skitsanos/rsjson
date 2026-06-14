package = "rsjson"
version = "{{VERSION}}"
source = {
  url = "git://github.com/skitsanos/rsjson.git"
}
description = {
  summary = "A Rust library for JSON encoding and decoding in OpenResty Lua.",
  detailed = [[
    rsjson is a Rust library designed to be called from OpenResty Lua for JSON encoding and decoding.
  ]],
  homepage = "https://github.com/skitsanos/rsjson",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "command",
  platforms = {
    unix = {
      build_command = [[
        cp target/release/librsjson.so .
      ]],
      install = {
        lib = {
          "librsjson.so"
        }
      }
    },
    macosx = {
      build_command = [[
        cp target/release/librsjson.dylib .
      ]],
      install = {
        lib = {
          "librsjson.dylib"
        }
      }
    },
    windows = {
      build_command = [[
        copy target\\release\\rsjson.dll .
      ]],
      install = {
        lib = {
          "rsjson.dll"
        }
      }
    }
  }
}
