## 📁 File Structure

First, create this structure in your project directory:

```txt
~/my-cli-tools/
├── jarvis                   # Your main script (renamed from jarvis.sh)
├── .jarvis-schema.json      # The configuration file you'll edit
├── generate-completions.py  # The generator script
└── README.md                # Instructions
```

## Step 1: Create the JSON Schema

Save this as `.jarvis-schema.json` in the same directory as your script:

```json
{
  "name": "jarvis",
  "version": "1.13.0",
  "description": "Personal CLI Tool",
  "commands": {
    "lights": {
      "aliases": ["light", "ram", "rams", "led", "leds", "lt", "lts"],
      "description": "Control RAM LED color",
      "subcommands": {
        "on": {
          "aliases": ["1"],
          "description": "Turn RAM LED on",
          "args": []
        },
        "off": {
          "aliases": ["0"],
          "description": "Turn RAM LED off",
          "args": []
        },
        "help": {
          "aliases": [],
          "description": "Show lights help",
          "args": []
        }
      }
    },
    "lock": {
      "aliases": [],
      "description": "Lock screen with optional delay",
      "args": [
        {
          "name": "delay",
          "type": "number",
          "description": "Delay in minutes",
          "optional": true,
          "suggestions": ["1", "2", "3", "4", "5", "10", "15", "30", "45", "60"]
        }
      ]
    },
    "unlock": {
      "aliases": [],
      "description": "Unlock screen",
      "args": []
    },
    "observe": {
      "aliases": ["monitor"],
      "description": "Monitor vault observer log",
      "args": []
    },
    "tree": {
      "aliases": ["list", "lst", "ls"],
      "description": "Show directory tree (git-aware)",
      "args": []
    },
    "power": {
      "aliases": ["poweroff", "pwr", "shutdown"],
      "description": "System shutdown",
      "args": []
    },
    "attendance": {
      "aliases": ["attend", "att"],
      "description": "Generate attendance sheet",
      "flags": {
        "-h": {
          "aliases": ["--help"],
          "description": "Show help"
        }
      }
    },
    "nmhunter": {
      "aliases": ["nmhunt", "nm", "hunt", "hunter"],
      "description": "Hunt and delete node_modules directories",
      "flags": {
        "--dry-run": {
          "aliases": [],
          "description": "Preview only, no deletion"
        },
        "-y": {
          "aliases": ["--yes"],
          "description": "Skip confirmation prompt"
        },
        "-h": {
          "aliases": ["--help"],
          "description": "Show help"
        }
      },
      "args": [
        {
          "name": "directory",
          "type": "path",
          "description": "Directory to scan",
          "optional": true,
          "default": "~/projects"
        }
      ]
    },
    "bkash": {
      "aliases": ["bk"],
      "description": "bKash MFS calculator",
      "subcommands": {
        "cashout": {
          "description": "Calculate cash out",
          "subcommands": {
            "from": {
              "description": "From balance (I have X)",
              "args": [
                {
                  "name": "amount",
                  "type": "number",
                  "description": "Amount in BDT",
                  "optional": false
                },
                {
                  "name": "rate",
                  "type": "number",
                  "description": "Charge rate per 1000 BDT",
                  "optional": true,
                  "default": "18.5",
                  "suggestions": [
                    "14.5",
                    "15.0",
                    "16.0",
                    "17.0",
                    "18.0",
                    "18.5",
                    "19.0",
                    "20.0"
                  ]
                }
              ]
            },
            "for": {
              "description": "For target amount (I want X)",
              "args": [
                {
                  "name": "amount",
                  "type": "number",
                  "description": "Amount in BDT",
                  "optional": false
                },
                {
                  "name": "rate",
                  "type": "number",
                  "description": "Charge rate per 1000 BDT",
                  "optional": true,
                  "default": "18.5",
                  "suggestions": [
                    "14.5",
                    "15.0",
                    "16.0",
                    "17.0",
                    "18.0",
                    "18.5",
                    "19.0",
                    "20.0"
                  ]
                }
              ]
            }
          }
        },
        "sendmoney": {
          "aliases": ["cashin"],
          "description": "Calculate send money",
          "args": [
            {
              "name": "amount",
              "type": "number",
              "description": "Amount in BDT",
              "optional": false
            },
            {
              "name": "rate",
              "type": "number",
              "description": "Charge rate per 1000 BDT",
              "optional": true,
              "default": "18.5",
              "suggestions": [
                "14.5",
                "15.0",
                "16.0",
                "17.0",
                "18.0",
                "18.5",
                "19.0",
                "20.0"
              ]
            }
          ]
        }
      }
    },
    "version": {
      "aliases": [],
      "description": "Show version info",
      "args": []
    },
    "help": {
      "aliases": ["h"],
      "description": "Show help",
      "args": []
    }
  },
  "global_flags": {
    "-h": {
      "aliases": ["--help"],
      "description": "Show help"
    },
    "-v": {
      "aliases": ["--version"],
      "description": "Show version"
    }
  }
}
```
