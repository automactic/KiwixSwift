import os
import argparse
import re
import subprocess
import glob
from pathlib import Path

# example usage:
# python localizations.py Support/en.lproj/Localizable.strings generate

parser = argparse.ArgumentParser()
parser.add_argument('input_file', type=argparse.FileType('r'), nargs=1, help='Localizable.strings file')
parser.add_argument('command', type=str, help="Possible options: generate or validate")
parser.add_argument('--target-dir', type=str, help='Target directory to write the generated swift file to, defaults to Support', default='Support')
arguments = parser.parse_args()

input_file = arguments.input_file[-1]
enum_name = "LocalString"
target_dir = arguments.target_dir
command = arguments.command
if command not in ['generate', 'validate']:
    parser.print_help()
    exit()

class Generate:
    def __init__(self, input_file_name, enum_name, target_dir):
        self.enum_name = enum_name
        reader = Reader(input_file_name)
        vars = self.__variables(reader)
        
        output_path = os.path.join(target_dir, enum_name + ".swift")
        file = open(output_path, 'w')
        file.write(self.__code_for("\n\t".join(vars)))
        file.close()
        
    def __variables(self, reader):
        vars = list()
        for key, has_arguments in sorted(reader.keys()):
            if has_arguments:
                vars.append(self.__static_func_for(key))
            else:
                vars.append(self.__static_let_for(key))
        return vars
    
    def __code_for(self, variables):
        return """
enum {} {{
    {}
}}
""".format(self.enum_name, variables)

    def __static_let_for(self, key):
        return """static let {} = "{}".localized""".format(self.__get_var_name(key), key)
    
    def __static_func_for(self, key):
        return """static func {}(withArgs: CVarArg...) -> String {{ "{}".localizedWithFormat(withArgs) }}""".format(self.__get_var_name(key), key)

    def __get_var_name(self, key):
        return re.sub('[^a-z0-9]', '_', key.lower())
    

class Reader:
    def __init__(self, input_file_name):
        self.input_file_name = input_file_name

    def keys(self):
        pattern = re.compile(r'"(?P<key>.+)" = "(?P<value>.+)"')
        for line in self.input_file_name:
            match = pattern.match(line)
            if match:
                groups = match.groupdict()
                key = groups.get('key')
                value = groups.get('value')
                has_arguments = "%@" in value
                yield key, has_arguments

class Validate:
    def __init__(self, input_file_name, enum_name, search_directory=os.getcwd()):
        reader = Reader(input_file_name)
        vars = list()
        for key, _ in reader.keys():
            vars.append(key)
        vars = sorted(vars)
        
        matches = dict()
        for swift_file_name in glob.iglob(os.path.join(search_directory, '**/*.swift'), recursive=True):
            if Path(swift_file_name).suffix != "{}.swift".format(enum_name):
                with open(swift_file_name, 'r') as swift_file:
                    content = swift_file.read()
                    for var in vars:
                        if var in content:
                            if var in matches:
                                matches[var].append(swift_file_name)
                            else:
                                matches[var] = []     
        print(matches)
        assert len(matches.keys()) == 0, "localization strings are still used in: {}".format(matches)

match command:
    case "generate":
        Generate(input_file, enum_name, target_dir)
    case "validate":
        Validate(input_file, enum_name)
    case _:
        exit(-1)