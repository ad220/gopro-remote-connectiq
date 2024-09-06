import sys
import glob

def extract_word(line:str): 
    return line.split('<')[1].split('>')[1]

def filter(filename:str):
    with open(filename, 'r', encoding="utf-8") as f:
        lines = f.readlines()
        filter_string = ""
        global_filter = ""
        for line in lines:
            if 'string id' in line:
                word = extract_word(line)
                if 'translatable="false"' in line:
                    global_filter += word
                else:
                    filter_string += word
    return "".join(sorted(set(filter_string))), "".join(sorted(set(global_filter)))



def filter_all(rootpath):
    files = glob.glob('**/strings.xml', recursive=True)
    filter_dict = {}
    global_filter = ""
    easy_filter = ""
    for f in files:
        tmp_filter, tmp_global_filter = filter(f)
        filter_dict[f] = tmp_filter
        global_filter += tmp_global_filter
        easy_filter += tmp_filter + tmp_global_filter
    for f in files:
        filter_dict[f] = "".join(sorted(set(filter_dict[f] + global_filter)))
    filter_dict['global'] = "".join(sorted(set(easy_filter)))

    return filter_dict


if __name__ == '__main__':
    print(filter_all(sys.argv[1]))