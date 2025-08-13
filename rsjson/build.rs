use std::env;
use std::path::PathBuf;

fn main() {
    let (lua_dir, lua_include_dir, lua_lib) = if cfg!(feature = "luajit") {
        let default_include = if std::path::Path::new("/usr/include/luajit-2.1").exists() {
            "/usr/include/luajit-2.1"
        } else {
            "/usr/local/include/luajit-2.1"
        };
        let luajit_dir = env::var("LUAJIT_DIR").unwrap_or_else(|_| "/usr/local".to_string());
        // On macOS with Homebrew, LuaJIT library is named 'luajit-5.1' 
        // On Ubuntu/Alpine, it might be 'luajit' or 'luajit-5.1'
        let lua_lib = if luajit_dir.contains("/opt/homebrew") || luajit_dir.contains("/usr/local/opt") {
            "luajit-5.1"  // Homebrew naming
        } else {
            "luajit-5.1"  // Standard naming
        };
        (
            luajit_dir,
            env::var("LUAJIT_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    } else if cfg!(feature = "lua54") {
        let default_include = if std::path::Path::new("/usr/include/lua5.4").exists() {
            "/usr/include/lua5.4"
        } else {
            "/usr/local/include/lua5.4"
        };
        let default_lib_dir = if std::path::Path::new("/usr/lib/lua5.4").exists() {
            "/usr/lib/lua5.4"
        } else {
            "/usr/local/lib"
        };
        let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_lib_dir.to_string());
        // On macOS with Homebrew, Lua library is named 'lua' and is in lib/ subdirectory
        // On Ubuntu/Alpine, it might be 'lua5.4' or 'lua'
        let lua_lib = if lua_dir.contains("/opt/homebrew") || lua_dir.contains("/usr/local/opt") {
            "lua"  // Homebrew naming
        } else {
            "lua5.4"  // Standard naming for Lua 5.4
        };
        (
            lua_dir,
            env::var("LUA_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    } else if cfg!(feature = "lua53") {
        let default_include = if std::path::Path::new("/usr/include/lua5.3").exists() {
            "/usr/include/lua5.3"
        } else {
            "/usr/local/include/lua5.3"
        };
        let default_lib_dir = if std::path::Path::new("/usr/lib/lua5.3").exists() {
            "/usr/lib/lua5.3"
        } else {
            "/usr/local/lib"
        };
        let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_lib_dir.to_string());
        let lua_lib = if lua_dir.contains("/opt/homebrew") || lua_dir.contains("/usr/local/opt") {
            "lua"  // Homebrew naming
        } else {
            "lua5.3"  // Standard naming for Lua 5.3
        };
        (
            lua_dir,
            env::var("LUA_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    } else if cfg!(feature = "lua52") {
        let default_include = if std::path::Path::new("/usr/include/lua5.2").exists() {
            "/usr/include/lua5.2"
        } else {
            "/usr/local/include/lua5.2"
        };
        let default_lib_dir = if std::path::Path::new("/usr/lib/lua5.2").exists() {
            "/usr/lib/lua5.2"
        } else {
            "/usr/local/lib"
        };
        let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_lib_dir.to_string());
        let lua_lib = if lua_dir.contains("/opt/homebrew") || lua_dir.contains("/usr/local/opt") {
            "lua"  // Homebrew naming
        } else {
            "lua5.2"  // Standard naming for Lua 5.2
        };
        (
            lua_dir,
            env::var("LUA_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    } else if cfg!(feature = "lua51") {
        let default_include = if std::path::Path::new("/usr/include/lua5.1").exists() {
            "/usr/include/lua5.1"
        } else {
            "/usr/local/include/lua5.1"
        };
        let default_lib_dir = if std::path::Path::new("/usr/lib").exists() {
            "/usr/lib"
        } else {
            "/usr/local/lib"
        };
        let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_lib_dir.to_string());
        let lua_lib = if lua_dir.contains("/opt/homebrew") || lua_dir.contains("/usr/local/opt") {
            "lua"  // Homebrew naming
        } else {
            "lua5.1"  // Standard naming for Lua 5.1
        };
        (
            lua_dir,
            env::var("LUA_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    } else {
        // Default fallback to lua5.4
        let default_include = if std::path::Path::new("/usr/include/lua5.4").exists() {
            "/usr/include/lua5.4"
        } else {
            "/usr/local/include/lua5.4"
        };
        let default_lib_dir = if std::path::Path::new("/usr/lib/lua5.4").exists() {
            "/usr/lib/lua5.4"
        } else {
            "/usr/local/lib"
        };
        let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_lib_dir.to_string());
        let lua_lib = if lua_dir.contains("/opt/homebrew") || lua_dir.contains("/usr/local/opt") {
            "lua"  // Homebrew naming
        } else {
            "lua5.4"  // Standard naming for Lua 5.4
        };
        (
            lua_dir,
            env::var("LUA_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    };

    println!("cargo:rustc-link-search={lua_dir}");
    println!("cargo:rustc-link-lib={lua_lib}");

    println!("cargo:rerun-if-changed=wrapper.c");

    let mut cc_build = cc::Build::new();
    cc_build.file("wrapper.c").include(&lua_include_dir);

    if cfg!(feature = "luajit") {
        cc_build.define("USE_LUAJIT", None);
    }

    cc_build.compile("lua_wrapper");

    let mut bindgen_builder = bindgen::Builder::default()
        .header("wrapper.c")
        .clang_arg(format!("-I{lua_include_dir}"))
        .parse_callbacks(Box::new(bindgen::CargoCallbacks::new()));

    if cfg!(feature = "luajit") {
        bindgen_builder = bindgen_builder.clang_arg("-DUSE_LUAJIT");
    }

    let bindings = bindgen_builder
        .generate()
        .expect("Unable to generate bindings");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");

    println!("cargo:rerun-if-env-changed=LUA_DIR");
    println!("cargo:rerun-if-env-changed=LUA_INCLUDE_DIR");
    println!("cargo:rerun-if-env-changed=LUAJIT_DIR");
    println!("cargo:rerun-if-env-changed=LUAJIT_INCLUDE_DIR");
}
