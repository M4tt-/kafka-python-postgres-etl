"""
:author: mrunyon

Description
-----------

This module contains a classes for data sanitization.
"""

# %% IMPORTS
from urllib.parse import parse_qs
import re

from constants import DEFAULT_REPLACEMENT_CHAR

# %% CLASSES


class Formatter:
    """Useful for converting data formats."""

    @classmethod
    def deformat_url_query(cls, query_string, **kwargs):
        """Deformat a query string from URL.

        This will throw a TypeError if the supplied data_label is not str.

        Parameters:
            query_string (str): The URL query string.
            kwargs (dict): The urllib.parse.parse_qs kwargs.

        Returns:
            str: The formatted data label.
        """

        return parse_qs(query_string, **kwargs)

    @classmethod
    def format_data_label(cls, data_label=None, sub=DEFAULT_REPLACEMENT_CHAR):
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
    def format_data_value(cls, data_value):
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


class SqlQueryBuilder:
    """Builds SQL queries from various data structures."""

    @classmethod
    def insert_from_dict(cls, ins_dict=None, table=None):
        """Format a dictionary into Sql insert string.

        The keys of the dictionary are the column names and the values are the
        values

        Parameters:
            ins_dict (dict): The dict to insert.
            table (str): The table to insert into.

        Returns:
            str: The SQL INSERT string.
        """

        columns_str = "("
        values_str = "("
        for key, value in ins_dict.items():
            columns_str += f"{key},"
            if isinstance(value, list):
                if len(value) == 1:
                    formatted_value = Formatter.format_data_value(value[0])
                    if isinstance(formatted_value, str):
                        formatted_value = f"'{formatted_value}'"
                else:   # convert to str and use parentheses rather than brackets
                    formatted_value = "'("
                    for subvalue in value:
                        formatted_subvalue = Formatter.format_data_value(subvalue)
                        formatted_value += f"{formatted_subvalue},"
                    formatted_value = formatted_value[0:-1] + ")'"
            else:
                formatted_value = Formatter.format_data_value(value)
                if isinstance(value, str):
                    formatted_value = f"'{formatted_value}'"
            values_str += f"{formatted_value},"

        columns_str = columns_str[0:-1] + ")"
        values_str = values_str[0:-1] + ")"
        insert_str = f"INSERT INTO {table} {columns_str} VALUES {values_str}"
        print(columns_str)
        print(values_str)
        print(insert_str)
        return insert_str
