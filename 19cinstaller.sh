#!/bin/sh

# Instalador de OracleDB para Red Hat Enterprise Linux

# Si deseas mejorar este script aquí hay una lista de cosas por hacer :)
#
# TODO: Dividir todos los pasos de setup en funciones (para manejo de errores)
# TODO: Reducir los if, hay formas más elegantes
# TODO: Revisar si este script ya fue ejecutado antes y limpiar si es necesario
# TODO: Reducir la cantidad de "if" en las función depcheck
# TODO: Evitar pasarse de la columna 80
# TODO: Evitar tener que recargar la sesión a mano.

# Variables (Siempre son globales, así que no importa xD)
pinst_pkg="oracle-database-preinstall-19c-1.0-2.el8.x86_64.rpm"
dbzip="LINUX.X64_193000_db_home.zip"
release="Red Hat Enterprise Linux release 8.5 (Ootpa)"
oracle_dir="/u01/app/oracle/product/19.3/dbhome_1"


# Función de ayuda
help () {
    echo "Instalador de OracleDB para RHEL 8.x
    Uso: instalador.sh [OPCIONES]
    OPCIONES:
        --help: Pantalla de ayuda"
}

# Función de chequeo de dependencias
depcheck() {
    if [ ! " $(cat /etc/redhat-release)" = "$release" ]; then
        echo "Versión de Red Hat no soportada, este script solo funciona con $release"
        exit 1
    fi

    # Revisar si existen los archivos propios de Oracle Database
    if [ ! -f "$pinst_pkg" ]; then
        echo "El archivo $pinst_pkg no existe. Descargando..."
        curl -o $pinst_pkg https://yum.oracle.com/repo/OracleLinux/OL8/appstream/x86_64/getPackage/oracle-database-preinstall-19c-1.0-2.el8.x86_64.rpm


    fi

    if [ ! -f "$dbzip" ]; then
        echo "El archivo $dbzip no existe. Puedes descargarlo aquí: https://www.oracle.com/mx/database/technologies/oracle19c-linux-downloads.html
        Una vez descargado solo arrástralo en el explorador de archivos de tu MobaXterm"
    fi  
}

# Función de configuración
setup() {
    echo "Instalando dependencias..."
    sudo dnf install bc xorg-x11-server-Xorg binutils elfutils-libelf elfutils-libelf-devel fontconfig-devel glibc glibc-devel ksh libaio libaio-devel libgcc libnsl librdmacm-devel libstdc++ libstdc++-devel libX11 libXau libxcb libXi libXrender libXrender-devel libXtst make net-tools nfs-utils python3 python3-configshell python3-rtslib python3-six smartmontools sysstat targetcli unzip
    echo "Descargando bibliotecas de RHEL 7.x"
    wget http://mirror.centos.org/centos/7/os/x86_64/Packages/compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm
    wget http://mirror.centos.org/centos/7/os/x86_64/Packages/compat-libcap1-1.10-7.el7.x86_64.rpm
    sudo dnf localinstall compat-libcap1-1.10-7.el7.x86_64.rpm
    sudo dnf localinstall $pinst_pkg
    sudo dnf localinstall compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm
    clear
    echo "Dependencias instaladas correctamente...
    Deshabilitando SELinux"
    sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
    sudo setenforce Permissive
    echo "Deshabilitando (y deteniendo) firewall"
    sudo systemctl disable --now firewalld
    echo "Creando grupos para OracleDB"
    sudo groupadd -g 1001 oinstall
    sudo groupadd -g 1002 dba
    sudo groupadd -g 1003 oper
    sudo useradd -u 1001 -g oinstall -G dba,oper oracle
    echo "Escriba una contraseña para el usuario oracle"
    sudo passwd oracle
    echo "Escriba una contraseña para el usuario root (Esto será necesario)"
    sudo passwd root
    clear
    echo "Escribiendo variable de entorno"
    echo "export CV_ASSUME_DISTID=OEL7.6" | tee -a .bashrc
    echo "export CV_ASSUME_DISTID=OEL7.6" | tee -a .profile
    echo "export CV_ASSUME_DISTID=OEL7.6" | tee -a .bash_profile
    sudo mkdir $oracle_dir
    echo "asignando permisos al directorio: $oracle_dir"
    sudo chown -R oracle:oinstall /u01
    sudo chmod -R 775 /u01
    su - c "unzip $dbzip -d $oracle_dir" oracle
}

ora_install() {
    export CV_ASSUME_DISTID=OEL7.6
    sudo -u oracle ./u01/app/oracle/product/19.3/dbhome_1/runInstaller
}

# Función principal
main() {
    echo "Este script hará uso de 'sudo'. No deje desatendida su máquina.
    Revisando prerequisitos para la instalación..."
    depcheck;
    setup;
    clear
    echo "Ejecutando instalador como usuario Oracle..."
    ora_install;
    echo "Instalación de OracleDB Finalizada. Puede eliminar este script de su sitema..."
}

# Manejar argumentos
if [ "$1" = "--help" ]; then
    help;
else
    main;
fi
