use std::env;
use std::path::PathBuf;
use bindgen::CargoCallbacks;

fn main() {
    // Detect LuaJIT installation
    let luajit_dir = "/usr/local/opt/luajit";  // Default Homebrew installation path

    // Set up library search path
    println!("cargo:rustc-link-search={}/lib", luajit_dir);

    // Link against LuaJIT
    println!("cargo:rustc-link-lib=luajit-5.1");

    // Tell cargo to invalidate the built crate whenever the wrapper changes
    println!("cargo:rerun-if-changed=wrapper.c");

    // Compile wrapper.c
    cc::Build::new()
        .file("wrapper.c")
        .include(format!("{}/include/luajit-2.1", luajit_dir))
        .compile("lua_wrapper");

    // Generate bindings
    let bindings = bindgen::Builder::default()
        .header("wrapper.c")
        .clang_arg(format!("-I{}/include/luajit-2.1", luajit_dir))
        .parse_callbacks(Box::new(CargoCallbacks::new()))
        .generate()
        .expect("Unable to generate bindings");

    // Write the bindings to the $OUT_DIR/bindings.rs file.
    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}