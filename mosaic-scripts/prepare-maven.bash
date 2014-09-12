#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

echo "[ii] building \`mvn\` (Maven)..." >&2

if test -e "${_tools}/pkg/maven" ; then
	echo "[ii] \`mvn\` package already exists; aborting!" >&2
	echo "[ii] (to force the build remove the folder \`${_tools}/pkg/maven\`)" >&2
	exit 0
fi

_outputs="${_temporary}/mvn--build"

echo "[ii] preparing..." >&2

mkdir -- "${_outputs}"

curl -s 'http://www.eu.apache.org/dist/maven/maven-3/3.1.1/binaries/apache-maven-3.1.1-bin.tar.gz' \
| tar -xz -C "${_outputs}" --strip-components 1
chmod -R a=rX,u=rwX -- "${_outputs}"

echo "[ii] deploying..." >&2

mkdir -- "${_tools}/pkg/maven"
( cd -- "${_outputs}" ; exec find . -not -name '.git' -print0 ; ) \
| ( cd -- "${_outputs}" ; exec cpio -p -0 --quiet -- "${_tools}/pkg/maven" ; )
chmod -R a=rX,u=rwX -- "${_tools}/pkg/maven"

echo "[ii] configuring..." >&2

cat >|"${_tools}/pkg/maven/conf/settings.xml" <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<settings
			xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
	<localRepository>${_tools}/pkg/maven/repo</localRepository>
	<offline>false</offline>
</settings>
EOS

echo "[ii] bootstrapping..." >&2

( . "${_workbench}/mosaic-scripts/prepare-maven-caches.bash" ; )

# FIXME: Make Maven fetch all required "base" plugins!
_do_exec env \
			M2_HOME="${_tools}/pkg/maven" \
	"${_tools}/pkg/maven/bin/mvn" --quiet help:help

echo "[ii] sealing..." >&2

chmod -R a=rX -- "${_tools}/pkg/maven"

echo "[ii] cleaning..." >&2

rm -R -- "${_outputs}"

exit 0
