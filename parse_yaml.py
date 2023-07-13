import sys
import yaml

def main():
    if len(sys.argv) != 3:
        print('Usage: python parse_yaml.py <yaml_file> <key>')
        return

    file_path = sys.argv[1]
    key = sys.argv[2]

    with open(file_path) as file:
        data = yaml.safe_load(file)

    if key in data:
        if isinstance(data[key], list):
            for item in data[key]:
                print(item)
        else:
            print(data[key])

if __name__ == "__main__":
    main()
