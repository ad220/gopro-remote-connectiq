import sys
import glob

HEIGHT_IDENTIFIER = "eight="
YOFFSET_IDENTIFIER = "yoffset="

def extract_value(line:str, value): 
    return int(line.split(value)[1].split(' ')[0])

def fix_value(line:str, value:str, offset:int):
    base_height = extract_value(line, value)
    value_index = line.index(value) + len(value)
    return line[:value_index] + f"{base_height - offset:02d}" + line[value_index+2:]


def fix_file(filename:str):
    with open(filename, 'r', encoding="utf-8") as f:
        lines = f.readlines()

    height_list = []
    base_height = -1

    for i in range(len(lines)):
        if 'lineHeight' in lines[i]:
            base_height = extract_value(lines[i], HEIGHT_IDENTIFIER)

        if 'char id' in lines[i]:
            height_list.append(extract_value(lines[i], HEIGHT_IDENTIFIER))

    new_height = max(height_list)
    if (base_height==-1):
        raise Exception()
    height_offset = int((base_height-new_height)*0.666)
    print(base_height, new_height, height_offset)

    
    for i in range(len(lines)):
        if 'lineHeight' in lines[i]:
            lines[i] = fix_value(lines[i], HEIGHT_IDENTIFIER, base_height-new_height)

        if 'char id' in lines[i]:
            lines[i] = fix_value(lines[i], YOFFSET_IDENTIFIER, height_offset)
    
    with open(filename[:-4] + "_fix" + filename[-4:], 'w', encoding="utf-8") as f:
        f.writelines(lines)
        



def fix_all(rootpath):
    files = glob.glob('*.fnt', root_dir=rootpath, recursive=True)
    print(files)
    for f in files:
        if not "_fix" in f:
            fix_file(rootpath+f)


if __name__ == '__main__':
    fix_all(sys.argv[1])