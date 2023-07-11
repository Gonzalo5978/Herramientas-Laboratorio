#!/bin/bash

#Colores
verde="\e[0;32m\033[1m"
finColor="\033[0m\e[0m"
rojo="\e[0;31m\033[1m"
azul="\e[0;34m\033[1m"
amarillo="\e[0;33m\033[1m"
morado="\e[0;35m\033[1m"
turquesa="\e[0;36m\033[1m"
blanco="\e[1;37m\033[1m"


#Funcion Ctrl+C
function ctrl_c(){
	echo -e "\n[!] Deteniendo Script... \n"
	exit 1
}

#Ctrl+C
trap ctrl_c INT

#Variables Introducidas

echo -e "\n [!] ${turquesa}Rango Instalacion (192.xxx.xxx):${finColor} \n"
read rango

echo -e "\n [!] ${turquesa}IP Primera Camara (Ultimos digitos xx):${finColor} \n"
read camaraInicio

echo -e "\n [!] ${turquesa}IP Ultima camara (Ultimos digitos xx):${finColor} \n"
read camaraFinal

echo -e "\n [!] ${turquesa}Password instalacion:${finColor} \n"
read password

archivo="$(touch $rango)"

#Script
for camaras in $(seq $camaraInicio $camaraFinal); do
	info="$(curl http://$rango.$camaras/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | head -n 12 | tail -n 10 | sed 's/<deviceName>/Nombre:/' | sed 's/<model>/Modelo:/' | sed 's/<macAddress>/MAC:/' | sed 's/<firmwareVersion>/Firmware:/' | sed 's/<firmwareReleasedDate>build/Build:/' | awk -F "<" '{print $1}' | xargs -n 1)"
	hora="$(curl http://$rango.$camaras/ISAPI/System/time --digest -u "admin:$password" -s | tail -n 3 | head -n 1 | awk '{print $0}' | awk '{print substr ($0, 12)}' | awk -F "<" '{print $1}')"
	barrido="$(ping -c 1 -W 1 $rango.$camaras > /dev/null && echo -e "\n${rojo}[+]${finColor} ${turquesa}Camara $camaras${finColor} - ${verde}ONLINE${finColor}" || echo -e "\n[+] Camara $camaras - ${rojo}OFFLINE${finColor} \n")"
	echo -e "\n$barrido\n"
	echo -e "\n${blanco}[Info]${finColor}\n$info"
	echo -e "\n${blanco}[Hora]${finColor}\n$hora"
done
