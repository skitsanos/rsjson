use std::env;
use std::path::Path;

fn main() {
    let (lua_dir, lua_lib) = lua_link_config();

    println!("cargo:rustc-link-search=native={lua_dir}");
    println!("cargo:rustc-link-lib={lua_lib}");

    for lib_dir in [
        "/usr/lib/lua5.4",
        "/usr/lib/lua5.3",
        "/usr/lib/lua5.2",
        "/usr/lib/lua5.1",
    ] {
        if Path::new(lib_dir).exists() {
            println!("cargo:rustc-link-search=native={lib_dir}");
        }
    }

    println!("cargo:rerun-if-env-changed=LUA_DIR");
    println!("cargo:rerun-if-env-changed=LUAJIT_DIR");
}

fn lua_link_config() -> (String, &'static str) {
    if cfg!(feature = "luajit") {
        let default_dir = if cfg!(target_os = "windows") {
            "C:\\ProgramData\\chocolatey\\lib\\luajit\\tools"
        } else if Path::new("/usr/include/luajit-2.1").exists() {
            "/usr"
        } else if Path::new("/opt/homebrew/opt/luajit/lib").exists() {
            "/opt/homebrew/opt/luajit/lib"
        } else {
            "/usr/local"
        };

        let lua_dir = env::var("LUAJIT_DIR").unwrap_or_else(|_| default_dir.to_string());
        return (lua_dir, "luajit-5.1");
    }

    let (feature_version, windows_lib) = if cfg!(feature = "lua51") {
        ("5.1", "lua51")
    } else if cfg!(feature = "lua52") {
        ("5.2", "lua52")
    } else if cfg!(feature = "lua53") {
        ("5.3", "lua53")
    } else {
        ("5.4", "lua54")
    };

    let homebrew_versioned_dir = format!("/opt/homebrew/opt/lua@{feature_version}/lib");

    let default_dir = if cfg!(target_os = "windows") {
        "C:\\ProgramData\\chocolatey\\lib\\lua\\tools"
    } else if Path::new(&format!("/usr/include/lua{feature_version}")).exists() {
        "/usr"
    } else if Path::new(&homebrew_versioned_dir).exists() {
        &homebrew_versioned_dir
    } else {
        "/usr/local"
    };

    let lua_dir = env::var("LUA_DIR").unwrap_or_else(|_| default_dir.to_string());

    if cfg!(target_os = "windows") {
        return (lua_dir, windows_lib);
    }

    let versioned_lua_lib = match feature_version {
        "5.1" => "lua5.1",
        "5.2" => "lua5.2",
        "5.3" => "lua5.3",
        _ => "lua5.4",
    };

    let lua_lib = if lua_dir.contains("/opt/homebrew")
        || lua_dir.contains("/usr/local/opt")
        || lua_dir.contains("/.lua/")
        || lua_dir.contains(&format!("/usr/lib/lua{feature_version}"))
        || (lua_dir == "/usr" && Path::new(&format!("/usr/lib/lua{feature_version}")).exists())
    {
        "lua"
    } else {
        versioned_lua_lib
    };

    (lua_dir, lua_lib)
}
