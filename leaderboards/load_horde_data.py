import os
import csv

from cassandra.cluster import Cluster


def main():
    cluster = Cluster(["localhost"], port=9042)

    try:
        # Create keyspace and table
        session = cluster.connect()
        session.execute(
            """
            CREATE KEYSPACE IF NOT EXISTS dungeons
            WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor': 2}
        """
        )

        session.set_keyspace("dungeons")

        # Create table if not exists
        session.execute(
            """
            CREATE TABLE IF NOT EXISTS hordas(
                country VARCHAR,
                event_id INT,
                username VARCHAR,
                email VARCHAR,
                n_kills COUNTER,
                PRIMARY KEY ((country, event_id), email, username)
            );
        """
        )

        # insert_stmt = session.prepare(
        #     """
        #     INSERT INTO hordas (country, event_id, email, username)
        #     VALUES (?, ?, ?, ?)
        # """
        # )

        update_counter_stmt = session.prepare(
            """
            UPDATE hordas SET n_kills = n_kills + ?
            WHERE country = ? AND event_id = ? AND email = ? AND username = ?
        """
        )

        current_file_path = os.path.dirname(os.path.abspath(__file__))
        csv_file_path = os.path.join(current_file_path, "export/Hordas.csv")

        with open(csv_file_path, "r", encoding="utf-8") as csvfile:
            reader = csv.reader(csvfile)
            for row in reader:
                country, event_id, username, email, n_kills = row
                event_id = int(event_id)
                n_kills = int(n_kills)

                # Insert data except the counter
                # session.execute(insert_stmt, (country, event_id, email, username))

                # Update the counter
                session.execute(
                    update_counter_stmt, (n_kills, country, event_id, email, username)
                )

        print("Data import completed successfully.")
    finally:
        cluster.shutdown()


if __name__ == "__main__":
    main()
