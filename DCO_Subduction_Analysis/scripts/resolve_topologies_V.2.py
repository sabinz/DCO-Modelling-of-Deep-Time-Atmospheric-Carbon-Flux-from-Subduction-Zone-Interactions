
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

from __future__ import print_function
import argparse
import math
import sys
import os.path
import pygplates

DEFAULT_OUTPUT_FILENAME_PREFIX = 'topology_'
DEFAULT_OUTPUT_FILENAME_EXTENSION = 'shp'


###################### Functions to identify and remove anomalous duplicates #####################


# Set global variable (a maximum search radius of 50 km in radians)
global max_distance
max_distance = (1/pygplates.Earth.mean_radius_in_kms) * 50 # kms

# Function used to remove anomalous feature from resolved feature collection
def filter_anomalous(anomalous_feature_collection, resolved_topology_feature_collection):
    
    black_list_ids = []

    # Creates an anomalous feature list sorted by their polyline lengths
    anomalous_feature_list = sort_fl_by_length(anomalous_feature_collection)
    # Creates a blacklist from anomalous feature list
    black_list = build_blacklist(anomalous_feature_list)
    # Collates a list of feature ID from list of features
    for feature_item in black_list:
        black_list_ids.append(feature_item.get_feature_id())
    
    # Remove blacklist items from subduction zone feature collection
    resolved_topology_feature_collection.remove(black_list_ids)

    return resolved_topology_feature_collection


# Gathers the total length (in kms) of a feature with multiple geometries.  
# Handles polyline feature with single or multiple geometries
def get_geometries_total_length(geometries):
    total_length = 0
    for geo in geometries:
        total_length += geo.get_arc_length()
    return total_length


# Recieves a feature collection of polyline geometry and returns a list of 
# features ordered by polyline length (largest to smallest)
def sort_fl_by_length(anomalous_feature_collection):
    anomalous_feature_list = []
    anomalous_geolength_list = []
    anomalous_geo_list = []
    anomalous_feature_list_sorted = []

    # Creates a list of features from feature collection
    for feature in anomalous_feature_collection:
        anomalous_feature_list.append(feature)

    # Creates a list of geometries from list of features
    for feature in anomalous_feature_list:
        anomalous_geo_list.append(feature.get_geometries())

    # Creates a list of geometry lengths from list of geometries
    for geo in anomalous_geo_list:
        # Handles cases where there are multiple geometries per feature
        anomalous_geolength_list.append(get_geometries_total_length(geo))
        
    # Zips together feature list and geometry lengths lists 
    zipped = zip(anomalous_feature_collection,anomalous_geolength_list)
    
    # Reorders zipped list by geometry lengths in reversed order
    zipped.sort(key = lambda a: a[1], reverse=True)

    # Creates ordered feature list from zipped list
    for item in zipped:
        anomalous_feature_list_sorted.append(item[0])

    return anomalous_feature_list_sorted


# Function used to determine if geometries overlap and how they overlap. If they over lap by more than 
# two vertices an 'adjacency type' class is given.  
# Function recieves two geometries of 'feature' and 'observed'.  
# If feature is a subset geometry of observed segment, then the string 'subset' is returned. 
# If feature is a superset geometry of observed segment, then the string 'superset' is returned.
# If the feature and observed segments are a match, then the string 'duplicate' is returned. 
# In the case that there is only a single vertex match, 'None' is returned.
# Likewise, in the case they do not intercept at any point, 'None' is also returned.
def adjacency_type(feature, observed):
    
    # If geometries of feature and observed do not intercept within 50 km of each other, 'adjacency type' is returned as 'None'
    if pygplates.GeometryOnSphere.distance(feature,observed) > max_distance:
        return None

    # Creates a latitude longitude list that defines the polyline geometries of feature and observed segment.
    feature_latlong_list = feature.get_points()
    observed_latlong_list = observed.get_points()

    # Gathers the distance of the polyline geometries of feature and observed.
    feature_distance_len = feature.get_arc_length()
    observed_distance_len = observed.get_arc_length()

    # Initialising a counter matches between the verticies of feature to the verticies of observed
    match_count = 0

    # In the case that feature is greater equal to observed, iterate through observed lat longs and determine their proximity 
    # to any point along the geometry of feature.  If the point falls into a distance of 50 km from the feature its considered 
    # a match.
    if feature_distance_len >= observed_distance_len:
        for o_latlong in observed_latlong_list:
            if pygplates.GeometryOnSphere.distance(o_latlong,feature)< max_distance:
                match_count+=1
    # Iterate through feature instead of observed
    else:
        for f_latlong in feature_latlong_list:
            if pygplates.GeometryOnSphere.distance(f_latlong,observed)< max_distance:
                match_count+=1


    # Analyzes results from comparisons and assigns it a class in the form of a string name
    if match_count > 2 and observed_distance_len > feature_distance_len:
        return 'subset'
    elif match_count > 2 and observed_distance_len < feature_distance_len:
        return 'superset'
    elif match_count == len(feature_latlong_list) and match_count == len(observed_latlong_list):
        return 'duplicate'
    else:
        # Do nothing. It is a non-overlapping geometry (i.e. only a single vertex match)
        return None


