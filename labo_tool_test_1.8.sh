#!/bin/bash

#-------
#Colores
#-------

verde="\e[0;32m\033[1m"
finColor="\033[0m\e[0m"
rojo="\e[0;31m\033[1m"
azul="\e[0;34m\033[1m"
amarillo="\e[0;33m\033[1m"
morado="\e[0;35m\033[1m"
turquesa="\e[0;36m\033[1m"
blanco="\e[0;37m\033[1m"

#--------------
#Funcion Ctrl+C
#--------------

function ctrl_c(){
	echo -e "\n${rojo}[!] Deteniendo Script...${finColor}\n"
	exit 1
}

trap ctrl_c INT

#------------------
#VARIABLES GLOBALES
#------------------

#---------
#FUNCIONES
#---------

function ayuda(){
	toilet Laboratorio -f pagga.tlf --metal

	echo -e "\n${turquesa}[?]${finColor}${blanco}Instrucciones Revisor:${finColor}"
	echo -e "\t${morado}-c${finColor}  Configurador de Cámaras"
	echo -e "\t${morado}-r${finColor}  Modo Revision Errores"
	echo -e "\t${morado}-s${finColor}  Modo Repetir Revision"
	echo -e "\t${morado}-i${finColor}  Modo Revision Individual"
	echo -e "\t${morado}-h${finColor}  Mostrar ayuda del programa"	
}

