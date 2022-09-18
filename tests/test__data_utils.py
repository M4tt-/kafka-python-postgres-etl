"""
:author: mrunyon

Description
-----------

Unit tests for data_utils.py.

Usage
-----

From the command line, navigate to the repo root and execute::

    python -m pytest tests/test__data_utils.py -v
"""
# pylint: disable=R0201
# %% IMPORTS
import pytest

import set_paths       # pylint: disable=W0611
from data_utils import Formatter

# %% TESTS


class TestFormatter:
    """Test the class methods of Formatter."""

    def test_01_format_data_value_str_to_float(self):
        """Ensure the data value is formatted as expected."""
        test_obj = '1.5'
        expected_obj = 1.5
        actual_obj = Formatter.format_data_value(test_obj)
        assert expected_obj == actual_obj

    def test_02_format_data_value_str_to_int(self):
        """Ensure the data value is formatted as expected."""
        test_obj = '1'
        expected_obj = 1
        actual_obj = Formatter.format_data_value(test_obj)
        assert expected_obj == actual_obj

    def test_03_format_data_value_str_to_str(self):
        """Ensure the data value is formatted as expected."""
        test_obj = 'string'
        expected_obj = 'string'
        actual_obj = Formatter.format_data_value(test_obj)
        assert expected_obj == actual_obj

    def test_04_format_data_value_int_to_int(self):
        """Ensure the data value is formatted as expected."""
        test_obj = -5
        expected_obj = -5
        actual_obj = Formatter.format_data_value(test_obj)
        assert expected_obj == actual_obj

    def test_05_format_data_value_float_to_float(self):
        """Ensure the data value is formatted as expected."""
        test_obj = -5.87
        expected_obj = -5.87
        actual_obj = Formatter.format_data_value(test_obj)
        assert expected_obj == actual_obj

    def test_06_format_data_label(self):
        """Ensure the data label is formatted as expected."""
        test_obj = "a regular str"
        expected_obj = "a_regular_str"
        actual_obj = Formatter.format_data_label(test_obj)
        assert expected_obj == actual_obj

    def test_07_format_data_label(self):
        """Ensure the data label is formatted as expected."""
        test_obj = "a~different!str)with`interesting+non alphanum^chars/"
        expected_obj = "a_different_str_with_interesting_non_alphanum_chars_"
        actual_obj = Formatter.format_data_label(test_obj)
        assert expected_obj == actual_obj

    def test_08_format_data_label(self):
        """Ensure the data label is formatted as expected."""
        test_obj = -18
        with pytest.raises(AttributeError):
            Formatter.format_data_label(test_obj)

    def test_09_format_data_label(self):
        """Ensure the data label is formatted as expected."""
        test_obj = "0almost_a_valid_label"
        expected_obj = "almost_a_valid_label0"
        actual_obj = Formatter.format_data_label(test_obj)
        assert expected_obj == actual_obj

    def test_10_format_data_label(self):
        """Ensure the data label is formatted as expected."""
        test_obj = "0124almost_a_valid_label"
        expected_obj = "almost_a_valid_label0124"
        actual_obj = Formatter.format_data_label(test_obj)
        assert expected_obj == actual_obj
