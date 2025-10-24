import sys
import glob

TINY_SPECIAL_CHAR = ".Kp:°@%0123456789"
SMALL_SPECIAL_CHAR = ".Kp:°0123456789"
MEDIUM_SPECIAL_CHAR = "i!0123456789"


def sort_filter(filter):
    return "".join(sorted(set("".join(filter))))


def extract_word(line:str): 
    label = line.split('<')[1].split('>')[1]
    return "".join(label.split("\\n"))


def filter(filename:str, translatable:bool):
    with open(filename, 'r', encoding="utf-8") as f:
        lines = f.readlines()
        tiny_filter = [TINY_SPECIAL_CHAR]
        small_filter = [SMALL_SPECIAL_CHAR]
        medium_filter = [MEDIUM_SPECIAL_CHAR]
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
                if translatable != ('translatable="false"' in line):
                    word = extract_word(line)
                    for filter in current_filters:
                        filter += word

    return sort_filter(tiny_filter), sort_filter(small_filter), sort_filter(medium_filter)


def filter_all(rootpath):
    files = glob.glob('**/strings.xml', root_dir=rootpath, recursive=True)

    not_translatables = filter(files[0], False)
    global_filter = [f for f in not_translatables]
    for f in files:
        filters = filter(f, True)
        print(f, {
            "tiny":     sort_filter(filters[0]+not_translatables[0]),
            "small":    sort_filter(filters[1]+not_translatables[1]),
            "medium":   sort_filter(filters[2]+not_translatables[2])
        })
        for i in range(3):
            global_filter[i] = sort_filter(filters[i]+global_filter[i])
    print("global", {
        "tiny":     global_filter[0],
        "small":    global_filter[1],
        "medium":   global_filter[2]
    })


if __name__ == '__main__':
    filter_all(sys.argv[1])