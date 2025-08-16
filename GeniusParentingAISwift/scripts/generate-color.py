#!/usr/bin/env python3
# GeniusParentingAISwift/scripts/generate-color.py
import os
import json
import sys

# 1) Your schemes with Light + Dark hex values
schemes = {
      "OceanBreeze": {
        "Light": {
          "Foreground": "#1C1C1E",
          "Background": "#F2F2F7",
          "Accent": "#5AC8FA",
          "Border": "#34C759",
          "Primary": "#007AFF",
          "Secondary": "#34C759",
          "Text": "#1C1C1E",
          "CardBackground": "#FFFFFF"
        },
        "Dark": {
          "Foreground": "#F2F2F7",
          "Background": "#1C1C1E",
          "Accent": "#64D2FF",
          "Border": "#30D158",
          "Primary": "#0A84FF",
          "Secondary": "#30D158",
          "Text": "#F2F2F7",
          "CardBackground": "#2C2C2E"
        }
      },
      "SunsetCoral": {
        "Light": {
          "Foreground": "#333333",
          "Background": "#F0F0F0",
          "Accent": "#FF9F43",
          "Border": "#FFD93D",
          "Primary": "#FF6B6B",
          "Secondary": "#FFD93D",
          "Text": "#333333",
          "CardBackground": "#FFFFFF"
        },
        "Dark": {
          "Foreground": "#FFFFFF",
          "Background": "#000000",
          "Accent": "#FF9F0A",
          "Border": "#FFD60A",
          "Primary": "#FF453A",
          "Secondary": "#FFD60A",
          "Text": "#FFFFFF",
          "CardBackground": "#1C1C1E"
        }
      },
    "ForestNight": {
        "Light": {
            "Foreground": "#0A1F1B",
            "Background": "#F5F5F5",
            "Accent":     "#82D9A9",
            "Border":     "#55C57A",
            "Primary":    "#1F4822",
            "Secondary":  "#55C57A",
            "Text":       "#0A1F1B",
            "CardBackground": "#FFFFFF",
        },
        "Dark": {
            "Foreground": "#E0E0E0",
            "Background": "#121212",
            "Accent":     "#55C57A",
            "Border":     "1F4822",
            "Primary":    "#0A1F1B",
            "Secondary":  "#1F4822",
            "Text":       "#E0E0E0",
            "CardBackground": "#1E1E1E",
        }
    },
    "SoftPastel": {
        "Light": {
            "Foreground":  "#2D3436",
            "Background": "#F9F9F9",
            "Accent":     "#55EFC4",
            "Border":     "#74B9FF",
            "Primary":    "#A29BFE",
            "Secondary":  "#74B9FF",
            "Text":       "#2D3436",
            "CardBackground": "#FFFFFF",
        },
        "Dark": {
            "Foreground": "#6C5CE7",
            "Background": "#2D3436",
            "Accent":     "#00B894",
            "Border":     "#0984E3",
            "Primary":    "#6C5CE7",
            "Secondary":  "#0984E3",
            "Text":       "#FFFFFF",
            "CardBackground": "#424242",
        }
    },
    "SoftBlue": {
        "Light": {
            "Foreground":   "#4A4A4A",
            "Background":   "#3977BF",
            "Accent":       "#40E0D0",
            "Border":       "#FFFFFF",
            "InputBoxBackground": "#FFFFFF",
        },
        "Dark": {
            "Foreground":   "#F0F0F0",
            "Background":   "#131920",
            "Accent":       "#A4E5D9",
            "Border":       "#F0F0F0",
            "InputBoxBackground": "#FFFFFF",
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
