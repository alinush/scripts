vDir=${1:-`pwd`}
vDir=$(cd "$vDir"; pwd -P)

echo "Listing extension in directory: $vDir"

find "$vDir" -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u
