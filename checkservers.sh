# Declaracion de funciones
# check_servers: Valida la carga de los servers
check_servers(){
	printf "Checking DB1 (DB-SERVER LOCAL) ...\n";
	ssh root@db1 uptime
	ssh root@db1 free -mt

	printf "\nChecking WEB1 (WEB-SERVER LOCAL) ...\n";
	ssh root@web1 uptime
	ssh root@web1 free -mt

	printf "\nChecking DB2 (IFX DB-SERVER) ...\n";
	ssh root@db2 uptime
	ssh root@db2 free -mt

	printf "\nChecking WEB2 (IFX WEB) ...\n";
	ssh root@web2 uptime
	ssh root@web2 free -mt

	printf "\nChecking GATEWAY (GATEWAY SERVER) ...\n";
	ssh root@gw -p 57667 uptime
	ssh root@gw -p 57667 free -mt

	printf "\nBLADE4 (TWIN IFX)\n";
	ssh root@blade4 uptime
	ssh root@blade4 free -mt
	
}
# clean_servers: Limpia la memoria swap y cache de los equipos
clean_servers(){
	SERVERS=("db1" "web1" "db2" "web2" "gw" "blade4")
	SERVERSNAMES=("DB1 (DB-SERVER LOCAL)" "WEB1 (WEB-SERVER LOCAL)" "DB2 (IFX DB-SERVER)" "WEB2 (IFX WEB)" "GATEWAY (GATEWAY SERVER)" "BLADE4 (TWIN IFX)")
	ind=0;
	for i in ${SERVERS[@]}; do
		printf "Cleaning ${SERVERSNAMES[$ind]}...\n"

		# Eliminacion de memoria swap utilizada
		CMD="swapoff -a && swapon -a"
		# Eliminacion de cache en ram
		CMD2="sync &&sysctl -w vm.drop_caches=3 && sleep 3 && sysctl -w vm.drop_caches=0"
		
		if [ ${i} == "gw" ] 
			then
				CMD=" -p 57667 $CMD"
				CMD2=" -p 57667 $CMD2"
		fi
		# Cleanin server
		#echo $CMD
		echo " \_Cleaning Swap..."
		ssh "root@${i}" $CMD
		echo " \_Cleaning Cache..."
		ssh "root@${i}" $CMD2
		ind=$((ind+1))
	done
}
# usage: Indica la forma de uso del programa
usage(){
	printf "\ncheckservers.sh [options] 
	run: 	Just check the server's estatus
	clean: 	Just clean server's cache (swap and ram)
	chkcln:	Check and clean\n\n";
  	exit 1;
}
# parse: Valida la opcion indicada
parse(){
	case "$1" in
		# Just check servers
		run) check_servers ;;
		# Just clean servers
		clean) clean_servers ;;
		# Check and clean servers
		chkcln) 
			check_servers
		    clean_servers
		    ;;
		*) echo "Invalid option"
			exit 1;
		   ;;
	esac
}

# Validacion de parametros
if [ $# -ne 0 ]
  then
    parse $1
  else
  	usage
fi
