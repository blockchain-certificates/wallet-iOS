#!/usr/bin/env python3

import sys
import argparse
import json

class TColors:
    ESC = '\033['
    BLACK = ESC + '30'
    RED = ESC + '31'
    GREEN = ESC + '32'
    YELLOW = ESC + '33'
    BLUE = ESC + '34'
    PURPLE = ESC + '35'
    CYAN = ESC + '36'
    WHITE = ESC + '37'
    NONE = ESC + '0'
    DIMMED = ESC + '2'

    BACKGROUND_GREEN = '42'

    @staticmethod
    def build(color, background = None):
        return TColors.ESC + color + ';' + (background or '') + 'm'

class StaticText:
    APP_STARTED_HEADER = TColors.build(TColors.GREEN) + '<< -------------------------\n<<    Application Started\n<< -------------------------' + TColors.build(TColors.NONE)

class KeyActions:
    APP_LAUNCHED = 'Application was launched!'

class LogLevels:
    INFO = 'info'
    DEBUG = 'debug'
    WARNING = 'warning'
    ERROR = 'error'

def switch_log_level(level):
    return {
        LogLevels.INFO: (lambda log_message: info_string(log_message), 'I'),
        LogLevels.DEBUG: (lambda log_message: debug_string(log_message), 'D'),
        LogLevels.WARNING: (lambda log_message: warning_string(log_message), 'W'),
        LogLevels.ERROR: (lambda log_message: error_string(log_message), 'E'),
    }[level]

def check_search(search_terms, color, message):
    message_copy = message

    if search_terms == None:
        return message

    for search in search_terms:
        message_copy = message_copy.replace(search, TColors.build(TColors.BLACK, TColors.BACKGROUND_GREEN) + search + TColors.build(TColors.NONE) + color)

    return message_copy

def check_replacements(color, message):
    message_copy = message
    replacements = {
        'tapped': TColors.build(TColors.CYAN) + 'tapped' + TColors.build(TColors.NONE)
    }

    for key, value in replacements.items():
        message_copy = message_copy.replace(key, value + color)

    return message_copy

def main():
    parser = argparse.ArgumentParser(description='Display for logs.')
    parser.add_argument('--log', '-l', type=str, help='JSON log file to display')
    parser.add_argument('--search', '-s', type=str, help='values to be searched', nargs='+')
    args = parser.parse_args()

    json_file_path = args.log
    search = args.search

    if len(json_file_path) == "":
        sys.exit()
    with open(json_file_path, 'r') as json_file:
        json_object = json.load(json_file)

        for log_message in json_object:
            if KeyActions.APP_LAUNCHED in log_message['message']:
                print(StaticText.APP_STARTED_HEADER)

            color, level = switch_log_level(log_message['level'])
            color = color(log_message['message'])
            message = check_replacements(color, log_message['message'])
            message = check_search(search, color, message)
            tag = ""
            if 'tag' in log_message:
                tag = log_message['tag']
            else:
                tag = ""
            print_log(color + message + TColors.build(TColors.NONE), log_message['date'], tag, level)

def info_string(message):
    return TColors.build(TColors.NONE)

def debug_string(message):
    return TColors.build(TColors.BLUE)

def warning_string(message):
    return TColors.build(TColors.YELLOW)

def error_string(message):
    return TColors.build(TColors.RED)

def print_log(message, date, tag, level):
    print(TColors.build(TColors.DIMMED) + '<<', '[' + date + '] ' + level + ("" if len(tag) == 0 else "/" + tag) + ': ' + TColors.build(TColors.NONE) + message)

main()