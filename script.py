import psycopg2
import psycopg2.extras  # Import the extras module
from config import load_config
from connect import connect
import time
import random

table_name = "measurements_100M"
sql_insert_measurements = f"INSERT INTO {table_name} (name, feet, inches) VALUES %s;"
number_of_measurements_to_be_inserted = 100000000
page_size = 100000  # Number of records to insert per batch


def bulk_insert_measurements(measurements_to_insert):
    """
    Inserts a large batch of measurements into the database.
    """

    config = load_config()
    start_time = time.time()

    try:
        with connect(config) as conn:
            with conn.cursor() as cur:
                print(f"Inserting {len(measurements_to_insert)} measurements...")
                psycopg2.extras.execute_values(
                    cur,
                    sql_insert_measurements,
                    measurements_to_insert,
                    page_size=page_size,
                )
            measurement_insert_end_time = time.time()
            print(
                f"Transaction committed in {measurement_insert_end_time - start_time:.2f} seconds."
            )

    except (Exception, psycopg2.DatabaseError) as error:
        print(f"Database error: {error}")
        return


def changing_measurements_schema():
    config = load_config()

    try:
        start_time = time.time()
        with connect(config) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SET statement_timeout = 300000;"
                )  # 5 minutes in milliseconds
                cur.execute(f"ALTER TABLE {table_name} ADD COLUMN total_inches int;")
                cur.execute(
                    f"UPDATE {table_name} SET total_inches = (feet * 12) + inches;"
                )
        end_time = time.time()
        print(f"Schema changed successfully in {end_time - start_time:.2f} seconds.")
    except (Exception, psycopg2.DatabaseError) as error:
        print(f"Database error: {error}")
        return


if __name__ == "__main__":

    batch_size = page_size
    total_time = 0

    for _ in range(number_of_measurements_to_be_inserted // batch_size):
        start_time = time.time()
        measurements_to_add = [
            (f"Name {i+1}", random.randint(1, 10), random.randint(0, 11))
            for i in range(batch_size)
        ]
        bulk_insert_measurements(measurements_to_add)
        end_time = time.time()
        total_time += end_time - start_time

    print("--------------------------------------------------")
    print(f"Total time taken for bulk inserting measurements: {total_time:.2f} seconds")
    print(
        f"Average time per batch: {total_time / (number_of_measurements_to_be_inserted // batch_size):.3f} seconds"
    )
    print(
        f"Records per second: {number_of_measurements_to_be_inserted / total_time:,.0f}"
    )
    print("--------------------------------------------------")

    start_time = time.time()
    changing_measurements_schema()
    end_time = time.time()

    print(
        f"Total time taken for changing measurements schema: {end_time - start_time:.2f} seconds"
    )
    print("--------------------------------------------------")
