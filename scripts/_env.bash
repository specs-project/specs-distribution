#!/dev/null

set -e -E -u -o pipefail -o noclobber -o noglob +o braceexpand || exit 1
trap 'printf "[ee] failed: %s\n" "${BASH_COMMAND}" >&2' ERR || exit 1
export -n BASH_ENV

_workbench="$( readlink -e -- . )"
_scripts="${_workbench}/scripts"

if test -z "${pallur_repositories:-}" ; then
	if test -e "${_workbench}/.local-mosaic-repositories" ; then
		_repositories="${_workbench}/.local-mosaic-repositories"
	else
		_repositories="${_workbench}/mosaic-repositories/repositories"
	fi
	echo "[ii] using mosaic-repositories -> \`${_repositories}\`;" >&2
else
	_repositories="${pallur_repositories}"
fi
if test -z "${pallur_dependencies:-}" ; then
	if test -e "${_workbench}/.local-mosaic-dependencies" ; then
		_dependencies="${_workbench}/.local-mosaic-dependencies"
	else
		_dependencies="${_workbench}/mosaic-dependencies/dependencies"
	fi
	echo "[ii] using mosaic-dependencies -> \`${_dependencies}\`;" >&2
else
	_dependencies="${pallur_dependencies}"
fi
if test -z "${pallur_tools:-}" ; then
	if test -e "${_workbench}/.local-tools" ; then
		_tools="${_workbench}/.local-tools"
	else
		_tools="${_workbench}/.temporary/__tools"
	fi
	echo "[ii] using mosaic-tools -> \`${_tools}\`;" >&2
else
	_tools="${pallur_tools}"
fi
if test -z "${pallur_temporary:-}" ; then
	if test -e "${_workbench}/.temporary" ; then
		_temporary="${_workbench}/.temporary"
	else
		_temporary="/tmp/$( basename -- "${_workbench}" )--$( readlink -e -- "${_workbench}" | tr -d '\n' | md5sum -t | tr -d ' \n-' )"
	fi
	echo "[ii] using mosaic-temporary -> \`${_temporary}\`;" >&2
else
	_temporary="${pallur_temporary}"
fi
if test -z "${pallur_PATH:-}" ; then
	if test -e "${_tools}/.prepared" ; then
		_PATH="${_tools}/bin"
		_PATH_stable="${_PATH}"
	else
		_PATH="${_tools}/bin:/usr/local/bin:/usr/bin:/bin"
		_PATH_stable=''
	fi
	echo "[ii] using mosaic-PATH -> \`${_PATH}\`;" >&2
else
	_PATH="${pallur_PATH}"
	_PATH_stable="${pallur_PATH}"
fi

if test -z "${pallur_distribution_version:-}" ; then
	_distribution_version="$( cat "${_workbench}/version.txt" )"
	echo "[ii] using mosaic-distribution-version -> \`${_distribution_version}\`;" >&2
else
	_distribution_version="${pallur_distribution_version}"
fi

if test -e /etc/mos-release ; then
	_local_os_identifier="$( tr ':' '\n' </etc/mos-release | tail -n +2 | head -n 1 )"
	_local_os_version="$( tr ':' '\n' </etc/mos-release | tail -n +3 | head -n 1 )"
elif test -e /etc/slitaz-release ; then
	_local_os_identifier=slitaz
	_local_os_version="$( cat /etc/slitaz-release )"
elif test -e /etc/arch-release ; then
	_local_os_identifier=archlinux
	_local_os_version=rolling
elif test -e /etc/lsb-release ; then
	_local_os_identifier="$( . /etc/lsb-release ; echo "${DISTRIB_ID:-}" )"
	_local_os_version="$( . /etc/lsb-release ; echo "${DISTRIB_RELEASE:-}" )"
else
	_local_os_identifier=
	_local_os_version=
fi

_local_os_identifier="${_local_os_identifier,,}"
_local_os_version="${_local_os_version,,}"
_local_os="${_local_os_identifier:-unknown}::${_local_os_version:-unknown}"

