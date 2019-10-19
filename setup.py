#!/usr/bin/env python
from __future__ import absolute_import, division, print_function
import sys
import skbuild
from os.path import exists
from collections import OrderedDict


def parse_long_description(fpath='README.rst'):
    """
    Better than using open.read directly for source installs work
    """
    # ONLY WORKS IN A SPECIFIC DIRECTORY
    candidates = [fpath]
    for fpath in candidates:
        if exists(fpath):
            return open(fpath, 'r').read()
    return ''


def parse_requirements(fname='requirements.txt'):
    """
    Parse the package dependencies listed in a requirements file but
    strips specific versioning information.

    CommandLine:
        python -c "import setup; print(setup.parse_requirements())"
    """
    import re
    require_fpath = fname

    def parse_line(line):
        """
        Parse information from a line in a requirements text file
        """
        if line.startswith('-r '):
            # Allow specifying requirements in other files
            target = line.split(' ')[1]
            for info in parse_require_file(target):
                yield info
        elif line.startswith('-e '):
            info = {}
            info['package'] = line.split('#egg=')[1]
            yield info
        else:
            # Remove versioning from the package
            pat = '(' + '|'.join(['>=', '==', '>']) + ')'
            parts = re.split(pat, line, maxsplit=1)
            parts = [p.strip() for p in parts]

            info = {}
            info['package'] = parts[0]
            if len(parts) > 1:
                op, rest = parts[1:]
                if ';' in rest:
                    # Handle platform specific dependencies
                    # http://setuptools.readthedocs.io/en/latest/setuptools.html#declaring-platform-specific-dependencies
                    version, platform_deps = map(str.strip, rest.split(';'))
                    info['platform_deps'] = platform_deps
                else:
                    version = rest  # NOQA
                info['version'] = (op, version)
            yield info

    def parse_require_file(fpath):
        with open(fpath, 'r') as f:
            for line in f.readlines():
                line = line.strip()
                if line and not line.startswith('#'):
                    for info in parse_line(line):
                        yield info

    # This breaks on pip install, so check that it exists.
    packages = []
    if exists(require_fpath):
        for info in parse_require_file(require_fpath):
            package = info['package']
            if not sys.version.startswith('3.4'):
                # apparently package_deps are broken in 3.4
                platform_deps = info.get('platform_deps')
                if platform_deps is not None:
                    package += ';' + platform_deps
            packages.append(package)
    return packages


def parse_authors():
    """
    Parse the git authors of a repo

    Returns:
        List[str]: list of authors

    CommandLine:
        python -c "import setup; print(setup.parse_authors())"
    """
    import subprocess
    try:
        output = subprocess.check_output(['git', 'shortlog', '-s'],
                                         universal_newlines=True)
    except Exception as ex:
        print('ex = {!r}'.format(ex))
        return []
    else:
        striped_lines = (l.strip() for l in output.split('\n'))
        freq_authors = [line.split(None, 1) for line in striped_lines if line]
        freq_authors = sorted((int(f), a) for f, a in freq_authors)[::-1]
        # keep authors with uppercase letters
        authors = [a for f, a in freq_authors if a.lower() != a]
        return authors


try:
    class EmptyListWithLength(list):
        def __len__(self):
            return 1

        def __repr__(self):
            return 'EmptyListWithLength()'

        def __str__(self):
            return 'EmptyListWithLength()'
except Exception:
    raise RuntimeError('FAILED TO ADD BUILD CONSTRUCTS')


def get_lib_ext():
    if sys.platform.startswith('win32'):
        ext = '.dll'
    elif sys.platform.startswith('darwin'):
        ext = '.dylib'
    elif sys.platform.startswith('linux'):
        ext = '.so'
    else:
        raise Exception('Unknown operating system: %s' % sys.platform)
    return ext

GIT_AUTHORS = parse_authors()


NAME = 'pyflann'
VERSION = '1.10.0'  # TODO: parse
AUTHORS = ['Marius Muja'] + GIT_AUTHORS
AUTHOR_EMAIL = 'mariusm@cs.ubc.ca'
URL = 'http://www.cs.ubc.ca/~mariusm/flann/'
LICENSE = 'BSD'
DESCRIPTION = 'FLANN - Fast Library for Approximate Nearest Neighbors'


KWARGS = OrderedDict(
    name=NAME,
    version=VERSION,
    author=', '.join(AUTHORS[0:1]),
    author_email=AUTHOR_EMAIL,
    description=DESCRIPTION,
    long_description=parse_long_description('README.md'),
    long_description_content_type='text/markdown',
    url=URL,
    license=LICENSE,
    install_requires=parse_requirements('requirements/runtime.txt'),
    extras_require={
        'all': parse_requirements('requirements.txt'),
        'tests': parse_requirements('requirements/tests.txt'),
        'build': parse_requirements('requirements/build.txt'),
        'runtime': parse_requirements('requirements/runtime.txt'),
    },

    # --- PACKAGES ---
    # The combination of packages and package_dir is how scikit-build will
    # know that the cmake installed files belong in the pyflann module and
    # not the data directory.
    packages=[
        'pyflann',
        # These are generated modules that will be created via build
        'pyflann.lib',
    ],
    package_dir={
        'pyflann': 'pyflann',
        # Note: this requires that FLANN_LIB_INSTALL_DIR is set to pyflann/lib
        # in the src/cpp/CMakeLists.txt
        'pyflann.lib': 'pyflann/lib',
    },
    include_package_data=False,
    # List of classifiers available at:
    # https://pypi.python.org/pypi?%3Aaction=list_classifiers
    classifiers=[
        'Development Status :: 6 - Mature',
        'License :: OSI Approved :: BSD License',
        'Intended Audience :: Developers',
        'Intended Audience :: Science/Research',
        'Operating System :: MacOS :: MacOS X',
        'Operating System :: Unix',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Topic :: Scientific/Engineering :: Artificial Intelligence',
        'Topic :: Scientific/Engineering :: Image Recognition'
    ],
    cmake_args=[
        '-DBUILD_C_BINDINGS=ON',
        '-DBUILD_MATLAB_BINDINGS=OFF',
        '-DBUILD_EXAMPLES=OFF',
        '-DBUILD_TESTS=OFF',
        '-DBUILD_DOC=OFF',
    ],
    ext_modules=EmptyListWithLength(),  # hack for including ctypes bins
)

if __name__ == '__main__':
    """
    python -c "import pyflann; print(pyflann.__file__)"
    """
    skbuild.setup(**KWARGS)
