#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

echo "[ii] building \`jzmq\` (Java ZeroMQ)..." >&2

if test -e "${_tools}/pkg/jzmq" ; then
	echo "[ii] \`jzmq\` package already exists; aborting!" >&2
	echo "[ii] (to force the build remove the folder \`${_tools}/pkg/jzmq\`)" >&2
	exit 0
fi

_outputs="${_temporary}/jzmq--build"
_repository="${_repositories}/jzmq"

echo "[ii] preparing..." >&2

mkdir -- "${_outputs}"
cd -- "${_repository}"
find . -not -name '.git' -print0 | cpio -p -0 --quiet -- "${_outputs}"
chmod -R a=rX,u=rwX -- "${_outputs}"
cd -- "${_outputs}"

_CFLAGS="-I${pallur_pkg_java}/include ${pallur_CFLAGS}"
_LDFLAGS="-L${pallur_pkg_java}/lib ${pallur_LDFLAGS}"
_LIBS="${pallur_LIBS}"
_JAVA_HOME="${pallur_pkg_java}"

echo "[ii] building..." >&2

_do_exec \
	./autogen.sh

_do_exec env \
			CFLAGS="${_CFLAGS}" \
			LDFLAGS="${_LDFLAGS}" \
			LIBS="${_LIBS}" \
			JAVA_HOME="${_JAVA_HOME}" \
	./configure \
		--prefix="${_tools}/pkg/jzmq" \
		--with-zeromq="${pallur_pkg_zeromq}"

_do_exec env \
			CFLAGS="${_CFLAGS}" \
			LDFLAGS="${_LDFLAGS}" \
			LIBS="${_LIBS}" \
			JAVA_HOME="${_JAVA_HOME}" \
	make -j 1

_do_exec \
	gcc -shared -o ./libjzmq.so \
		-I "${_JAVA_HOME}/include" \
		-L "${_JAVA_HOME}/lib" \
		-I "${pallur_pkg_zeromq}/include" \
		-L "${pallur_pkg_zeromq}/lib" \
		-I ./src \
		-w \
		${CFLAGS:-} ${LDFLAGS:-} \
		./src/ZMQ.cpp \
		./src/Context.cpp \
		./src/Socket.cpp \
		./src/Poller.cpp \
		./src/util.cpp \
		${pallur_LIBS:-} \
		-Wl,-Bstatic -lzmq -luuid -Wl,-Bdynamic \
		-Wl,-Bstatic -lstdc++ -Wl,-Bdynamic \
		-static-libgcc -static-libstdc++

echo "[ii] deploying..." >&2

mkdir -- "${_tools}/pkg/jzmq"
mkdir -- "${_tools}/pkg/jzmq/lib"

cp -T -- ./libjzmq.so "${_tools}/pkg/jzmq/lib/libjzmq.so"

echo "[ii] sealing..." >&2

chmod -R a=rX -- "${_tools}/pkg/jzmq"

echo "[ii] cleaning..." >&2

rm -R -- "${_outputs}"

exit 0
