mysql_server_instance:
	docker run --name mysql-server \
	-e MYSQL_ROOT_PASSWORD=root \
	-e MYSQL_DATABASE=practica_cassandra_database \
	-p 33060:3306 \
	-v ./sql:/docker/sql \
	-d mysql:8.3.0
