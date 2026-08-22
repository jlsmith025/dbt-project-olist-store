import kagglehub
import duckdb
from pathlib import Path
import pandas as pd
from faker import Faker

"""
Functions
"""
def download_olist_csvs_from_kaggle(olist_csv_target_path):
    """ 
        Download the latest version of the Olist Brazilian E-Commerce dataset from Kaggle. 
        force_download = True overwrites the data each run.
    """
    #path = 
    kagglehub.dataset_download(
        "olistbr/brazilian-ecommerce" # Kaggle Dataset Name
        , output_dir = olist_csv_target_path
        , force_download = True
    )

    print(f'\n' + '=' * 70 + f"\nOlist Data Downloaded to {olist_csv_target_path}\n" + '=' * 70 + '\n')

def generate_seller_name(seller_id: str, locale: str = "pt_BR") -> str:
    """
    Deterministically generate a fake name for a given seller_id.
    Since seller_id is the seed, Faker will generate the same seller name each time this is run
    """
    fake = Faker(locale)
    fake.seed_instance(str(seller_id))
    return fake.company()


def add_seller_names(df: pd.DataFrame) -> pd.DataFrame:
    """Add a seller_name column to the dataframe and populate it with Faker generated data."""
    df = df.copy()
    df["seller_name"] = df["seller_id"].apply(generate_seller_name)
    return df


def add_fake_seller_names_to_seller_data(input_file: Path) -> None:
    """Load the CSV, enrich with a fake seller name using Faker, and save the changes to the sellers CSV. Generate success message """
    df = pd.read_csv(input_file)
    df = add_seller_names(df)
    df.to_csv(input_file, index=False)
    print(f'\n' + '=' * 100 + f"\nAdded Faker generated seller company names to {input_file}\n" + '=' * 100 + '\n')

"""
Main Block
"""
if __name__ == '__main__':
    # Define variables
    olist_csv_target_path = r'Ingestion\olist dataset'
    sellers_csv_file = Path(r'Ingestion\olist dataset\olist_sellers_dataset.csv')

    # download the datasets from Kaggle
    download_olist_csvs_from_kaggle(olist_csv_target_path)

    # Enrich the sellers data file with a faker generated seller name
    add_fake_seller_names_to_seller_data(sellers_csv_file)