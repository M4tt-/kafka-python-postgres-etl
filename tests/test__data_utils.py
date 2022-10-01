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
from data_utils import (Formatter, SqlQueryBuilder)

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

    def test_11_deformat_url_query(self):
        """Ensure a URL query string gets deformatted into a dict of lists."""
        test_obj = "timestamp=1664624846.762738&make=Ford&model=Explorer&" \
                   "position=0.004990763058979908&position=" \
                   "2.4563888155285308e-05&position=0.004508130855317203" \
                   "&speed=2.134912508024945&vin=GD9KE1GANAGOCJ64E"
        result = Formatter.deformat_url_query(test_obj)
        assert isinstance(result, dict)
        for key, value in result.items():
            assert isinstance(key, str)
            assert isinstance(value, list)

    def test_12_deformat_url_query(self):
        """Ensure a URL query string gets deformatted into a dict of lists."""
        test_obj = "timestamp=1664046446.939104&make=Ford&model=F-150&" \
                   "position=1&position=2&position=3&speed=85.6&" \
                   "vin=ABCDEF0123456789J"
        result = Formatter.deformat_url_query(test_obj)
        assert isinstance(result, dict)
        for key, value in result.items():
            assert isinstance(key, str)
            assert isinstance(value, list)


class TestSqlQueryBuilder:
    """Test the class methods of Formatter."""

    def test_01_insert_from_dict(self):
        """Ensure a dict gets formatted into a proper Sql insert."""
        test_obj = {'field1': 'value1',
                    'field2': 'value2',
                    'field3': 'value3'}
        test_table = "av_streaming"
        expected_result = f"INSERT INTO {test_table} (field1,field2,field3)" \
                          f" VALUES ('value1','value2','value3')"
        actual_result = SqlQueryBuilder.insert_from_dict(dict=test_obj,
                                                         table=test_table)
        assert expected_result == actual_result

    def test_02_insert_from_dict(self):
        """Ensure a dict gets formatted into a proper Sql insert."""
        test_obj = {'timestamp': ['1664624846.762738'],
                    'make': ['Ford'],
                    'model': ['Explorer'],
                    'position': ['0.004990763058979908',
                                 '2.4563888155285308e-05',
                                 '0.004508130855317203'],
                    'speed': ['2.134912508024945'],
                    'vin': ['GD9KE1GANAGOCJ64E']}
        test_table = "av_streaming"
        expected_result = f"INSERT INTO {test_table} (timestamp,make," \
                          f"model,position,speed,vin) VALUES (" \
                          f"1664624846.762738,'Ford','Explorer'," \
                          f"'(0.004990763058979908,2.4563888155285308e-05," \
                          f"0.004508130855317203)',2.134912508024945," \
                          f"'GD9KE1GANAGOCJ64E')"
        actual_result = SqlQueryBuilder.insert_from_dict(dict=test_obj,
                                                         table=test_table)
        assert expected_result == actual_result

    #@pytest.mark.skip(reason="Rework to use position_x, position_y, etc.")
    def test_03_insert_from_dict(self):
        """Ensure a dict gets formatted into a proper Sql insert."""
        test_obj = {'timestamp': ['1664624846.762738'],
                    'make': ['Ford'],
                    'model': ['Explorer'],
                    'position_x': ['0.004990763058979908'],
                    'position_y': ['2.4563888155285308e-05'],
                    'position_z': ['0.004508130855317203'],
                    'speed': ['2.134912508024945'],
                    'vin': ['GD9KE1GANAGOCJ64E']}
        test_table = "av_streaming"
        expected_result = f"INSERT INTO {test_table} (timestamp,make," \
                          f"model,position_x,position_y,position_z,speed,vin) VALUES (" \
                          f"1664624846.762738,'Ford','Explorer'," \
                          f"0.004990763058979908,2.4563888155285308e-05," \
                          f"0.004508130855317203,2.134912508024945," \
                          f"'GD9KE1GANAGOCJ64E')"
        actual_result = SqlQueryBuilder.insert_from_dict(dict=test_obj,
                                                         table=test_table)
        assert expected_result == actual_result
