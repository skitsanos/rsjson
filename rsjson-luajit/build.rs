use std::env;
use std::path::PathBuf;

fn main() {
    let lua_dir = env::var("LUAJIT_DIR").unwrap_or_else(|_| "/usr/local".to_string());
    let lua_include_dir = env::var("LUAJIT_INCLUDE_DIR").unwrap_or_else(|_| "/usr/local/include/luajit-2.1".to_string());

    println!("cargo:rustc-link-search={}/lib", lua_dir);
    println!("cargo:rustc-link-lib=luajit-5.1");

    println!("cargo:rerun-if-changed=wrapper.c");

    cc::Build::new()
        .file("wrapper.c")
        .include(&lua_include_dir)
        .compile("lua_wrapper");

    let bindings = bindgen::Builder::default()
        .header("wrapper.c")
        .clang_arg(format!("-I{}", lua_include_dir))
        .parse_callbacks(Box::new(bindgen::CargoCallbacks))
        .generate()
        .expect("Unable to generate bindings");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");

    println!("cargo:rerun-if-env-changed=LUAJIT_DIR");
    println!("cargo:rerun-if-env-changed=LUAJIT_INCLUDE_DIR");
}