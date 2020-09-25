from enum import Enum


class ServerType(Enum):
    """Define the enumeration of server type supported by the tool."""

    APACHE = 1
    TOMCAT = 2
    IIS = 3
