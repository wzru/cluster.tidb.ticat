set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

shift
user="${1}"
auto_conf_mysql=`to_true "${2}"`
roles="${3}"

name=`must_env_val "${env}" 'tidb.cluster'`
if [ -z "${roles}" ]; then
	tiup cluster start "${name}"
else
	tiup cluster start "${name}" --role "${roles}"
fi

tidbs=`must_cluster_tidbs "${name}"`

cnt=`echo "${tidbs}" | wc -l | awk '{print $1}'`
if [ "${cnt}" != 1 ]; then
	echo "[:-] more than 1 tidb found(${cnt}) in cluster '${name}', select the first one" >&2
fi

tidb=`echo "${tidbs}" | head -n 1`
host=`echo "${tidb}" | awk -F ':' '{print $1}'`
port=`echo "${tidb}" | awk -F ':' '{print $2}'`

verify_mysql_timeout "${host}" "${port}" "${user}" 16

if [ "${auto_conf_mysql}" == 'true' ]; then
	config_mysql "${env_file}" "${host}" "${port}" "${user}"
fi