# Function will find 'adjacency type' in the case that either or both feature and observed are 
# multiple set of geometries.  Function will identify whether observed and feature geometries are a 
# adjacency type duplicate, subset, superset or none
def compare_multiple_geometries(feature_geometries, observed_geometries):
    
    # Gets the total polyline length of the geometry sets of feature and observed 
    feature_length = get_geometries_total_length(feature_geometries)
    observed_length = get_geometries_total_length(observed_geometries)

    # Initialises 'adjacency type'
    adj_type = ''
    # Test for 'duplicates' type 
    if(len(observed_geometries)==len(feature_geometries)):
        for f_geo, o_geo in zip(feature_geometries, observed_geometries):
            adj_type = adjacency_type(f_geo,o_geo)    
            if adj_type!='duplicate':
                break
        
        if adj_type == 'duplicate':
            return 'duplicate'

    # Test for 'subset' or 'superset' type 
    for f_geo in feature_geometries:
        for o_geo in observed_geometries:

            adj_type = adjacency_type(f_geo,o_geo)  
        
            # In the case that a matching segment is found
            if adj_type == 'subset' or adj_type == 'superset' or adj_type == 'duplicate':
                if feature_length > observed_length:
                    return 'superset'
                if feature_length < observed_length:
                    return 'subset'

    # After all of the tests if no type is found return 'None'
    return None


# Function collates a list of anomalous features to be removed from a 
# resolved feature collection.  It recieves an ordered (by poyline length) list of anomalous 
# features and returns a black list of features
def build_blacklist(anomalous_feature_list):
    
    # Initialise black list 
    black_list = []
    adj_type = ''

    # Iterate through anomalous feature set, for each item 'feature' 
    # is compared to every other item in the feaure set 'observed'
    for feature in anomalous_feature_list:
        # Ignore iteration if feature is in black list
        if feature in black_list:
            continue

        feature_geometry = feature.get_geometries()

        for observed in anomalous_feature_list:
            
            adj_type = ''

            # For testing
            ob_id = observed.get_feature_id()
            f_id = feature.get_feature_id()
    
            observed_geometry = observed.get_geometries()

            # If observed is in black list or feature and observed are the same, skip this comparison  
            if observed == feature or observed in black_list:
                continue
            
            # If either feature or observed are single sets of geometries
            elif len(observed_geometry) == 1 and len(feature_geometry) == 1:
                
                # Finds 'adjacency type'
                adj_type = adjacency_type(feature_geometry[0], observed_geometry[0])
                
           
            # If either feature or observed consist of multiple geometries
            else:
                # Finds 'adjacency type'
                adj_type = compare_multiple_geometries(feature_geometry, observed_geometry)

            # Black list action to be taken after recieving an 'adjacency type' if the type is 'None', than no action is taken
            if adj_type == 'superset' or adj_type == 'duplicate':     
                
                black_list.append(observed)
                
            if adj_type== 'subset':
                black_list.append(feature)
                # Skip to the next feature comparison in the case that feature is a subset
                break
    
    return black_list



###################### Resolve Topologies Function #####################


