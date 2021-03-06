import os
import traceback
import json

import requests
import awswrangler as wr
import pandas as pd

URL_FORMAT = "http://api.bcb.gov.br/dados/serie/bcdata.sgs.{}/dados"


def lambda_handler(event=None, context=None):
    try:
        if context:
            bucket_name = os.getenv("S3_BUCKET_NAME")
        else:
            bucket_name = "sgs-extract"
        codigos = event["codigos"]
        for codigo in codigos:
            response = requests.get(URL_FORMAT.format(int(codigo))).json()
            df = pd.DataFrame(response)
            wr.s3.to_json(df=df, path=f"s3://{bucket_name}/{codigo}.json")

        return {'status': True,
                'body': 'sucess',
                "event": event}

    except Exception:
        raise Exception(json.dumps(
            {
                "event": event,
                "body": traceback.format_exc()
            }
        )
        )


if __name__ == "__main__":
    lambda_handler(event={"codigos": list(range(21388, 21396))}, context=False)
