class Expression:
    """Represents a regular expression and specify if its content must be found or not."""

    def __init__(self, expression, presence_needed, block=None):
        """Constructor.

        :param expression: The regular expression.
        :param presence_needed: A bool telling if the regular expression must be found.
        """
        self.expression = expression
        self.presence_needed = presence_needed
        self.block = block

    @staticmethod
    def unserializer(object):
        """The static method used to unserialize data from JSON to a Expression object.

        :param object: The object returned by the json.loads function.
        :return: A new Expression object containing the values passed in the object parameter.
        """
        if "block" in object:
            block = object["block"]
        else:
            block = None
        return Expression(object["expression"], object["presence_needed"] == "True", block)
