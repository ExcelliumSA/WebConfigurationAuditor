from enum import Enum


class Severity(Enum):
    """Define the enumeration of message severity."""

    ERROR = 1
    WARN = 2
    INFO = 3
    DEBUG = 4
