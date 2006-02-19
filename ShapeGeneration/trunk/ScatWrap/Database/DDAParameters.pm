package ScatWrap::Database::DDAParameters;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

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
    dielectric_table_files
    init
    error_tolerance
    eta_scattering
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
    phi /;
ScatWrap::DDAParameters->table('dda_parameters');
ScatWrap::DDAParameters->columns( All => qq/$columns/ );
ScatWrap::DDAParameters->has_a( dipoleid => 'ScatWrap::Database::DDADipoles' );
ScatWrap::DDAParameters->has_many( resultids => 'ScatWrap::Database::DDAResults' );
ScatWrap::DDAParameters->has_many( planeids => 'ScatWrap::Database::DDAScatteringPlanes' );
#XXX: Should this be a separate table, or in here?
# ScatWrap::DDAParameters->has_many( dielectricids => 'ScatWrap::Database::DDADielectricTables' );

1;
