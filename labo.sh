#!/bin/bash

#-------
#COLORES
#-------

verde="\e[0;32m\033[1m"
finColor="\033[0m\e[0m"
rojo="\e[0;31m\033[1m"
azul="\e[0;34m\033[1m"
amarillo="\e[0;33m\033[1m"
morado="\e[0;35m\033[1m"
turquesa="\e[0;36m\033[1m"
blanco="\e[0;37m\033[1m"

#----------------------------------------------------------------------------------------
#---------
#FUNCIONES
#---------


#FUNCION Ctrl+C

function ctrl_c(){
	echo -e "\n${rojo}[!] Deteniendo Script [!]${finColor}"
	exit 1
}

trap ctrl_c INT


#----------------
#REVISION ERRORES
#----------------

function revision_errores(){
	#Banner
	toilet Revisor -f pagga.tlf --metal

	#Preguntas info datos
	echo -en "\n${turquesa}[+]${finColor} ${blanco}Introduce el rango de la instalación [192.xxx.xx]: ${finColor}" && read rango
	echo -en "\n${turquesa}[+]${finColor} ${blanco}Introduce el Nº de Host de la 1º camara: ${finColor}" && read camara_1
	echo -en "\n${turquesa}[+]${finColor} ${blanco}Introduce el Nº de Host de la última camara: ${finColor}" && read camara_final
	echo -en "\n${turquesa}[+]${finColor} ${blanco}Introduce la password de la instalacion: ${finColor}" && read password
	echo -e "\n${blanco}-------------------------------------------------------------------${finColor}\n"
	#Save de datos para posteriores ejecuciones
	echo "$rango" > tmp/rango.txt
	echo "$camara_1" > tmp/camara_1.txt
	echo "$camara_final" > tmp/camara_final.txt
	echo "$password" > tmp/password.txt
	
	#Appends
	declare -a nombres_camaras=()
	declare -a remitente_camaras=()
	declare -a gateway_camaras=()

	#Llamadas API
	for descarga in $(seq $camara_1 $camara_final); do

		timeout 1 ping -c 1 $rango.$descarga >/dev/null

		if [ "$?" -eq 0 ]; then

			touch tmp/$descarga.txt

			nombres="$(curl http://$rango.$descarga/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | grep "<deviceName>" | sed 's/<deviceName>/[+] Camara: /' | sed 's/<\/deviceName>/ - ONLINE/')"

			nombres_camaras+=("$nombres")
			
			remitente="$(curl http://$rango.$descarga/ISAPI/System/network/mailing --digest -u "admin:$password" -s | grep "<name>" | sed '2,4d' | sed 's/<name>/- Remitente: /' | sed 's/<\/name>//')"

			remitente_camaras+=("$remitente")
		
			gateway="$(curl http://$rango.$descarga/ISAPI/System/Network/interfaces --digest -u "admin:$password" -s | grep "<ipAddress>" | sed '1d' | sed '2,3d' | sed 's/<ipAddress>/- Gateway:/' | awk -F "<" '{print $1}')"

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

		else
			echo -e "\n${rojo}[!] Camara: C$descarga"Nx" - OFFLINE${finColor}\n"
		fi
	done
	
	#Variables para control posicional de los Appends
	declare -i numero_camaras=0
	declare -i numero_remitente=0
	declare -i numero_gateway=0

	#Revisión sobre los dispositivos encontrados y echo de datos de appends
	for dispositivos in $(seq $camara_1 $camara_final); do	

		echo -e "${morado}${nombres_camaras[$numero_camaras]}${finColor}"
		numero_camaras+=1
		echo -e "${blanco} ${remitente_camaras[$numero_remitente]}${finColor}"
		numero_remitente+=1
		echo -e "${blanco} ${gateway_camaras[$numero_gateway]}${finColor}\n"
		numero_gateway+=1
	
		#diff para comparar datos y rm para eliminar los archivos temporales
		diff -y --suppress-common-lines tmp/$dispositivos.txt tmp/comparer.txt 2>/dev/null
		rm tmp/$dispositivos.txt 2>/dev/null

	done
}


#----------------
#REPETIR REVISION
#----------------

