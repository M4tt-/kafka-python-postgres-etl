"""
:author: mrunyon

Description
-----------

This module contains a classes for data sanitization.
"""

# %% IMPORTS
import re

from constants import DEFAULT_REPLACEMENT_CHAR

# %% CLASSES


class Formatter:
    """Useful for converting data formats."""

    @classmethod
    def format_data_label(self, data_label=None, sub=DEFAULT_REPLACEMENT_CHAR):
        """Format a data label to follow some convention.

        This will throw a TypeError if the supplied data_label is not str.

        Parameters:
            data_label (str): The nominal data label.
            sub (str): The string to substitute for non-alphanumeric chars.

        Returns:
            str: The formatted data label.
        """

        if not data_label.isidentifier():
            new_data_label = re.sub(r'\W+', sub, data_label)
            while new_data_label[0].isdigit():
                new_data_label = new_data_label[1:] + new_data_label[0]
            return new_data_label
        return data_label

    @classmethod
    def format_data_value(self, data_value):
        """Format a data value into the correct type.

        Parameters:
            data_value (Any): The data to format.

        Returns:
            Any: The type-casted data value.
        """

        if isinstance(data_value, str):
            if data_value.isdigit():
                return int(data_value)
            try:
                return float(data_value)
            except ValueError:
                return data_value
        return data_value
