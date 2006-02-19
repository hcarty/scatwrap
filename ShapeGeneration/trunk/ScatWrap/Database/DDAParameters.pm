package ScatWrap::Database::DDAParameters;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

# The columns in this table.
my $columns = q/
    id
    name
    description
    torque
    solution_method
    fft_algorithm
    dipole_polarizability
    binary_dump
    netcdf
    shapeid
    dielectric_table_names
    dielectric_table_data
    init
    error_tolerance
    eta_scattering
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
    phi
    iwav0
    irad0
    iori0
    num_reported_elements
    reported_elements_indices /;

# Table description.
ScatWrap::DDAParameters->table('dda_parameters');
ScatWrap::DDAParameters->columns( All => qq/$columns/ );

# Data relationships.
ScatWrap::DDAParameters->has_a( shapeid => 'ScatWrap::Database::DDAShapes' );
ScatWrap::DDAParameters->has_many( resultids => 'ScatWrap::Database::DDAResults' );
ScatWrap::DDAParameters->has_many( planeids => 'ScatWrap::Database::DDAScatteringPlanes' );

1;
