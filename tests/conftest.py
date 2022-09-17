#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""

:author: mrunyon

Description: pytest config file.
"""

# %% IMPORTS

import pytest

# %% CONSTANTS

DEFAULT_CONFIG = "tests/test_config.json"

# %% FUNCTIONS AND FIXTURES

def pytest_addoption(parser):
    parser.addoption("--conf", action="store", default=DEFAULT_CONFIG,
                     help='full path to config file (.json)')

@pytest.fixture(scope='session')
def conf(request):
    return request.config.getoption("--conf")
