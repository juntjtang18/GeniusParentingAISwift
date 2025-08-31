#!/usr/bin/env python3
# GeniusParentingAISwift/scripts/generate-color.py
import os
import json
import sys

# 1) Your schemes with Light + Dark hex values
schemes = {
    "SoftBlue": {
        "Light": {
            "Foreground":   "#FFFFFF",
            "Background":   "#3D91FD",
            "Background2":  "#8977FF",            
            "AccentBackground": "#FFFFFF",
            "Accent":       "#333333",
            "AccentSecond": "#FFFFFF",
            "AccentThird": "#FFFFFF",
            "Border":       "#FFFFFF",
            "InputBoxForeground": "#333333",
            "InputBoxBackground": "#FFFFFF",
            "Primary":     "#30D0DB",
            "PrimaryText": "#333333",
        },
        "Dark": {
            "Foreground":   "#F5F5F5",
            "Background":   "#15202B",
            "Background2":  "#15202B",            
            "AccentBackground": "#797E84",
            "Accent":       "#F5F5F5",
            "AccentSecond": "#39424A",
            "AccentThird":  "#FFFFFF",
            "Border":       "#39424A",
            "InputBoxForeground": "#F5F5F5",
            "InputBoxBackground": "#39424A",
            "Primary":     "#30D0DB",
            "PrimaryText": "#F5F5F5",
        },
    },
    "WarmPurple": {
        "Light": {
            "Foreground":   "#4A4A4A",
            "Background":   "#FAF9F6",
            "Background2":  "#8977FF",            
            "AccentBackground": "#FFFFFF",
            "Accent":       "#000000",
            "AccentSecond": "#FFFFFF",
            "AccentThird": "#FFFFFF",
            "Border":       "#E5E5E5",
            "InputBoxForeground": "#333333",
            "InputBoxBackground": "#FFFFFF",
            "Primary":     "#A35FA3",
            "PrimaryText": "#FFFFFF",

        },
        "Dark": {
            "Foreground":   "#F0F0F0",
            "Background":   "#15202B",
            "Background2":  "#8977FF",            
            "AccentBackground": "#797E84",
            "Accent":       "#FFFFFF",
            "AccentSecond": "#000000",
            "AccentThird": "#FFFFFF",
            "Border":       "#797E84",
            "InputBoxForeground": "#39424A",
            "InputBoxBackground": "#797E84",
            "Primary":     "#A4E5D9",
            "PrimaryText": "#000000",
        },
    },
}

def hex_to_components(hex_str):
    h = hex_str.lstrip('#')
    r, g, b = (int(h[i:i+2], 16)/255.0 for i in (0,2,4))
    return {"red":f"{r:.3f}", "green":f"{g:.3f}", "blue":f"{b:.3f}", "alpha":"1.000"}

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def write_json(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=2)

def main():
    # accept `.xcassets` path as arg or default
    assets_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.getcwd(), "Assets.xcassets")
    if not assets_path.endswith(".xcassets"):
        print("❌ Point to a `.xcassets` folder!")
        sys.exit(1)
    ensure_dir(assets_path)

    # 2) Create top-level ColorSchemes group
    top_group = os.path.join(assets_path, "ColorSchemes")
    ensure_dir(top_group)
    write_json(os.path.join(top_group, "Contents.json"), {
        "info": {"version":1,"author":"xcode"},
        "properties": {"provides-namespace": True}
    })

    total = 0
    for scheme, modes in schemes.items():
        # 3) Per-scheme subgroup
        scheme_folder = os.path.join(top_group, scheme)
        ensure_dir(scheme_folder)
        write_json(os.path.join(scheme_folder, "Contents.json"), {
            "info": {"version":1,"author":"xcode"},
            "properties": {"provides-namespace": True}
        })

        light_map = modes["Light"]
        dark_map  = modes["Dark"]

        # 4) Inside that, your dynamic .colorset bundles
        for role, light_hex in light_map.items():
            dark_hex = dark_map.get(role, light_hex)
            cs_name = f"{scheme}{role}.colorset"
            cs_path = os.path.join(scheme_folder, cs_name)
            ensure_dir(cs_path)

            write_json(os.path.join(cs_path, "Contents.json"), {
                "info": {"version":1,"author":"xcode"},
                "colors": [
                    {
                        "idiom": "universal",
                        "color": {
                            "color-space": "srgb",
                            "components": hex_to_components(light_hex)
                        }
                    },
                    {
                        "idiom": "universal",
                        "appearances":[{"appearance":"luminosity","value":"dark"}],
                        "color": {
                            "color-space": "srgb",
                            "components": hex_to_components(dark_hex)
                        }
                    }
                ]
            })
            total += 1

    print(f"✅ Generated {total} colors under ColorSchemes in:\n   {assets_path}")

if __name__=="__main__":
    main()