function repetir_revision(){
	#Variables extraidas de ejecución anterior
	rango="$(cat tmp/rango.txt)"
	camara_1="$(cat tmp/camara_1.txt)"
	camara_final="$(cat tmp/camara_final.txt)"
	password="$(cat tmp/password.txt)"

	#Appends datos
	declare -a nombres_camaras=()
	declare -a remitente_camaras=()
	declare -a gateway_camaras=()

	#Llamadas API
	for descarga in $(seq $camara_1 $camara_final); do

		timeout 1 ping -c 1 $rango.$descarga >/dev/null

		if [ "$?" -eq 0 ]; then

			touch tmp/$descarga.txt

			nombres="$(curl http://$rango.$descarga/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | grep "<deviceName>" | sed 's/<deviceName>/[+] Camara: /' | sed 's/<\/deviceName>/ - ONLINE/')"

			nombres_camaras+=("$nombres")
			
			remitente="$(curl http://$rango.$descarga/ISAPI/System/network/mailing --digest -u "admin:$password" -s | grep "<name>" | sed '2,4d' | sed 's/<name>/- Remitente: /' | sed 's/<\/name>//')"

			remitente_camaras+=("$remitente")
		
			gateway="$(curl http://$rango.$descarga/ISAPI/System/Network/interfaces --digest -u "admin:$password" -s | grep "<ipAddress>" | sed '1d' | sed '2,3d' | sed 's/<ipAddress>/- Gateway:/' | awk -F "<" '{print $1}')"

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

		else
			echo -e "\n${rojo}[!] Camara: C$descarga"Nx" - OFFLINE${finColor}\n"
		fi
	done

	#Variables para control posicional de los Appends
	declare -i numero_camaras=0
	declare -i numero_remitente=0
	declare -i numero_gateway=0

	#Revisión sobre los dispositivos encontrados y echo de datos de appends
	for dispositivos in $(seq $camara_1 $camara_final); do	

		echo -e "${morado}${nombres_camaras[$numero_camaras]}${finColor}"
		numero_camaras+=1
		echo -e "${blanco} ${remitente_camaras[$numero_remitente]}${finColor}"
		numero_remitente+=1
		echo -e "${blanco} ${gateway_camaras[$numero_gateway]}${finColor}\n"
		numero_gateway+=1
	
		#diff para comparar datos y rm para eliminar los archivos temporales
		diff -y --suppress-common-lines tmp/$dispositivos.txt tmp/comparer.txt 2>/dev/null
		rm tmp/$dispositivos.txt 2>/dev/null

	done

}


#-------------------
#REVISION INDIVIDUAL
#-------------------


