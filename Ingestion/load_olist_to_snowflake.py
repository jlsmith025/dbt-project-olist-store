import logging
from pathlib import Path

import pandas as pd
import snowflake.connector
from tabulate import tabulate

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(levelname)-8s %(message)s")
log = logging.getLogger(__name__)

# Resolve to an absolute path so behavior doesn't depend on the caller's cwd.
OLIST_CSV_DIRECTORY = Path(r"Ingestion\olist dataset").resolve()
DATABASE = "RAW"
SCHEMA = "OLIST"
STAGE_NAME = "olist_python_load_stage"
LOAD_FORMAT_NAME = "LOAD_CSV_FORMAT"


def setup_snowflake_objects(cursor) -> None:
    """Create the file format and stage the ingestion depends on."""
    cursor.execute(f"USE DATABASE {DATABASE}")
    cursor.execute(f"USE SCHEMA {SCHEMA}")

    cursor.execute(f"""
        CREATE FILE FORMAT IF NOT EXISTS {DATABASE}.{SCHEMA}.{LOAD_FORMAT_NAME}
            TYPE = CSV
            SKIP_HEADER = 1
            FIELD_OPTIONALLY_ENCLOSED_BY = '"';
    """)

    cursor.execute(f"CREATE STAGE IF NOT EXISTS {STAGE_NAME}")


def table_name_from_file(file: Path) -> str:
    """Derive the target table name from a CSV filename."""
    return file.stem.replace("olist_", "").replace("_dataset", "").upper()


def ingest_file(cursor, file: Path) -> dict:
    """PUT one CSV to the stage and COPY it into its table.

    Returns a result dict for the summary report. Snowflake errors are
    caught here so a single bad file becomes one FAILED row in the summary 
    instead of an unhandled exception that aborts the rest of the process.
    """
    table_name = table_name_from_file(file)
    log.info("Processing %s -> %s", file.name, table_name)

    try:
        cursor.execute(f"""
            PUT 'file://{file.as_posix()}'
            @{STAGE_NAME}
            AUTO_COMPRESS=TRUE
            OVERWRITE=FALSE
        """)

        # Point COPY at the stage with a pattern matching this file's stem
        cursor.execute(f"""
            COPY INTO {table_name}
            FROM @{STAGE_NAME}
            PATTERN = '.*{file.stem}.*'
            FILE_FORMAT = '{DATABASE}.{SCHEMA}.{LOAD_FORMAT_NAME}'
            ON_ERROR = 'CONTINUE'
        """)
        # ON_ERROR='CONTINUE' logs bad rows and keeps loading the rest of
        # the file instead of aborting the whole file on the first bad
        # row (Snowflake's default).

        copy_results = cursor.fetchall()
        columns = [c[0] for c in cursor.description] if cursor.description else []

    except snowflake.connector.errors.ProgrammingError as e:
        # Catch here so we know exactly which file/table failed 
        # and can keep going with the rest of the batch.
        log.error("Failed to ingest %s: %s", file.name, e)
        return {
            "file": file.name,
            "table": table_name,
            "status": "ERROR",
            "rows_parsed": 0,
            "rows_loaded": 0,
        }

    if not copy_results:
        log.warning("No COPY result returned for %s", file.name)
        return {
            "file": file.name,
            "table": table_name,
            "status": "UNKNOWN",
            "rows_parsed": 0,
            "rows_loaded": 0,
        }

    row = copy_results[0]

    def get_column(name, default=None):
        """ Check the column names Snowflake returned to see if the file was skipped """
        if name not in columns:
            return default
        return row[columns.index(name)]

    status = get_column("status", default="SKIPPED")
    rows_parsed = get_column("rows_parsed", default=0)
    rows_loaded = get_column("rows_loaded", default=0)

    return {
        "file": file.name,
        "table": table_name,
        "status": status,
        "rows_parsed": rows_parsed,
        "rows_loaded": rows_loaded,
    }


def run_ingestion(cursor, csv_directory: Path) -> list[dict]:
    """Run setup once, then ingest every CSV in the directory."""
    setup_snowflake_objects(cursor)

    results = []
    for file in sorted(csv_directory.glob("*.csv")):
        results.append(ingest_file(cursor, file))
    return results


def print_summary(results: list[dict]) -> None:
    """Print and return a DataFrame summary of the run."""
    results_df = pd.DataFrame(results)

    print("\nLoad Summary:")
    print(tabulate(results_df, headers="keys", tablefmt="simple_outline", showindex=False))

    return results_df


def main() -> None:
    conn = snowflake.connector.connect(connection_name="olist_raw")
    cursor = conn.cursor()

    try:
        results = run_ingestion(cursor, OLIST_CSV_DIRECTORY)
    finally:
        cursor.close()
        conn.close()

    if results:
        print_summary(results)
    else:
        log.warning("No CSV files found in %s", OLIST_CSV_DIRECTORY)


if __name__ == "__main__":
    main()