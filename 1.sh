#!/bin/bash

if [ $(id -u) != 0 ]; then
        echo "This script must be run as root."
        exit 1
fi

drupal_path=${1%/}
drupal_user=${2}
httpd_group="${3:-www-data}"

# Help menu
print_help() {
cat <<-HELP

This script is used to fix permissions of a drupal installation
you need to provide the following arguments:

1) Path to your drupal installation
2) Username of the user that you want to give files/directories ownership
3) HTTPD group name (defaults to www-data for apache)

Usage: (sudo) bash ${0##*/} --drupal_path=USER --drupal_user=USER --httpd_group=GROUP

Example: (sudo) bash ${0##*/} --drupal_path=/usr/local/apache2/htdocs --drupal_user=john --httpd_group=www-data

HELP
exit 0
}

# Parse Command Line Arguments
while [ $# -gt 0 ]; do
        case "$1" in
                --drupal_path=*) 
			drupal_path="${1#*=}"
			;;
		--drupal_user=*)
			drupal_user="${1#*=}"
			;;
		--httpd_group=*)
			httpd_group="${1#*=}"
			;;
		--help) print_help;;
		*)
			echo "Invalid argument, run --help for valid arguments";
			exit 1
	esac
	shift
done

if [ -z "${drupal_path}" ] || [ ! -d "${drupal_path}/sites" ] || [ ! -f "${drupal_path}/modules/system/system.module" ]; then
	echo "Please provide a valid drupal path"
	print_help
	exit 1
fi

if [ -z "${drupal_user}" ] || [ $(id -un ${drupal_user} 2> /dev/null) != "${drupal_user}" ]; then
	echo "Please provide a valid user"
	print_help
	exit 1
fi


cd $drupal_path
echo -e "Changing ownership of all contents of \"${drupal_path}\" :\n user => \"${drupal_user}\" \t group => \"${httpd_group}\"\n"
chown -R ${drupal_user}:${httpd_group} .

echo "Changing permissions of all directories inside \"${drupal_path}\" to \"rwxr-x---\"..."
find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;

echo -e "Changing permissions of all files inside \"${drupal_path}\" to \"rw-r-----\"...\n"
find . -type f -exec chmod u=rw,g=r,o= '{}' \;

echo "Changing permissions of \"files\" directories in \"${drupal_path}/sites\" to \"rwxrwx---\"..."
cd ${drupal_path}/sites
find . -type d -name files -exec chmod ug=rwx,o= '{}' \;
echo "Changing permissions of all files inside all \"files\" directories in \"${drupal_path}/sites\" to \"rw-rw----\"..."
echo "Changing permissions of all directories inside all \"files\" directories in \"${drupal_path}/sites\" to \"rwxrwx---\"..."

for x in ./*/files; do
	find ${x} -type d -exec chmod ug=rwx,o= '{}' \;
	find ${x} -type f -exec chmod ug=rw,o= '{}' \;
done

echo "Done settings proper permissions on files and directories"

