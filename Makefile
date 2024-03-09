mysql_server_instance:
	cd mysql
	docker-compose -up

check_process_in_33060_port:
	sudo lsof -i :33060
