import os
import subprocess
import time
import signal
import requests
import configparser

# Leer configuración desde config.ini
config = configparser.ConfigParser()
config.read('/home/selec/config.ini')  # Asegúrate de colocar la ruta correcta

# Variables de configuración
CHROMIUM_URL = config['settings'].get('chromium_url', 'http://192.168.100.115:88/billboard/6')
REFRESH_INTERVAL = config['settings'].getint('refresh_interval', 300)

def launch_chromium():
    print("Launching Chromium...")
    proc = subprocess.Popen([
        "chromium-browser",
        "--use-gl=angle",
        "--enable-gpu-rasterization",
        "--display=:0",
        "--kiosk",
        "--incognito",
        "--window-position=0,0",
        "--enable-features=OverlayScrollbar",
        "--disable-translate",
        "--disable-extensions",
        CHROMIUM_URL
    ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(5)  # Esperar un poco para que Chromium cargue completamente
    return proc

def refresh_chromium():
    print("Refreshing Chromium...")
    subprocess.call(["xdotool", "search", "--onlyvisible", "--class", "chromium", "windowactivate", "key", "F5"])

def check_screen():
    # Simula la verificación de la pantalla (por implementar según necesidad)
    return False

def check_http_status(url):
    try:
        response = requests.get(url)
        return response.status_code == 200
    except requests.RequestException:
        return False

def main():
    chromium_proc = launch_chromium()
    while True:
        # Verifica si Chromium sigue corriendo
        if chromium_proc.poll() is not None:
            print("Chromium process not found. Restarting...")
            chromium_proc = launch_chromium()

        # Verificar si la pantalla está en blanco (implementación de ejemplo)
        if check_screen():
            chromium_proc.terminate()
            time.sleep(2)
            chromium_proc = launch_chromium()

        # Verificar la respuesta HTTP de la página
        if not check_http_status(CHROMIUM_URL):
            print(f"HTTP check failed. Restarting Chromium...")
            chromium_proc.terminate()
            time.sleep(2)
            chromium_proc = launch_chromium()

        # Refrescar la pantalla cada intervalo configurado
        time.sleep(REFRESH_INTERVAL)
        refresh_chromium()

if __name__ == "__main__":
    main()
