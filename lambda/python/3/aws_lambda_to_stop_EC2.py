import boto3
import datetime
import json

from datetime import datetime as datetime  # noqa: F811


class CustomDateTimeEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, datetime):
            return o.isoformat()
        return json.JSONEncoder.default(self, o)


def lambda_handler(event, context):
    client = boto3.client('ec2')
    response = client.describe_instances(
      DryRun=False,
      MaxResults=123
    )
    InstanceIds = []
    for x in response["Reservations"]:
        for y in x['Instances']:
            print(y['InstanceId'], y['State']['Name'])
            if y['State']['Name'] == "running":
                InstanceIds.append(y['InstanceId'])
    if len(InstanceIds) != 0:
        response = client.stop_instances(
          InstanceIds=InstanceIds,
          Hibernate=False,
          DryRun=False,
          Force=False
        )
    else:
        print("No instances found running...")
    return {
      'statusCode': 200,
      'body': json.dumps(response, cls=CustomDateTimeEncoder,
                         sort_keys=True, indent=4, separators=(',', ': '))
    }