function revision_individual(){
	#Preguntas
	echo -en "\n${turquesa}[+]${finColor} ${blanco}Intoduce la IP del dispositivo: ${finColor}" && read ip
	echo -en "${turquesa}[+]${finColor} ${blanco}Intoduce la password: ${finColor}" && read password
	echo -e "\n${blanco}-------------------------------------------------------------------${finColor}\n"

	timeout 1 ping -c 1 $ip >/dev/null

	if [ "$?" -eq 0 ]; then

		touch tmp/$ip.txt

		nombres="$(curl http://$ip/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | grep "<deviceName>" | sed 's/<deviceName>/[+] Camara: /' | sed 's/<\/deviceName>/ - ONLINE/')"
		
		remitente="$(curl http://$ip/ISAPI/System/network/mailing --digest -u "admin:$password" -s | grep "<name>" | sed '2,4d' | sed 's/<name>/- Remitente: /' | sed 's/<\/name>//')"
	
		gateway="$(curl http://$ip/ISAPI/System/Network/interfaces --digest -u "admin:$password" -s | grep "<ipAddress>" | sed '1d' | sed '2,3d' | sed 's/<ipAddress>/- Gateway:/' | awk -F "<" '{print $1}')"

		info_pet="$(curl http://$ip/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | awk "/<deviceName>/,/<firmwareReleasedDate>/" | sed 's/<model>/Modelo:/' | sed 's/<firmwareVersion>/Firmware:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge tmp/$ip.txt)"

		hora_pet="$(curl http://$ip/ISAPI/System/time/ntpServers --digest -u "admin:$password" -s | sed 's/<hostName>/NTP:/' | sed 's/<synchronizeInterval>/Intervalo:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$ip.txt)"

		hora_mode="$(curl http://$ip/ISAPI/System/time --digest -u "admin:$password" -s | grep "<timeMode>" | sed 's/<timeMode>/Modo hora:/' | sed 's/<\/timeMode>//' | sponge -a tmp/$ip.txt)"

		net_pet="$(curl http://$ip/ISAPI/System/Network/interfaces --digest -u "admin:$password" -s | grep "<ipAddress>" | sed '1,2d' | sed 's/<ipAddress>/DNS:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$ip.txt)"

		mail_pet="$(curl http://$ip/ISAPI/System/network/mailing --digest -u "admin:$password" -s | sed '1,5d' | sed '2,6d' | sed '4,11d' | sed '6,19d' | sed '8,11d' | sed 's/<emailAddress>/Email:/' | sed 's/<hostName>/SMTP:/' | sed 's/<portNo>/Puerto:/' | sed 's/<name>/Soporte:/' | sed 's/<enabled>/Imagen:/' | sed 's/<interval>/Intervalo:/' | awk -F "<" '{print $1}' | sponge -a tmp/$ip.txt)"

		sd_pet="$(curl http://$ip/ISAPI/ContentMgmt/Storage/hdd --digest -u "admin:$password" -s | grep "<status>" | sed 's/<status>/Formateo:/' | sed 's/<\/status>//' | xargs -n 1 | sponge -a tmp/$ip.txt)"

		osd_pet="$(curl http://$ip/ISAPI/System/Video/inputs/channels/1/overlays --digest -u "admin:$password" -s | grep "<dateStyle>" -A 2 | sed 's/<dateStyle>/Formato fecha:/' | sed 's/<timeStyle>/Estilo fecha:/' | sed 's/<displayWeek>/Semana:/' | awk -F "<" '{print $1}' | sponge -a tmp/$ip.txt)"
		
		resolucion="$(curl http://$ip/ISAPI/Streaming/channels --digest -u "admin:$password" -s | grep -A 9 "videoCodecType" | sed 's/<videoCodecType>/Compresion:/' | sed 's/<videoResolutionWidth>/Anchura:/' | sed 's/<videoResolutionHeight>/Altura:/' | sed 's/<constantBitRate>/BitRate:/' | sed 's/<maxFrameRate>/FPS:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$ip.txt)"
	
	
		excep_hdd="$(curl http://$ip/ISAPI/Event/triggers/illaccess --digest -u "admin:$password" -s | grep "<notificationMethod>" | sed 2d | sed 's/<notificationMethod>/Login ilegal:/' | awk -F "<" '{print $1}' | sponge -a tmp/$ip.txt)"

		excep_login="$(curl http://$ip/ISAPI/Event/triggers/diskerror --digest -u "admin:$password" -s | grep "<notificationMethod>" | sed 2d | sed 's/<notificationMethod>/HDD Error:/' | awk -F "<" '{print $1}' | sponge -a tmp/$ip.txt)"

		quota="$(curl http://$ip/ISAPI/ContentMgmt/Storage/quota --digest -u "admin:La-916783315" -s | grep "<videoQuotaRatio>" | sed 's/<videoQuotaRatio>/Quota:/' | awk -F "<" '{print $1}' | sponge -a tmp/$ip.txt)"

		tracks="$(curl http://$ip/ISAPI/ContentMgmt/record/tracks --digest -u "admin:$password" -s | sed 's/<DayOfWeek>/Dia:/' | sed 's/<TimeOfDay>/Horas:/' | sed 's/<Record>/Grabacion:/' | sed 's/<ActionRecordingMode>/Modo:/' | sed 's/<PreRecordTimeSeconds>/Adelanto:/' | sed 's/<PostRecordTimeSeconds>/Retardo:/' | sed 's/<Duration>/Duracion:/' | sed 's/<durationEnabled>/Caducidad:/' | awk -F "<" '{print $1}' | xargs -n 1 | sponge -a tmp/$ip.txt)"

		echo -e "${morado}$nombres${finColor}"
		echo -e "${blanco}$remitente${finColor}"
		echo -e "${blanco}$gateway${finColor}"

		diff -y --suppress-common-lines tmp/$ip.txt tmp/comparer.txt 2>/dev/null
		rm tmp/$ip.txt 2>/dev/null
	else
		echo -e "\n${rojo}[!] Camara: $ip - OFFLINE${finColor}\n"
	fi

}


#---------
#CORRECTOR
#---------