_scripts_env=(
	
	pallur_distribution_version="${_distribution_version}"
	pallur_repositories="${_repositories}"
	pallur_dependencies="${_dependencies}"
	pallur_tools="${_tools}"
	pallur_temporary="${_temporary}"
	pallur_path="${_PATH_stable}"
	
	pallur_local_os_identifier="${_local_os_identifier}"
	pallur_local_os_version="${_local_os_version}"
	pallur_local_os="${_local_os}"
	
	pallur_pkg_erlang="${_tools}/pkg/erlang"
	pallur_pkg_nodejs="${_tools}/pkg/nodejs"
	pallur_pkg_go="${_tools}/pkg/go"
	pallur_pkg_java="${_tools}/pkg/java"
	pallur_pkg_mvn="${_tools}/pkg/mvn"
	pallur_pkg_zeromq="${_tools}/pkg/zeromq"
	pallur_pkg_jzmq="${_tools}/pkg/jzmq"
	pallur_pkg_jansson="${_tools}/pkg/jansson"
	
	pallur_PATH="${_PATH}"
	pallur_CFLAGS="-I${_tools}/include"
	pallur_LDFLAGS="-L${_tools}/lib"
	pallur_LIBS=
	
	PATH="${_PATH}"
	HOME="${HOME:-${_tools}/home}"
	JAVA_HOME="${_tools}/pkg/java"
	MAVEN_HOME="${_tools}/pkg/mvn"
	M2_HOME="${_tools}/pkg/mvn"
	TMPDIR="${_temporary}"
)

case "${mosaic_do_selection:-all}" in
	
	( all )
		_do_prerequisites="${mosaic_do_prerequisites:-true}"
		_do_node="${mosaic_do_node:-true}"
		_do_components="${mosaic_do_components:-true}"
		_do_java="${mosaic_do_java:-true}"
		_do_examples="${mosaic_do_examples:-true}"
		_do_feeds="${mosaic_do_feeds:-true}"
	;;
	
	( core )
		_do_prerequisites="${mosaic_do_prerequisites:-true}"
		_do_node="${mosaic_do_node:-true}"
		_do_components="${mosaic_do_components:-true}"
		_do_java="${mosaic_do_java:-false}"
		_do_examples="${mosaic_do_examples:-false}"
		_do_feeds="${mosaic_do_feeds:-false}"
	;;
	
	( core+java )
		_do_prerequisites="${mosaic_do_prerequisites:-true}"
		_do_node="${mosaic_do_node:-true}"
		_do_components="${mosaic_do_components:-true}"
		_do_java="${mosaic_do_java:-true}"
		_do_examples="${mosaic_do_examples:-false}"
		_do_feeds="${mosaic_do_feeds:-false}"
	;;
	
	( none )
		_do_prerequisites="${mosaic_do_prerequisites:-false}"
		_do_node="${mosaic_do_node:-false}"
		_do_components="${mosaic_do_components:-false}"
		_do_java="${mosaic_do_java:-false}"
		_do_examples="${mosaic_do_examples:-false}"
		_do_feeds="${mosaic_do_feeds:-false}"
	;;
esac

_do_scripts_env_quiet="${mosaic_do_scripts_env_quiet:-true}"

while read _script_env_var ; do
	_scripts_env+=( "${_script_env_var}" )
	case "${_script_env_var}" in
		( _pallur_* | _mosaic_* | _mos_* )
			echo "[ww] exporting private scripts variable \`${_script_env_var}\`;" >&2
		;;
	esac
	if test "${_do_scripts_env_quiet:-}" == false ; then
		echo "[ii] overriding scripts variable \`${_script_env_var}\`;" >&2
	fi
done < <(
	env \
	| grep -E \
			-e '^pallur_[^=]+=.*$' \
			-e '^_pallur_[^=]+=.*$' \
			-e '^mosaic_[^=]+=.*$' \
			-e '^_mosaic_[^=]+=.*$' \
			-e '^mos_[^=]+=.*$' \
			-e '^_mos_[^=]+=.*$' \
	|| true
)
_scripts_env+=( mosaic_do_scripts_env_quiet=true )

if test -n "${SSH_AUTH_SOCK:-}" ; then
	_scripts_env+=( SSH_AUTH_SOCK="${SSH_AUTH_SOCK}" )
fi

function _script_exec () {
	test "${#}" -ge 1
	echo "[ii] executing script \`${@:1}\`..." >&2
	_outcome=0
	env -i "${_scripts_env[@]}" "${@}" 2>&1 \
	| sed -u -r -e 's!^.*$![  ] &!g' >&2 \
	|| _outcome="${?}"
	if test "${_outcome}" -ne 0 ; then
		echo "[ww] failed with ${_outcome}" >&2
		echo "[--]" >&2
		return "${_outcome}"
	else
		echo "[--]" >&2
		return 0
	fi
}

_git_bin="$( PATH="${_PATH}" type -P -- git || true )"
if test -z "${_git_bin}" ; then
	echo "[ww] missing \`git\` (Git DSCV) executable in path: \`${_PATH}\`; ignoring!" >&2
	_git_bin=git
fi

_git_args=()
_git_env=()
while read _git_env_var ; do
	_git_env+=( "${_git_env_var}" )
done < <( env )
