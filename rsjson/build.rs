use std::env;
use std::path::PathBuf;

fn main() {
    let (lua_dir, lua_include_dir, lua_lib) = if cfg!(feature = "luajit") {
        let (default_dir, default_include) = if cfg!(target_os = "windows") {
            // Windows defaults (LuaJIT not currently supported on Windows in CI)
            ("C:\\ProgramData\\chocolatey\\lib\\luajit\\tools", "C:\\ProgramData\\chocolatey\\lib\\luajit\\tools\\include")
        } else if std::path::Path::new("/usr/include/luajit-2.1").exists() {
            ("/usr", "/usr/include/luajit-2.1")
        } else {
            ("/usr/local", "/usr/local/include/luajit-2.1")
        };
        
        let luajit_dir = env::var("LUAJIT_DIR").unwrap_or_else(|_| default_dir.to_string());
        
        // Library naming varies by platform and package manager
        let lua_lib = if cfg!(target_os = "windows") {
            "luajit"  // Windows naming
        } else if luajit_dir.contains("/opt/homebrew") || luajit_dir.contains("/usr/local/opt") {
            "luajit-5.1"  // Homebrew naming
        } else if luajit_dir.contains("/.lua/") {
            "luajit-5.1"  // leafo/gh-actions-lua naming
        } else {
            "luajit-5.1"  // Standard Unix naming
        };
        
        (
            luajit_dir,
            env::var("LUAJIT_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    } else if cfg!(feature = "lua54") {
        let (default_dir, default_include) = if cfg!(target_os = "windows") {
            // Windows defaults - chocolatey for runtime, downloaded source for headers
            ("C:\\ProgramData\\chocolatey\\lib\\lua\\tools", "C:\\tools\\lua\\lua-5.4.7\\src")
        } else if std::path::Path::new("/usr/include/lua5.4").exists() {
            ("/usr", "/usr/include/lua5.4")
        } else {
            ("/usr/local", "/usr/local/include/lua5.4")
        };
        
        let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_dir.to_string());
        
        // Library naming varies by platform and package manager
        let lua_lib = if cfg!(target_os = "windows") {
            if lua_dir.contains(".lua\\lib") {
                "lua54"  // leafo/gh-actions-lua creates lua54.lib
            } else {
                "lua"   // Standard Windows naming
            }
        } else if lua_dir.contains("/opt/homebrew") || lua_dir.contains("/usr/local/opt") {
            "lua"  // Homebrew naming
        } else if lua_dir.contains("/usr/lib/lua5.4") {
            "lua"  // Alpine Linux naming in /usr/lib/lua5.4/
        } else if lua_dir.contains("/.lua/") {
            "lua"  // leafo/gh-actions-lua naming
        } else if lua_dir.contains("/usr/lib") && std::path::Path::new("/usr/lib/lua5.4/liblua.a").exists() {
            "lua"  // Alpine Linux system package naming (library in /usr/lib/lua5.4/)
        } else if lua_dir.contains("/usr/lib") {
            "lua5.4"  // Standard system package naming
        } else {
            "lua5.4"  // Standard Unix naming for Lua 5.4
        };
        
        (
            lua_dir,
            env::var("LUA_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    } else if cfg!(feature = "lua53") {
        let (default_dir, default_include) = if cfg!(target_os = "windows") {
            ("C:\\ProgramData\\chocolatey\\lib\\lua\\tools", "C:\\ProgramData\\chocolatey\\lib\\lua\\tools\\include")
        } else if std::path::Path::new("/usr/include/lua5.3").exists() {
            ("/usr", "/usr/include/lua5.3")
        } else {
            ("/usr/local", "/usr/local/include/lua5.3")
        };
        let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_dir.to_string());
        let lua_lib = if cfg!(target_os = "windows") {
            "lua"
        } else if lua_dir.contains("/opt/homebrew") || lua_dir.contains("/usr/local/opt") {
            "lua"  // Homebrew naming
        } else if lua_dir.contains("/usr/lib/lua5.3") {
            "lua"  // Alpine Linux naming in /usr/lib/lua5.3/
        } else if lua_dir.contains("/.lua/") {
            "lua"  // leafo/gh-actions-lua naming
        } else if lua_dir.contains("/usr/lib") {
            "lua5.3"  // System package naming
        } else {
            "lua5.3"  // Standard naming for Lua 5.3
        };
        (
            lua_dir,
            env::var("LUA_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    } else if cfg!(feature = "lua52") {
        let (default_dir, default_include) = if cfg!(target_os = "windows") {
            ("C:\\ProgramData\\chocolatey\\lib\\lua\\tools", "C:\\ProgramData\\chocolatey\\lib\\lua\\tools\\include")
        } else if std::path::Path::new("/usr/include/lua5.2").exists() {
            ("/usr", "/usr/include/lua5.2")
        } else {
            ("/usr/local", "/usr/local/include/lua5.2")
        };
        let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_dir.to_string());
        let lua_lib = if cfg!(target_os = "windows") {
            "lua"
        } else if lua_dir.contains("/opt/homebrew") || lua_dir.contains("/usr/local/opt") {
            "lua"  // Homebrew naming
        } else if lua_dir.contains("/usr/lib/lua5.2") {
            "lua"  // Alpine Linux naming in /usr/lib/lua5.2/
        } else if lua_dir.contains("/.lua/") {
            "lua"  // leafo/gh-actions-lua naming
        } else if lua_dir.contains("/usr/lib") {
            "lua5.2"  // System package naming
        } else {
            "lua5.2"  // Standard naming for Lua 5.2
        };
        (
            lua_dir,
            env::var("LUA_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    } else if cfg!(feature = "lua51") {
        let (default_dir, default_include) = if cfg!(target_os = "windows") {
            ("C:\\ProgramData\\chocolatey\\lib\\lua\\tools", "C:\\ProgramData\\chocolatey\\lib\\lua\\tools\\include")
        } else if std::path::Path::new("/usr/include/lua5.1").exists() {
            ("/usr", "/usr/include/lua5.1")
        } else {
            ("/usr/local", "/usr/local/include/lua5.1")
        };
        let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_dir.to_string());
        let lua_lib = if cfg!(target_os = "windows") {
            "lua"
        } else if lua_dir.contains("/opt/homebrew") || lua_dir.contains("/usr/local/opt") {
            "lua"  // Homebrew naming
        } else if lua_dir.contains("/usr/lib/lua5.1") {
            "lua"  // Alpine Linux naming in /usr/lib/lua5.1/
        } else if lua_dir.contains("/.lua/") {
            "lua"  // leafo/gh-actions-lua naming
        } else if lua_dir.contains("/usr/lib") {
            "lua5.1"  // System package naming
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
        let (default_dir, default_include) = if cfg!(target_os = "windows") {
            ("C:\\ProgramData\\chocolatey\\lib\\lua\\tools", "C:\\ProgramData\\chocolatey\\lib\\lua\\tools\\include")
        } else if std::path::Path::new("/usr/include/lua5.4").exists() {
            ("/usr", "/usr/include/lua5.4")
        } else {
            ("/usr/local", "/usr/local/include/lua5.4")
        };
        let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_dir.to_string());
        let lua_lib = if cfg!(target_os = "windows") {
            "lua"
        } else if lua_dir.contains("/opt/homebrew") || lua_dir.contains("/usr/local/opt") {
            "lua"  // Homebrew naming
        } else if lua_dir.contains("/usr/lib/lua5.4") {
            "lua"  // Alpine Linux naming in /usr/lib/lua5.4/
        } else if lua_dir.contains("/.lua/") {
            "lua"  // leafo/gh-actions-lua naming
        } else {
            "lua5.4"  // Standard naming for Lua 5.4
        };
        (
            lua_dir,
            env::var("LUA_INCLUDE_DIR").unwrap_or_else(|_| default_include.to_string()),
            lua_lib,
        )
    };

    // Add library search paths
    println!("cargo:rustc-link-search={lua_dir}");
    
    // Alpine Linux stores libraries in versioned subdirectories
    if std::path::Path::new("/usr/lib/lua5.4/liblua.a").exists() {
        println!("cargo:rustc-link-search=/usr/lib/lua5.4");
    } else if std::path::Path::new("/usr/lib/lua5.3/liblua.a").exists() {
        println!("cargo:rustc-link-search=/usr/lib/lua5.3");
    } else if std::path::Path::new("/usr/lib/lua5.2/liblua.a").exists() {
        println!("cargo:rustc-link-search=/usr/lib/lua5.2");
    } else if std::path::Path::new("/usr/lib/lua5.1/liblua.a").exists() {
        println!("cargo:rustc-link-search=/usr/lib/lua5.1");
    }
    
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
