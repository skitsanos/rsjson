package = "rsjson"
version = "1.0-1"
source = {
  url = "git://github.com/yourusername/rsjson.git",
  tag = "v1.0"
}
description = {
  summary = "A Rust library for JSON encoding and decoding in OpenResty Lua.",
  detailed = [[
    rsjson is a Rust library designed to be called from OpenResty Lua for JSON encoding and decoding.
  ]],
  homepage = "https://github.com/yourusername/rsjson",
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
        cargo build --release &&
        cp target/release/librsjson.so .
      ]],
      install = {
        lua = {
          "src-lua/rsjson.lua"
        },
        lib = {
          "librsjson.so"
        }
      }
    },
    macosx = {
      build_command = [[
        cargo build --release &&
        cp target/release/librsjson.dylib .
      ]],
      install = {
        lua = {
          "src-lua/rsjson.lua"
        },
        lib = {
          "librsjson.dylib"
        }
      }
    },
    windows = {
      build_command = [[
        cargo build --release &&
        copy target\\release\\rsjson.dll .
      ]],
      install = {
        lua = {
          "src-lua/rsjson.lua"
        },
        lib = {
          "rsjson.dll"
        }
      }
    }
  }
}
