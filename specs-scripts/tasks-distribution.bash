#!/dev/null

if ! test "${#}" -eq 0 ; then
	echo "[ee] invalid arguments; aborting!" >&2
	exit 1
fi

for _task in requisites prepare compile package publish ; do
	cat <<EOS

specs-distribution@${_task} : \
		specs-distribution@all@${_task}

specs-distribution@all@${_task} : \
		specs-distribution@node@${_task} \
		specs-distribution@components@${_task} \
		specs-distribution@platform-core@${_task} \
		specs-distribution@platform-java@${_task}

specs-distribution@node@${_task} : \
		mosaic-node@${_task} \
		mosaic-node-wui@${_task} \
		mosaic-node-boot@${_task}

specs-distribution@components@${_task} : \
		mosaic-components-couchdb@${_task} \
		mosaic-components-rabbitmq@${_task} \
		mosaic-components-riak-kv@${_task} \
		mosaic-components-mysql@${_task} \
		mosaic-components-me2cp@${_task} \
		mosaic-components-httpg@${_task}

specs-distribution@platform-core@${_task} : \
		specs-distribution@node@${_task} \
		specs-distribution@components@${_task}

specs-distribution@platform-java@${_task} : \
		mosaic-java-platform-artifacts@${_task} \
		mosaic-components-java-component-container@${_task} \
		mosaic-components-java-cloudlet-container@${_task} \
		mosaic-components-java-driver-amqp@${_task} \
		mosaic-components-java-driver-riak@${_task} \
		specs-distribution@node@${_task} \
		specs-distribution@components@${_task}

EOS
done

exit 0
