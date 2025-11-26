import subprocess
import time
import os
import shutil

# Folder that contains project.godot
PROJECT_PATH = "/home/dominique/GodotProjects/TankBattle"  # <--- adjust if needed

N_ENVS = 16
BASE_PORT = 5000

# Try locating Godot executable
GODOT_CMD = shutil.which("godot4") or shutil.which("godot")
if GODOT_CMD is None:
    print("❌ ERROR: Could not find 'godot4' or 'godot' in PATH")
    exit(1)

print(f"Using Godot binary: {GODOT_CMD}")
print(f"Project path: {PROJECT_PATH}")
print(f"Launching {N_ENVS} environments (1 visual + {N_ENVS-1} headless)...\n")

for i in range(N_ENVS):
    port = BASE_PORT + i

    env = os.environ.copy()
    env["TANK_PORT"] = str(port)

    if i == 0:
        # 🚀 FIRST ENVIRONMENT IS VISUAL (window opens!)
        print(f"[VISUAL] Env {i} on port {port}")
        subprocess.Popen(
            [GODOT_CMD, "--path", PROJECT_PATH],  # No --headless
            cwd=PROJECT_PATH,
            env=env,
        )
    else:
        # Remaining envs are headless for max training throughput
        print(f"[HEADLESS] Env {i} on port {port}")
        subprocess.Popen(
            [GODOT_CMD, "--headless", "--path", PROJECT_PATH],
            cwd=PROJECT_PATH,
            env=env,
        )

    time.sleep(0.1)

print(f"\n🚀 All environments launched.\n"
      f"• Visual instance  → port {BASE_PORT}\n"
      f"• {N_ENVS-1} headless envs → ports {BASE_PORT+1} - {BASE_PORT+N_ENVS-1}\n")
