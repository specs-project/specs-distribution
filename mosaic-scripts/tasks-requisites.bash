#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

_packages=(
		erlang-15
		erlang-17
		nodejs
		nodejs-caches
		go
		maven
		maven-caches
		zeromq
		jzmq
		jansson
		ninja
		vbs
		js-1.8.5
		js-1.8.0
		nspr-4.9
		nspr-4.8
)

_os_packages=(
		java
		python-2
		rpm
)

for _package in "${_packages[@]}" ; do
	cat <<EOS

pallur-packages : pallur-packages@${_package}

pallur-packages@${_package} : pallur-environment
	!bash ${_workbench}/mosaic-scripts/prepare-${_package}.bash

EOS
done

for _package in "${_os_packages[@]}" ; do
	cat <<EOS

pallur-packages : pallur-packages@${_package}

pallur-packages@${_package} : pallur-os

EOS
done

cat <<EOS

pallur-packages@jzmq : pallur-packages@zeromq
pallur-packages@js-1.8.5 : pallur-packages@nspr-4.9
pallur-packages@js-1.8.0 : pallur-packages@nspr-4.8
pallur-packages@maven : pallur-packages@maven-caches
pallur-packages@nodejs : pallur-packages@nodejs-caches

EOS

cat <<EOS

pallur-packages : pallur-os

pallur-os :
	!bash ${_workbench}/mosaic-scripts/prepare-os.bash

EOS

exit 0
