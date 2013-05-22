#!/usr/bin/env python

from distutils.core import setup

setup(
    name = 'KISSmetrics',
    packages = ['KISSmetrics'],
    version = '0.1.0',
    description = 'Python client for KISSmetrics',
    long_description = 'Python client for KISSmetrics',
    url = 'http://github.com/kissmetrics/KISSmetrics',
    author = 'kissmetrics',
    author_email = 'support@kissmetrics.com',
    maintainer = 'kissmetrics',
    maintainer_email = 'support@kissmetrics.com',
    keywords = ['kissmetrics'],
    license = 'Apache Software License',
    classifiers=[
        'Programming Language :: Python',
        'License :: OSI Approved :: Apache Software License',
        'Operating System :: OS Independent',
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Topic :: Software Development :: Libraries :: Python Modules',
    ],
    install_requires = [],
)