function corrector(){
	toilet Corrector -f pagga.tlf --metal

	#Pregunta de parámetro a corregir
	echo -e "\n${morado}[!]${finColor} ${blanco}Que quieres corregir?${finColor} ${morado}[!]${finColor}\n"
	
	echo -e "\t${turquesa}[1]${finColor} ${blanco}NTP${finColor}"

	echo -en "\n${morado}[+]${finColor} ${blanco}Introduce el parámetro a corregir: ${finColor}" && read parameter
	
	#IF para seleccionar parámetro
	
	#CORRECCIÓN NTP
	if [ "$parameter" -eq 1 ]; then
		echo -en "\n${morado}[?]${finColor} ${blanco}Corregir múltiples dispositivos? ${finColor}${turquesa}[Y/N]${finColor}${blanco}:${finColor} " && read sino
		
		#Condicional en el parámetro 1 para corregir 1 dispositivo o más (respuesta y/n)
		if [[ "$sino" == "Y" || "$sino" == "y" ]]; then

			#Preguntas datos dispositivos
			echo -en "\n${turquesa}[+]${finColor} ${blanco}Introduce el rango de la instalación [192.xxx.xx]: ${finColor}" && read rango
			echo -en "\n${turquesa}[+]${finColor} ${blanco}Introduce el Nº de Host de la 1º camara: ${finColor}" && read camara_1
			echo -en "\n${turquesa}[+]${finColor} ${blanco}Introduce el Nº de Host de la última camara: ${finColor}" && read camara_final
			echo -en "\n${turquesa}[+]${finColor} ${blanco}Introduce la password de la instalacion: ${finColor}" && read password
			echo -e "\n${blanco}-------------------------------------------------------------------${finColor}\n"
			
			#Corrección de datos
			for camaras in $(seq $camara_1 $camara_final); do
				
				timeout 1 ping -c 1 $rango.$camaras >/dev/null

				if [ "$?" -eq 0 ]; then
					nombres="$(curl http://$rango.$camaras/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | grep "<deviceName>" | sed 's/<deviceName>/[+] Camara: /' | sed 's/<\/deviceName>/- CORREGIDA/')"

					curl -X POST -d "@xml_parameters/XML_NTPServer.xml" -H "Content-Type: application/xml" http://$rango.$camaras/ISAPI/System/time/ntpServers --digest -u "admin:$password" -s >/dev/null
					echo -e "${verde}$nombres${finColor}" 				
				else
					echo -e "${rojo}[!] Camara: $rango.$camaras - OFFLINE${finColor}"
				fi

			done

		elif [[ "$sino" == "N" || "$sino" == "n" ]]; then
			
			echo -en "\n${turquesa}[+]${finColor} ${blanco}Intoduce la IP del dispositivo: ${finColor}" && read ip
			echo -en "${turquesa}[+]${finColor} ${blanco}Intoduce la password: ${finColor}" && read password
			echo -e "\n${blanco}-------------------------------------------------------------------${finColor}\n"

			timeout 1 ping -c 1 $ip >/dev/null

			if [ "$?" -eq 0 ]; then
				nombres="$(curl http://$ip/ISAPI/System/deviceInfo --digest -u "admin:$password" -s | grep "<deviceName>" | sed 's/<deviceName>/[+] Camara: /' | sed 's/<\/deviceName>/- CORREGIDA/')"
				curl -X POST -d "@xml_parameters/XML_NTPServer.xml" -H "Content-Type: application/xml" http://$ip/ISAPI/System/time/ntpServers --digest -u "admin:$password" -s >/dev/null
				echo -e "${verde}$nombres${finColor}" 				

			else
				echo -e "${rojo}[!] Camara: $ip - OFFLINE${finColor}"
			fi
		else
			echo -e "\n${rojo}[!] ERROR [!]${finColor}"
		fi

	else
		echo -e "${rojo}[!] Número Incorrecto [!]${finColor}"
	fi


}

#-------------------------------------------------------------------------------------------

#SELECCIÓN DE MODO

toilet Laboratorio -f pagga.tlf --metal

echo -e "\n${morado}[!]${finColor} ${blanco}Selecciona un modo de uso${finColor} ${morado}[!]${finColor}"
echo -e "\n\t${turquesa}[1]${finColor} ${blanco}Modo Revisión Errores${finColor}"
echo -e "\t${turquesa}[2]${finColor} ${blanco}Modo Repetir Revisión${finColor}"
echo -e "\t${turquesa}[3]${finColor} ${blanco}Modo Revisión Individual${finColor}"
echo -e "\t${turquesa}[4]${finColor} ${blanco}Corrector de Cámaras${finColor}"
echo -e "\t${turquesa}[5]${finColor} ${blanco}Configurador de Cámaras${finColor}"

#Lectura del número de modo añadiendose a variable "mode"
echo -en "\n${morado}[+]${finColor} ${blanco}Introduce el modo a utilizar: ${finColor}" && read mode
echo -e "\n${blanco}-------------------------------------------------------------------${finColor}\n"

#Ejecución de los modos según la variable "mode"
if [ "$mode" -eq 1 ]; then
	revision_errores
elif [ "$mode" -eq 2 ]; then
	repetir_revision
elif [ "$mode" -eq 3 ]; then
	revision_individual
elif [ "$mode" -eq 4 ]; then
	corrector
else
	echo -e "${rojo}[!] Número Incorrecto [!]${finColor}"
fi