def resolve_topologies(rotation_model, topological_features, reconstruction_time, output_filename_prefix, \
    output_filename_extension, anchor_plate_id):
    

    # FIXME: Temporary fix to avoid getting OGR GMT/Shapefile error "Mismatch in field names..." and
    # missing geometries when saving resolved topologies/sections to GMT/Shapefile.
    # It's caused by the OGR writer inside pyglates trying to write out features with different
    # shapefile attribute field (key) names to the same file. We get around this by removing
    # all shapefile attributes.
    topological_features = pygplates.FeaturesFunctionArgument(topological_features).get_features()
    for topological_feature in topological_features:
        topological_feature.remove(pygplates.PropertyName.gpml_shapefile_attributes)
        
    # Resolve our topological plate polygons (and deforming networks) to the current 'reconstruction_time'.
    # We generate both the resolved topology boundaries and the boundary sections between them.
    resolved_topologies = []
    shared_boundary_sections = []
    pygplates.resolve_topologies(
            topological_features, rotation_model, resolved_topologies, reconstruction_time, shared_boundary_sections, \
            anchor_plate_id)

    # We'll create a feature for each boundary polygon feature and each type of
    # resolved topological section feature we find.
    resolved_topology_features = []
    ridge_transform_boundary_section_features = []
    subduction_boundary_section_features = []
    left_subduction_boundary_section_features = []
    right_subduction_boundary_section_features = []

    #anomalous feature lists
    anomalous_sz = []
    anomalous_ridge = []

    # Iterate over the resolved topologies.
    for resolved_topology in resolved_topologies:
        resolved_topology_features.append(resolved_topology.get_resolved_feature())

    # Iterate over the shared boundary sections.
    for shared_boundary_section in shared_boundary_sections:
        
        # Get all the geometries of the current boundary section.
        boundary_section_features = [shared_sub_segment.get_resolved_feature()
                for shared_sub_segment in shared_boundary_section.get_shared_sub_segments()]
        
        #Creates a list of anomalous list of features per feature type ie subduction zones and ridge transform
        for shared_sub_segment, b_s_f in zip(shared_boundary_section.get_shared_sub_segments(), boundary_section_features):
            # Condition identifies anomalous segment
            if len(shared_sub_segment.get_sharing_resolved_topologies()) != 2:
                if shared_boundary_section.get_feature().get_feature_type() == pygplates.FeatureType.create_gpml('SubductionZone'):
                    anomalous_sz.append(b_s_f)
                else:
                    anomalous_ridge.append(b_s_f)

        
        # Add the feature to the correct list depending on feature type, etc.
        if shared_boundary_section.get_feature().get_feature_type() == pygplates.FeatureType.create_gpml('SubductionZone'):
            
            # Put all subduction zones in one collection/file.
            subduction_boundary_section_features.extend(boundary_section_features)
            
            # Also put subduction zones in left/right collection/file.
            polarity_property = shared_boundary_section.get_feature().get(
                    pygplates.PropertyName.create_gpml('subductionPolarity'))
            if polarity_property:
                polarity = polarity_property.get_value().get_content()
                if polarity == 'Left':
                    left_subduction_boundary_section_features.extend(boundary_section_features)
                elif polarity == 'Right':
                    right_subduction_boundary_section_features.extend(boundary_section_features)
            
            
        else:
            # Put all ridges in one collection/file.
            ridge_transform_boundary_section_features.extend(boundary_section_features)

    if resolved_topology_features:
        # Put the features in a feature collection so we can write them to a file.
        resolved_topology_feature_collection= pygplates.FeatureCollection(resolved_topology_features)
        resolved_topology_features_filename = '{0}boundary_polygons_{1:0.2f}Ma.{2}'.format(
                output_filename_prefix, reconstruction_time, output_filename_extension)
        resolved_topology_feature_collection.write(resolved_topology_features_filename)
        
    if ridge_transform_boundary_section_features:
        # Put the features in a feature collection so we can write them to a file.
        ridge_transform_boundary_section_feature_collection = pygplates.FeatureCollection(ridge_transform_boundary_section_features)    

        if anomalous_ridge:
            anomalous_feature_collection = pygplates.FeatureCollection(anomalous_ridge)
            # Anomalous segments are filtered from resolved feature collection
            ridge_transform_boundary_section_feature_collection = filter_anomalous(anomalous_feature_collection,\
                ridge_transform_boundary_section_feature_collection)
            anomalous_ridges_transforms_filename='{0}anomalous_ridge_transform_boundaries_{1:0.2f}Ma.{2}'.format(
                output_filename_prefix, reconstruction_time, output_filename_extension)
            anomalous_feature_collection.write(anomalous_ridges_transforms_filename)


        ridge_transform_boundary_section_features_filename = '{0}ridge_transform_boundaries_{1:0.2f}Ma.{2}'.format(
                output_filename_prefix, reconstruction_time, output_filename_extension)
        ridge_transform_boundary_section_feature_collection.write(ridge_transform_boundary_section_features_filename)
        
    if subduction_boundary_section_features:
        # Put the features in a feature collection so we can write them to a file.
        subduction_boundary_section_feature_collection = pygplates.FeatureCollection(subduction_boundary_section_features)
        
        # In the case that there are anomalous (duplicated) features present, anomalous segments are added to a feature collection and 
        # written to a file
        if anomalous_sz:
            # Write a file containing all of the anomalous subduction zones
            anomalous_feature_collection = pygplates.FeatureCollection(anomalous_sz)
            # Anomalous segments are filtered from resolved feature collection
            subduction_boundary_section_feature_collection = filter_anomalous(anomalous_feature_collection,\
                subduction_boundary_section_feature_collection)
            anomalous_subduction_boundaries_filename='{0}anomalous_subduction_boundaries_{1:0.2f}Ma.{2}'.format(
                output_filename_prefix, reconstruction_time, output_filename_extension)
            anomalous_feature_collection.write(anomalous_subduction_boundaries_filename)

        subduction_boundary_section_features_filename = '{0}subduction_boundaries_{1:0.2f}Ma.{2}'.format(
                output_filename_prefix, reconstruction_time, output_filename_extension)
        subduction_boundary_section_feature_collection.write(subduction_boundary_section_features_filename)
        
    if left_subduction_boundary_section_features:
        # Put the features in a feature collection so we can write them to a file.
        left_subduction_boundary_section_feature_collection = pygplates.FeatureCollection(left_subduction_boundary_section_features)
        
        if anomalous_sz:
            anomalous_feature_collection = pygplates.FeatureCollection(anomalous_sz)
            # Anomalous segments are filtered from resolved feature collection
            left_subduction_boundary_section_feature_collection = filter_anomalous(anomalous_feature_collection,\
                left_subduction_boundary_section_feature_collection)
            anomalous_left_subduction_filename = '{0}anomalous_subduction_boundaries_sL_{1:0.2f}Ma.{2}'.format(
                output_filename_prefix, reconstruction_time, output_filename_extension)
            anomalous_feature_collection.write(anomalous_left_subduction_filename)

        
        left_subduction_boundary_section_features_filename = '{0}subduction_boundaries_sL_{1:0.2f}Ma.{2}'.format(
                output_filename_prefix, reconstruction_time, output_filename_extension)
        left_subduction_boundary_section_feature_collection.write(left_subduction_boundary_section_features_filename)
        
    if right_subduction_boundary_section_features:
        # Put the features in a feature collection so we can write them to a file.
        right_subduction_boundary_section_feature_collection = pygplates.FeatureCollection(right_subduction_boundary_section_features)
        
        if anomalous_sz:
            anomalous_feature_collection = pygplates.FeatureCollection(anomalous_sz)
            # Anomalous segments are filtered from resolved feature collection
            right_subduction_boundary_section_feature_collection = filter_anomalous(anomalous_feature_collection,\
                right_subduction_boundary_section_feature_collection)
            anomalous_right_subduction_filename = '{0}anomalous_subduction_boundaries_sR_{1:0.2f}Ma.{2}'.format(
                output_filename_prefix, reconstruction_time, output_filename_extension)
            anomalous_feature_collection.write(anomalous_right_subduction_filename)
        
        right_subduction_boundary_section_features_filename = '{0}subduction_boundaries_sR_{1:0.2f}Ma.{2}'.format(
                output_filename_prefix, reconstruction_time, output_filename_extension)
        right_subduction_boundary_section_feature_collection.write(right_subduction_boundary_section_features_filename)

    
