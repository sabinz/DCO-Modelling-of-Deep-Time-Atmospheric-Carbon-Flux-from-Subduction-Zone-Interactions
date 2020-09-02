
"""
    Copyright (C) 2015 The University of Sydney, Australia
    
    This program is free software; you can redistribute it and/or modify it under
    the terms of the GNU General Public License, version 2, as published by
    the Free Software Foundation.
    
    This program is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.
    
    You should have received a copy of the GNU General Public License along
    with this program; if not, write to Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
"""


import argparse
import sys
import os.path
import pygplates


DEFAULT_OUTPUT_FILENAME_PREFIX = 'features'
DEFAULT_OUTPUT_FILENAME_EXTENSION = 'gmt'

# Recieves a rotation files of a plate kinematic model, features to be reconstructed and a specified timestep.
# The function produces a geometry file rotated in accordance to the time step and rotation files.
def reconstruct_features(rotation_model, topological_features, reconstruction_time, output_filename_prefix, output_filename_extension):

    export_filename = 'reconstructed_{0!s}_{1}Ma.{2!s}'.format(output_filename_prefix ,reconstruction_time, output_filename_extension)
    pygplates.reconstruct(topological_features, rotation_model, export_filename, reconstruction_time)


if __name__ == "__main__":

    # Check the imported pygplates version.
    required_version = pygplates.Version(12)
    if not hasattr(pygplates, 'Version') or pygplates.Version.get_imported_version() < required_version:
        print('{0}: Error - imported pygplates version {1} but version {2} or greater is required'.format(
                os.path.basename(__file__), pygplates.Version.get_imported_version(), required_version),
            file=sys.stderr)
        sys.exit(1)


    __description__ = \
    """Reconstruct features to a time step in accordance to given rotation files.

    NOTE: Separate the positional and optional arguments with '--' (workaround for bug in argparse module).
    For example...

    python %(prog)s -r rotations1.rot rotations2.rot -m topologies1.gpml topologies2.gpml -t 10 -- topology_"""

    # The command-line parser.
    parser = argparse.ArgumentParser(description = __description__, formatter_class=argparse.RawDescriptionHelpFormatter)
    
    parser.add_argument('-r', '--rotation_filenames', type=str, nargs='+', required=True,
            metavar='rotation_filename', help='One or more rotation files.')
    parser.add_argument('-m', '--topology_filenames', type=str, nargs='+', required=True,
            metavar='topology_filename', help='One or more files topology files.')

    parser.add_argument('-t', '--reconstruction_times', type=float, nargs='+', required=True,
            metavar='reconstruction_time',
            help='One or more times at which to reconstruct/resolve topologies.')
    
    parser.add_argument('-e', '--output_filename_extension', type=str,
            default='{0}'.format(DEFAULT_OUTPUT_FILENAME_EXTENSION),
            help="The filename extension of the output files containing the resolved topological boundaries and sections "
                "- the default extension is '{0}' - supported extensions include 'shp', 'gmt' and 'xy'."
                .format(DEFAULT_OUTPUT_FILENAME_EXTENSION))
    
    parser.add_argument('output_filename_prefix', type=str, nargs='?',
            default='{0}'.format(DEFAULT_OUTPUT_FILENAME_PREFIX),
            help="The prefix of the output files containing the resolved topological boundaries and sections "
                "- the default prefix is '{0}'".format(DEFAULT_OUTPUT_FILENAME_PREFIX))
    
    
    # Parse command-line options.
    args = parser.parse_args()
    
    rotation_model = pygplates.RotationModel(args.rotation_filenames)
    
    topological_features = [pygplates.FeatureCollection(topology_filename)
            for topology_filename in args.topology_filenames]
    
    for reconstruction_time in args.reconstruction_times:
        reconstruct_features(
                rotation_model,
                topological_features,
                reconstruction_time,
                args.output_filename_prefix,
                args.output_filename_extension)