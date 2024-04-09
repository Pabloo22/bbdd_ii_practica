check_process_in_3306_port:
	sudo lsof -i :3306

cassandra_:
	cd cassandra && docker compose up --build

neo4j_:
	cd neo4j && docker compose up --build

dump_dungeons:  # Copiar en terminal
	cd neo4j && docker run -it --tty --rm --user=$(id -u):$(id -g) --volume=$PWD/data:/data --volume=$PWD/import:/backups neo4j/neo4j-admin:5.13.0 neo4j-admin database load dungeons --from-path=/backups