if __name__ == "__main__":

    # Check the imported pygplates version.
    required_version = pygplates.Version(9)
    if not hasattr(pygplates, 'Version') or pygplates.Version.get_imported_version() < required_version:
        print('{0}: Error - imported pygplates version {1} but version {2} or greater is required'.format(
                os.path.basename(__file__), pygplates.Version.get_imported_version(), required_version),
            file=sys.stderr)
        sys.exit(1)


    __description__ = \
    """Resolve topological plate polygons (and deforming networks).

    NOTE: Separate the positional and optional arguments with '--' (workaround for bug in argparse module).
    For example...

    python %(prog)s -r rotations1.rot rotations2.rot -m topologies1.gpml topologies2.gpml -t 10 -- topology_"""

    # The command-line parser.
    parser = argparse.ArgumentParser(description = __description__, formatter_class=argparse.RawDescriptionHelpFormatter)
    
    parser.add_argument('-r', '--rotation_filenames', type=str, nargs='+', required=True,
            metavar='rotation_filename', help='One or more rotation files.')
    parser.add_argument('-m', '--topology_filenames', type=str, nargs='+', required=True,
            metavar='topology_filename', help='One or more files topology files.')
    parser.add_argument('-a', '--anchor', type=int, default=0,
            dest='anchor_plate_id',
            help='Anchor plate id used for reconstructing. Defaults to zero.')
    
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
        resolve_topologies(
                rotation_model,
                topological_features,
                reconstruction_time,
                args.output_filename_prefix,
                args.output_filename_extension,
                args.anchor_plate_id)
