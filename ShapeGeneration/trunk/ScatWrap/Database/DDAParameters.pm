package ScatWrap::Database::DDAParameters;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

ScatWrap::DDAParameters->table('dda_parameters');
ScatWrap::DDAParameters->columns( All => qw/
    id
    name
    description
    torque
    solution_method
    fft_algorithm
    dipole_polarizability
    binary_dump
    netcdf
    shape
    shape_parameters
    shape_description
    shape_data
    dielectric_table_names
    dielectric_table_files
    init
    error_tolerance
    num_thetas
    num_phis
    wavelength_first
    wavelength_last
    wavelength_num
    wavelength_choice
    radii_first
    radii_last
    radii_num
    radii_choice
    polarization
    polarization_states
    write_sca
    beta
    theta
    phi / );
ScatWrap::DDAParameters->has_a( resultid => 'ScatWrap::Database::DDAResults' );
ScatWrap::DDAParameters->has_many( planeid => 'ScatWrap::Database::DDAScatteringPlanes' );

1;
