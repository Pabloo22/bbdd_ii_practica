check_process_in_33060_port:
	sudo lsof -i :33060

cassandra_:
	cd cassandra && docker compose up --build

neo4j_:
	cd neo4j && docker compose up --build
