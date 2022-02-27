#!/usr/bin/env python3
from argparse import ArgumentParser
import yaml


NAME_CONFIG_YAML = "./fausto/single_test/config.yaml"

def get_parser():
    parser = ArgumentParser()
    parser.add_argument('template', help='Template configuration', type=str)
    parser.add_argument('-r', help='Kafka rate', nargs='+', type=int, required=True)
    parser.add_argument('-v', help='Variants used (OS, LACHESIS, RANDOM)', nargs='+', type=str, choices=['OS', 'LACHESIS', 'RANDOM'], required=True)
    return parser

def load_config(path):
    with open(path, 'r') as file:
        return yaml.load('\n'.join(file.readlines()), Loader=yaml.CLoader)

def write_config(path, config):
    with open(path, 'w') as file:
        file.write(yaml.dump(config, indent=4))

if __name__ == "__main__":

    parser, unknown_args = get_parser().parse_known_args()
    rate = list(set(parser.r))
    variants_in = list(set(parser.v))

    template = load_config(parser.template)
    template['dimensions']['rate'] = rate

    variants = [variant["name"] for variant in template['variants']]
    template['variants'] = [variant for variant in template['variants'] if variant["name"] in variants_in]

    
    write_config(NAME_CONFIG_YAML, template)
