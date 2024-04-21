from cassandra.cluster import Cluster
import csv


def main():
    cluster = Cluster(["localhost"], port=9042)
    session = cluster.connect("dungeon")

    insert_stmt = session.prepare(
        """
        INSERT INTO hordas (country, event_id, email, username)
        VALUES (?, ?, ?, ?)
    """
    )

    update_counter_stmt = session.prepare(
        """
        UPDATE hordas SET n_kills = n_kills + ?
        WHERE country = ? AND event_id = ? AND email = ? AND username = ?
    """
    )

    with open("/csv/Hordas.csv", "r") as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            country, event_id, username, email, n_kills = row
            event_id = int(event_id)
            n_kills = int(n_kills)

            # Insert data except the counter
            session.execute(insert_stmt, (country, event_id, email, username))

            # Update the counter
            session.execute(
                update_counter_stmt, (n_kills, country, event_id, email, username)
            )

    print("Data import completed successfully.")
    cluster.shutdown()


if __name__ == "__main__":
    main()
