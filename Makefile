check_process_in_33060_port:
	sudo lsof -i :33060

cassandra_:
	docker compose -f ./cassandra/docker-compose.yml up --build 

neo4j_:
	docker compose -f ./neo4j/docker-compose.yml up --build 
