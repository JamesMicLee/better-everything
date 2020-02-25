import argparse
import json
import yaml

parser = argparse.ArgumentParser(description='Checks if a file is formatted correctly for yaml.')  # noqa: E501
parser.add_argument('yaml_file', metavar='N', type=str, nargs=1,
                    help='an filename to check for yaml')

args = parser.parse_args()
yaml_file = getattr(args, 'yaml_file')[0]


# read the yaml
stream = open(yaml_file, 'r')
parsed = yaml.safe_load(stream)
stream.close()
print(yaml.dump(parsed, explicit_start=True))

# write out some json
pretty_json = json.dumps(parsed, indent=4, sort_keys=True)
print(pretty_json)
