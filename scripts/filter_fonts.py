import sys
import glob


def sort_filter(filter):
    return "".join(sorted(set("".join(filter))))


def extract_word(line:str): 
    return line.split('<')[1].split('>')[1]


def filter(filename:str):
    with open(filename, 'r', encoding="utf-8") as f:
        lines = f.readlines()
        tiny_filter = []
        small_filter = []
        medium_filter = []
        current_filters = []
        for line in lines:
            if '$$$' in line:
                current_filters = []
                if 'Tiny' in line:
                    current_filters.append(tiny_filter)
                if 'Small' in line:
                    current_filters.append(small_filter)
                if 'Medium' in line:
                    current_filters.append(medium_filter)

            if 'string id' in line:
                word = extract_word(line)
                for filter in current_filters:
                    filter += word

    return sort_filter(tiny_filter), sort_filter(small_filter), sort_filter(medium_filter)


def filter_all(rootpath):
    files = glob.glob('**/strings.xml', root_dir=rootpath, recursive=True)
    filter_dict = {
        "tiny": "",
        "small": "",
        "medium": ""
    }
    for f in files:
        filters = filter(f)
        filter_dict["tiny"] = "".join(sorted(set(filter_dict["tiny"] + filters[0])))
        filter_dict["small"] = "".join(sorted(set(filter_dict["small"] + filters[1])))
        filter_dict["medium"] = "".join(sorted(set(filter_dict["medium"] + filters[2])))

    return filter_dict


if __name__ == '__main__':
    print(filter_all(sys.argv[1]))