use std::env;
use std::fs;
use std::path::Path;
use std::process::Command;

fn main() {
    // Tell cargo to rerun if these files change
    println!("cargo:rerun-if-changed=assets/");
    println!("cargo:rerun-if-changed=package.json");
    println!("cargo:rerun-if-changed=tailwind.config.js");
    println!("cargo:rerun-if-changed=tsconfig.json");
    println!("cargo:rerun-if-changed=input.css");

    let out_dir = env::var("OUT_DIR").unwrap();
    let assets_dir = Path::new("assets");
    let dist_dir = assets_dir.join("dist");

    // Create assets directories if they don't exist
    if !assets_dir.exists() {
        fs::create_dir_all(&assets_dir).expect("Failed to create assets directory");
    }

    if !dist_dir.exists() {
        fs::create_dir_all(&dist_dir).expect("Failed to create dist directory");
    }

    // Ensure styles directory exists
    let styles_dir = assets_dir.join("styles");
    if !styles_dir.exists() {
        fs::create_dir_all(&styles_dir).expect("Failed to create styles directory");
    }

    // Ensure js directory exists
    let js_dir = assets_dir.join("js");
    if !js_dir.exists() {
        fs::create_dir_all(&js_dir).expect("Failed to create js directory");
    }

    // Create input.css if it doesn't exist
    let input_css = styles_dir.join("input.css");
    if !input_css.exists() {
        let default_css = r#"@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom styles */
@layer components {
  .btn {
    @apply px-4 py-2 rounded-md font-medium transition-colors duration-200;
  }
  
  .btn-primary {
    @apply bg-blue-600 text-white hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2;
  }
  
  .btn-secondary {
    @apply bg-gray-600 text-white hover:bg-gray-700 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2;
  }
  
  .form-input {
    @apply mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500;
  }
  
  .form-label {
    @apply block text-sm font-medium text-gray-700;
  }
  
  .card {
    @apply bg-white shadow-md rounded-lg p-6;
  }
  
  .alert {
    @apply p-4 rounded-md border;
  }
  
  .alert-error {
    @apply bg-red-50 border-red-200 text-red-800;
  }
  
  .alert-success {
    @apply bg-green-50 border-green-200 text-green-800;
  }
  
  .alert-info {
    @apply bg-blue-50 border-blue-200 text-blue-800;
  }
}
"#;
        fs::write(&input_css, default_css).expect("Failed to create input.css");
    }

    // Check if bun is available and install dependencies if needed
    if !Path::new("node_modules").exists() {
        println!("cargo:warning=Installing dependencies with bun...");
        let output = Command::new("bun")
            .arg("install")
            .output()
            .expect("Failed to run bun install");

        if !output.status.success() {
            panic!(
                "bun install failed: {}",
                String::from_utf8_lossy(&output.stderr)
            );
        }
    }

    // Build CSS with TailwindCSS using bun
    println!("cargo:warning=Building CSS with TailwindCSS...");
    let css_output = Command::new("bun")
        .args([
            "x",
            "tailwindcss",
            "-i",
            "assets/styles/input.css",
            "-o",
            "assets/dist/output.css",
            "--minify",
        ])
        .output()
        .expect("Failed to run TailwindCSS");

    if !css_output.status.success() {
        panic!(
            "TailwindCSS build failed: {}",
            String::from_utf8_lossy(&css_output.stderr)
        );
    }

    // Build TypeScript with bun
    println!("cargo:warning=Building TypeScript with bun...");
    let js_output = Command::new("bun")
        .args([
            "build",
            "assets/js/index.ts",
            "--minify",
            "--format=iife",
            "--outfile=assets/dist/index.js",
        ])
        .output()
        .expect("Failed to run bun build");

    if !js_output.status.success() {
        panic!(
            "bun build failed: {}",
            String::from_utf8_lossy(&js_output.stderr)
        );
    }

    // Copy built assets to OUT_DIR so they can be included in the binary
    let target_css = Path::new(&out_dir).join("output.css");
    let target_js = Path::new(&out_dir).join("index.js");

    if Path::new("assets/dist/output.css").exists() {
        fs::copy("assets/dist/output.css", &target_css).expect("Failed to copy CSS to OUT_DIR");
    }

    if Path::new("assets/dist/index.js").exists() {
        fs::copy("assets/dist/index.js", &target_js).expect("Failed to copy JS to OUT_DIR");
    }

    println!("cargo:warning=Assets built successfully!");
}