function revision_errores(){
	toilet Laboratorio -f pagga.tlf --metal

	echo -en "\n${turquesa}[+]${finColor} Introduce el rango de la instalación [192.xxx.xx]: " && read rango
	echo -en "\n${turquesa}[+]${finColor} Introduce el Nº de Host de la 1º camara: " && read camara_1
	echo -en "\n${turquesa}[+]${finColor} Introduce el Nº de Host de la última camara: " && read camara_final
	echo -en "\n${turquesa}[+]${finColor} Introduce la password de la instalacion: " && read password
	echo -e "-------------------------------------------------------------------"

	echo "$rango" > tmp/rango.txt
	echo "$camara_1" > tmp/camara_1.txt
	echo "$camara_final" > tmp/camara_final.txt
	echo "$password" > tmp/password.txt

#-------------------
#TESTEO DE FUNCIONES
#-------------------


#------------------
#DESCARGA DATOS API
#------------------

#Append con nombres de las camaras
declare -a nombres_camaras=()
declare -a remitente_camaras=()
declare -a gateway_camaras=()

	for descarga in $(seq $camara_1 $camara_final); do
		touch tmp/$descarga.txt

		nombres="$(curl http://$rango.$descarga/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | grep "<deviceName>" | sed 's/<deviceName>/[[+] Camara: /' | sed 's/<\/deviceName>/ - ONLINE/')"

		nombres_camaras+=("$nombres")
		
		remitente="$(curl http://$rango.$descarga/ISAPI/System/network/mailing --digest -u "admin:$password" -s | grep "<name>" | sed '2,4d' | sed 's/<name>/Remitente: /' | sed 's/<\/name>//')"

		remitente_camaras+=("$remitente")
	
		gateway="$(curl http://$rango.$descarga/ISAPI/System/Network/interfaces --digest -u "admin:$password" -s | grep "<ipAddress>" | sed '1d' | sed '2,3d' | sed 's/<ipAddress>/Gateway:/' | awk -F "<" '{print $1}')"

		gateway_camaras+=("$gateway")

		info_pet="$(curl http://$rango.$descarga/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | awk "/<deviceName>/,/<firmwareReleasedDate>/" | sed 's/<model>/Modelo:/' | sed 's/<firmwareVersion>/Firmware:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge tmp/$descarga.txt)"

		hora_pet="$(curl http://$rango.$descarga/ISAPI/System/time/ntpServers --digest -u "admin:$password" -s | sed 's/<hostName>/NTP:/' | sed 's/<synchronizeInterval>/Intervalo:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		hora_mode="$(curl http://$rango.$descarga/ISAPI/System/time --digest -u "admin:$password" -s | grep "<timeMode>" | sed 's/<timeMode>/Modo hora:/' | sed 's/<\/timeMode>//' | sponge -a tmp/$descarga.txt)"

		net_pet="$(curl http://$rango.$descarga/ISAPI/System/Network/interfaces --digest -u "admin:$password" -s | grep "<ipAddress>" | sed '1,2d' | sed 's/<ipAddress>/DNS:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		mail_pet="$(curl http://$rango.$descarga/ISAPI/System/network/mailing --digest -u "admin:$password" -s | sed '1,5d' | sed '2,6d' | sed '4,11d' | sed '6,19d' | sed '8,11d' | sed 's/<emailAddress>/Email:/' | sed 's/<hostName>/SMTP:/' | sed 's/<portNo>/Puerto:/' | sed 's/<name>/Soporte:/' | sed 's/<enabled>/Imagen:/' | sed 's/<interval>/Intervalo:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		sd_pet="$(curl http://$rango.$descarga/ISAPI/ContentMgmt/Storage/hdd --digest -u "admin:$password" -s | grep "<status>" | sed 's/<status>/Formateo:/' | sed 's/<\/status>//' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		osd_pet="$(curl http://$rango.$descarga/ISAPI/System/Video/inputs/channels/1/overlays --digest -u "admin:$password" -s | grep "<dateStyle>" -A 2 | sed 's/<dateStyle>/Formato fecha:/' | sed 's/<timeStyle>/Estilo fecha:/' | sed 's/<displayWeek>/Semana:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"
		
		resolucion="$(curl http://$rango.$descarga/ISAPI/Streaming/channels --digest -u "admin:$password" -s | grep -A 9 "videoCodecType" | sed 's/<videoCodecType>/Compresion:/' | sed 's/<videoResolutionWidth>/Anchura:/' | sed 's/<videoResolutionHeight>/Altura:/' | sed 's/<constantBitRate>/BitRate:/' | sed 's/<maxFrameRate>/FPS:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"
	
	
		excep_hdd="$(curl http://$rango.$descarga/ISAPI/Event/triggers/illaccess --digest -u "admin:$password" -s | grep "<notificationMethod>" | sed 2d | sed 's/<notificationMethod>/Login ilegal:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		excep_login="$(curl http://$rango.$descarga/ISAPI/Event/triggers/diskerror --digest -u "admin:$password" -s | grep "<notificationMethod>" | sed 2d | sed 's/<notificationMethod>/HDD Error:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		quota="$(curl http://$rango.$descarga/ISAPI/ContentMgmt/Storage/quota --digest -u "admin:La-916783315" -s | grep "<videoQuotaRatio>" | sed 's/<videoQuotaRatio>/Quota:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		tracks="$(curl http://$rango.$descarga/ISAPI/ContentMgmt/record/tracks --digest -u "admin:$password" -s | sed 's/<DayOfWeek>/Dia:/' | sed 's/<TimeOfDay>/Horas:/' | sed 's/<Record>/Grabacion:/' | sed 's/<ActionRecordingMode>/Modo:/' | sed 's/<PreRecordTimeSeconds>/Adelanto:/' | sed 's/<PostRecordTimeSeconds>/Retardo:/' | sed 's/<Duration>/Duracion:/' | sed 's/<durationEnabled>/Caducidad:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

	done

#----------------
#VARIABLE NOMBRES
#----------------

declare -i numero_camaras=0
declare -i numero_remitente=0
declare -i numero_gateway=0


#		grabador_1_1="$(timeout 1 ping -c 1 $rango.11 > /dev/null && echo "${turquesa}[+]${finColor} ${blanco}NVR1 -${finColor} ${verde}ONLINE${finColor}" || echo "${amarillo}[!]${finColor} ${blanco}NVR1 -${finColor} ${rojo}OFFLINE${finColor}")"
#		echo -e "\n$grabador_1_1\n"
	

		for dispositivos in $(seq $camara_1 $camara_final); do	

			barrido="$(timeout 2 ping -c 1 $rango.$dispositivos >/dev/null && echo -e "${morado}${nombres_camaras[$numero_camaras]}" ${finColor} || echo -e " ${rojo}[!] Camara: $dispositivos - OFFLINE${finColor}")"

			numero_camaras+=1

			echo -e "\n$barrido\n"

			echo -e "${blanco} ${remitente_camaras[$numero_remitente]}${finColor}"
			numero_remitente+=1
			echo -e "${blanco} ${gateway_camaras[$numero_gateway]}${finColor}\n"
			numero_gateway+=1

			diff -y --suppress-common-lines tmp/$dispositivos.txt tmp/comparer.txt

		done

}


#------------------------
#FUNCION REPETIR REVISION
#------------------------

function revision_anterior(){
	toilet Laboratorio -f pagga.tlf --metal

	rango="$(cat tmp/rango.txt)"
	camara_1="$(cat tmp/camara_1.txt)"
	camara_final="$(cat tmp/camara_final.txt)"
	password="$(cat tmp/password.txt)"




#Descarga datos API

#Append con nombres de las camaras
declare -a nombres_camaras=()

#Append con remitente de las camaras
declare -a remitente_camaras=()

#Append con gateway de las camaras
declare -a gateway_camaras=()

	for descarga in $(seq $camara_1 $camara_final); do
		touch tmp/$descarga.txt

		nombres="$(curl http://$rango.$descarga/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | grep "<deviceName>" | sed 's/<deviceName>/[[+] Camara: /' | sed 's/<\/deviceName>/ - ONLINE/')"

		nombres_camaras+=("$nombres")
		
		remitente="$(curl http://$rango.$descarga/ISAPI/System/network/mailing --digest -u "admin:$password" -s | grep "<name>" | sed '2,4d' | sed 's/<name>/Remitente: /' | sed 's/<\/name>//')"

		remitente_camaras+=("$remitente")

		gateway="$(curl http://$rango.$descarga/ISAPI/System/Network/interfaces --digest -u "admin:$password" -s | grep "<ipAddress>" | sed '1d' | sed '2,3d' | sed 's/<ipAddress>/Gateway:/' | awk -F "<" '{print $1}')"
		gateway_camaras+=("$gateway")

		info_pet="$(curl http://$rango.$descarga/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | awk "/<deviceName>/,/<firmwareReleasedDate>/" | sed 's/<model>/Modelo:/' | sed 's/<firmwareVersion>/Firmware:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge tmp/$descarga.txt)"

		hora_pet="$(curl http://$rango.$descarga/ISAPI/System/time/ntpServers --digest -u "admin:$password" -s | sed 's/<hostName>/NTP:/' | sed 's/<synchronizeInterval>/Intervalo:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		hora_mode="$(curl http://$rango.$descarga/ISAPI/System/time --digest -u "admin:$password" -s | grep "<timeMode>" | sed 's/<timeMode>/Modo hora:/' | sed 's/<\/timeMode>//' | sponge -a tmp/$descarga.txt)"

		net_pet="$(curl http://$rango.$descarga/ISAPI/System/Network/interfaces --digest -u "admin:$password" -s | grep "<ipAddress>" | sed '1,2d' | sed 's/<ipAddress>/DNS:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		mail_pet="$(curl http://$rango.$descarga/ISAPI/System/network/mailing --digest -u "admin:$password" -s | sed '1,5d' | sed '2,6d' | sed '4,11d' | sed '6,19d' | sed '8,11d' | sed 's/<emailAddress>/Email:/' | sed 's/<hostName>/SMTP:/' | sed 's/<portNo>/Puerto:/' | sed 's/<name>/Soporte:/' | sed 's/<enabled>/Imagen:/' | sed 's/<interval>/Intervalo:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		sd_pet="$(curl http://$rango.$descarga/ISAPI/ContentMgmt/Storage/hdd --digest -u "admin:$password" -s | grep "<status>" | sed 's/<status>/Formateo:/' | sed 's/<\/status>//' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		osd_pet="$(curl http://$rango.$descarga/ISAPI/System/Video/inputs/channels/1/overlays --digest -u "admin:$password" -s | grep "<dateStyle>" -A 2 | sed 's/<dateStyle>/Formato fecha:/' | sed 's/<timeStyle>/Estilo fecha:/' | sed 's/<displayWeek>/Semana:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		resolucion="$(curl http://$rango.$descarga/ISAPI/Streaming/channels --digest -u "admin:$password" -s | grep -A 9 "videoCodecType" | sed 's/<videoCodecType>/Compresion:/' | sed 's/<videoResolutionWidth>/Anchura:/' | sed 's/<videoResolutionHeight>/Altura:/' | sed 's/<constantBitRate>/BitRate:/' | sed 's/<maxFrameRate>/FPS:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		excep_hdd="$(curl http://$rango.$descarga/ISAPI/Event/triggers/illaccess --digest -u "admin:$password" -s | grep "<notificationMethod>" | sed 2d | sed 's/<notificationMethod>/Login ilegal:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		excep_login="$(curl http://$rango.$descarga/ISAPI/Event/triggers/diskerror --digest -u "admin:$password" -s | grep "<notificationMethod>" | sed 2d | sed 's/<notificationMethod>/HDD Error:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		quota="$(curl http://$rango.$descarga/ISAPI/ContentMgmt/Storage/quota --digest -u "admin:La-916783315" -s | grep "<videoQuotaRatio>" | sed 's/<videoQuotaRatio>/Quota:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		tracks="$(curl http://$rango.$descarga/ISAPI/ContentMgmt/record/tracks --digest -u "admin:$password" -s | sed 's/<DayOfWeek>/Dia:/' | sed 's/<TimeOfDay>/Horas:/' | sed 's/<Record>/Grabacion:/' | sed 's/<ActionRecordingMode>/Modo:/' | sed 's/<PreRecordTimeSeconds>/Adelanto:/' | sed 's/<PostRecordTimeSeconds>/Retardo:/' | sed 's/<Duration>/Duracion:/' | sed 's/<durationEnabled>/Caducidad:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

	done


#Contador incremental para mostrar la posicion de los appends
declare -i numero_camaras=0
declare -i numero_remitente=0
declare -i numero_gateway=0



		for dispositivos in $(seq $camara_1 $camara_final); do	

			barrido="$(timeout 2 ping -c 1 $rango.$dispositivos >/dev/null && echo -e "${morado}${nombres_camaras[$numero_camaras]}" ${finColor} || echo -e " ${rojo}[!] Camara: $dispositivos - OFFLINE${finColor}")"

			numero_camaras+=1

			echo -e "\n$barrido\n"

			echo -e "${blanco} ${remitente_camaras[$numero_remitente]}${finColor}"
			numero_remitente+=1
			echo -e "${blanco} ${gateway_camaras[$numero_gateway]}$finColor\n"
			numero_gateway+=1

			diff -y --suppress-common-lines tmp/$dispositivos.txt tmp/comparer.txt

		done

}



#------------------------
#MODO REVISIÓN INDIVUDUAL
#------------------------

function revision_individual(){
	
	#Banner
	toilet Laboratorio -f pagga.tlf --metal
	
	#Preguntas
	echo -en "\n${turquesa}[+]${finColor} Intoduce la IP del dispositivo: " && read ip
	echo -en "${turquesa}[+]${finColor} Intoduce la password: " && read password
	echo -e "-------------------------------------------------------------------"
	
	#Ping sin output
	timeout 1 ping -c 1 $ip >/dev/null
	
	touch tmp/$ip.txt

	#Si ping Okey entonces llama API y compara si no muestra error
	if [ $? -eq 0 ]; then
		
		nombres="$(curl http://$rango.$descarga/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | grep "<deviceName>" | sed 's/<deviceName>/[[+] Camara: /' | sed 's/<\/deviceName>/ - ONLINE/')"

		nombres_camaras+=("$nombres")
		
		remitente="$(curl http://$rango.$descarga/ISAPI/System/network/mailing --digest -u "admin:$password" -s | grep "<name>" | sed '2,4d' | sed 's/<name>/Remitente: /' | sed 's/<\/name>//')"

		remitente_camaras+=("$remitente")

		gateway="$(curl http://$rango.$descarga/ISAPI/System/Network/interfaces --digest -u "admin:$password" -s | grep "<ipAddress>" | sed '1d' | sed '2,3d' | sed 's/<ipAddress>/Gateway:/' | awk -F "<" '{print $1}')"
		gateway_camaras+=("$gateway")

		info_pet="$(curl http://$rango.$descarga/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | awk "/<deviceName>/,/<firmwareReleasedDate>/" | sed 's/<model>/Modelo:/' | sed 's/<firmwareVersion>/Firmware:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge tmp/$descarga.txt)"

		hora_pet="$(curl http://$rango.$descarga/ISAPI/System/time/ntpServers --digest -u "admin:$password" -s | sed 's/<hostName>/NTP:/' | sed 's/<synchronizeInterval>/Intervalo:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		hora_mode="$(curl http://$rango.$descarga/ISAPI/System/time --digest -u "admin:$password" -s | grep "<timeMode>" | sed 's/<timeMode>/Modo hora:/' | sed 's/<\/timeMode>//' | sponge -a tmp/$descarga.txt)"

		net_pet="$(curl http://$rango.$descarga/ISAPI/System/Network/interfaces --digest -u "admin:$password" -s | grep "<ipAddress>" | sed '1,2d' | sed 's/<ipAddress>/DNS:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		mail_pet="$(curl http://$rango.$descarga/ISAPI/System/network/mailing --digest -u "admin:$password" -s | sed '1,5d' | sed '2,6d' | sed '4,11d' | sed '6,19d' | sed '8,11d' | sed 's/<emailAddress>/Email:/' | sed 's/<hostName>/SMTP:/' | sed 's/<portNo>/Puerto:/' | sed 's/<name>/Soporte:/' | sed 's/<enabled>/Imagen:/' | sed 's/<interval>/Intervalo:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		sd_pet="$(curl http://$rango.$descarga/ISAPI/ContentMgmt/Storage/hdd --digest -u "admin:$password" -s | grep "<status>" | sed 's/<status>/Formateo:/' | sed 's/<\/status>//' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		osd_pet="$(curl http://$rango.$descarga/ISAPI/System/Video/inputs/channels/1/overlays --digest -u "admin:$password" -s | grep "<dateStyle>" -A 2 | sed 's/<dateStyle>/Formato fecha:/' | sed 's/<timeStyle>/Estilo fecha:/' | sed 's/<displayWeek>/Semana:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		resolucion="$(curl http://$rango.$descarga/ISAPI/Streaming/channels --digest -u "admin:$password" -s | grep -A 9 "videoCodecType" | sed 's/<videoCodecType>/Compresion:/' | sed 's/<videoResolutionWidth>/Anchura:/' | sed 's/<videoResolutionHeight>/Altura:/' | sed 's/<constantBitRate>/BitRate:/' | sed 's/<maxFrameRate>/FPS:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"

		excep_hdd="$(curl http://$rango.$descarga/ISAPI/Event/triggers/illaccess --digest -u "admin:$password" -s | grep "<notificationMethod>" | sed 2d | sed 's/<notificationMethod>/Login ilegal:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		excep_login="$(curl http://$rango.$descarga/ISAPI/Event/triggers/diskerror --digest -u "admin:$password" -s | grep "<notificationMethod>" | sed 2d | sed 's/<notificationMethod>/HDD Error:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		quota="$(curl http://$rango.$descarga/ISAPI/ContentMgmt/Storage/quota --digest -u "admin:La-916783315" -s | grep "<videoQuotaRatio>" | sed 's/<videoQuotaRatio>/Quota:/' | awk -F "<" '{print $1}' | sponge -a tmp/$descarga.txt)"

		tracks="$(curl http://$rango.$descarga/ISAPI/ContentMgmt/record/tracks --digest -u "admin:$password" -s | sed 's/<DayOfWeek>/Dia:/' | sed 's/<TimeOfDay>/Horas:/' | sed 's/<Record>/Grabacion:/' | sed 's/<ActionRecordingMode>/Modo:/' | sed 's/<PreRecordTimeSeconds>/Adelanto:/' | sed 's/<PostRecordTimeSeconds>/Retardo:/' | sed 's/<Duration>/Duracion:/' | sed 's/<durationEnabled>/Caducidad:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$descarga.txt)"


		echo -e "\n${morado}$nombre${finColor}\n"
		echo -e "${blanco}$remitente${finColor}"
		echo -e "${blanco}$gateway${finColor}\n"

		diff -y --suppress-common-lines tmp/$ip.txt tmp/comparer.txt

	else
		
		echo -e "\n${rojo}[!]${finColor} ${blanco}Camara: ${amarillo}$ip${finColor} ${blanco}-${finColor} ${rojo}OFFLINE${finColor}"

	fi
}


#-------------------------
#MODO CONFIGURADOR CÁMARAS
#-------------------------

function configurador(){
	toilet Laboratorio -f pagga.tlf --metal
	
	echo -en "\n${turquesa}[+]${finColor} Introduce el rango de la instalación [192.xxx.xx]: " && read rango
	echo -en "\n${turquesa}[+]${finColor} Introduce el Nº de Host de la 1º camara: "
	echo -en "${turquesa}[+]${finColor} Introduce la password: " && read password
	echo -e "-------------------------------------------------------------------\n"
	
		
	
}

#----------
#ARGUMENTOS
#----------

declare -i contador_argumentos=0

while getopts "crsih" arg; do
	case $arg in
		c) let contador_argumentos+=1;;
		r) let contador_argumentos+=2;;
		s) let contador_argumentos+=3;;
		i) let contador_argumentos+=4;;
		h) ;;
	esac
done


#------------------------
#CONDICIONALES ARGUMENTOS
#------------------------


if [  "$contador_argumentos" -eq 1 ]; then
	configurador
elif [ "$contador_argumentos" -eq 2 ]; then
	revision_errores
elif [ "$contador_argumentos" -eq 3 ]; then
	revision_anterior
elif [ "$contador_argumentos" -eq 4 ]; then
	revision_individual
else
	ayuda
fi
