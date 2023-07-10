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

#Script
for camaras in $(seq $camaraInicio $camaraFinal); do
	hora="$(curl http://$rango.$camaras/ISAPI/System/time --digest -u "admin:$password" -s | tail -n 3 | head -n 1 | awk '{print $0}' | awk '{print substr ($0, 12)}' | awk -F "<" '{print $1}')"
	ping -c 1 $rango.$camaras > /dev/null && echo -e "\n [+] Camara $camaras - ${verde}ONLINE${finColor}" && echo -e ${blanco}"$hora"${finColor} || echo -e "\n [+] Camara $camaras - ${rojo}OFFLINE${finColor} \n"
done
