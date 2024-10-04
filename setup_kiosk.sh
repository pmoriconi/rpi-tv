#!/bin/bash

# 1) Instalar unclutter y matchbox-window-manager
sudo apt-get update
sudo apt-get install -y unclutter matchbox-window-manager

# 2) Generar archivo de configuración kiosk.conf con la URL
KIOSK_CONF_PATH="/home/selec/kiosk.conf"
echo 'URL="http://192.168.100.115:88/billboard/6"' > $KIOSK_CONF_PATH

# 3) Copiar ejecutable
cp kiosk-bin /home/selec/kiosk-bin

# 4) Editar .bashrc del home de usuario selec
BASHRC_PATH="/home/selec/.bashrc"
if ! grep -q "xinit /home/selec/kiosk-bin -- vt\$(fgconsole)" $BASHRC_PATH; then
  echo "xinit /home/selec/kiosk-bin -- vt\$(fgconsole) >/dev/null 2>&1" >> $BASHRC_PATH
fi

# 5) Editar el archivo /boot/firmware/cmdline.txt
CMDLINE_PATH="/boot/firmware/cmdline.txt"
CMDLINE_CHANGES="console=serial0,115200 console=tty3 root=PARTUUID=212ade2c-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles cfg80211.ieee80211_regdom=AR logo.nologo vt.global_cursor_default=0"
if ! grep -q "console=serial0,115200 console=tty3" $CMDLINE_PATH; then
  sudo sed -i "1s|^|$CMDLINE_CHANGES |" $CMDLINE_PATH
fi

# 6) Editar el archivo /boot/firmware/config.txt
CONFIG_PATH="/boot/firmware/config.txt"
if ! grep -q "display_hdmi_rotate=0" $CONFIG_PATH; then
  echo -e "\n# Rotate display (for portrait displays you must disable DRM VC4 V3D and max_fr>\n# 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°\ndisplay_hdmi_rotate=0" | sudo tee -a $CONFIG_PATH > /dev/null
fi

if ! grep -q "disable_splash=1" $CONFIG_PATH; then
  echo -e "\n[All]\ndisable_splash=1" | sudo tee -a $CONFIG_PATH > /dev/null
fi

cp /home/selec/rpi-tv/splash.png /home/selec/splash.png

# 7) Reemplazar el archivo /usr/share/plymouth/themes/pix/splash.png con /home/selec/splash.png
PLYMOUTH_SPLASH_PATH="/usr/share/plymouth/themes/pix/splash.png"
if [ -f "/home/selec/splash.png" ]; then
  sudo cp /home/selec/splash.png $PLYMOUTH_SPLASH_PATH
  echo "Reemplazado splash.png con el archivo de /home/selec/splash.png"
else
  echo "El archivo /home/selec/splash.png no existe, no se pudo reemplazar splash.png"
fi

# 8) Crear un script para verificar y eliminar la carpeta /home/selec/rpi-tv
INIT_SCRIPT_PATH="/etc/init.d/check_rpi_tv"
sudo bash -c "cat > $INIT_SCRIPT_PATH" << 'EOF'
#!/bin/bash

# Verificar y eliminar la carpeta /home/selec/rpi-tv si existe
if [ -d /home/selec/rpi-tv ]; then
  rm -rf /home/selec/rpi-tv
  echo "La carpeta /home/selec/rpi-tv ha sido eliminada."
else
  echo "La carpeta /home/selec/rpi-tv no existe."
fi
EOF

# 9) Hacer el script ejecutable
sudo chmod +x $INIT_SCRIPT_PATH

# 10) Agregar el script al inicio del sistema
sudo update-rc.d check_rpi_tv defaults

# 11) Actualizar initramfs y reiniciar
sudo truncate -s 0 /etc/issue
sudo truncate -s 0 /etc/issue.net
sudo truncate -s 0 /etc/motd
sudo update-initramfs -u

# 12) Eliminar el historial de bash
cat /dev/null > ~/.bash_history
unset HISTFILE

sudo reboot
