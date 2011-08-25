#!/usr/bin/env python

sdict = dict(
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
#    license = 'MIT',
    classifiers=[
        'Programming Language :: Python',
#        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Topic :: Software Development :: Libraries :: Python Modules',
    ],
    install_requires = [],
)

from distutils.core import setup
setup(**sdict)