CREATE TABLE dda_parameters (
    name VARCHAR(64),
    description VARCHAR(64),
    torque CHAR(6),
    solution_method CHAR(6),
    fft_algorithm CHAR(6),
    dipole_polarizability CHAR(6),
    binary_dump CHAR(6),
    netcdf CHAR(6),
    shape CHAR(6),
    shape_parameters VARCHAR(64),
    shape_description VARCHAR(255),
    shape_data TEXT,
    dielectric_table_names VARCHAR(255),
    dielectric_table_files TEXT,
    init INTEGER,
    error_tolerance VARCHAR(32),
    num_thetas INTEGER,
    num_phis INTEGER,
    wavelength_first VARCHAR(32),
    wavelength_last VARCHAR(32),
    wavelength_num VARCHAR(16),
    wavelength_choice VARCHAR(16),
    radii_first VARCHAR(32),
    radii_last VARCHAR(32),
    radii_num VARCHAR(16),
    radii_choice VARCHAR(16),
    polarization VARCHAR(32),
    polarization_states INTEGER,
    write_sca INTEGER,
    beta VARCHAR(64),
    theta VARCHAR(64),
    phi VARCHAR(64),
    scattering_planes_table VARCHAR(255),
    results_table VARCHAR(255));

INSERT INTO dda_parameters VALUES (
    'Example DDA',
    'Example DDA parameters from the ddscat source distribution.',
    'NOTORQ',
    'PBCGST',
    'GPFAFT',
    'LATTDR',
    'NOTBIN',
    'NOTCDF',
    'RCTNGL',
    '8 6 4',
    '',
    '',
    'TABLES',
    'diel.tab',
    0,
    '1.00e-5',
    33,
    12,
    '6.283185',
    '6.283185',
    '1',
    'INV',
    '1.',
    '1.',
    '1',
    'LIN',
    '(0,0) (1.,0.) (0.,0.)',
    2,
    1,
    '0. 0. 1',
    '0. 90. 3',
    '0. 0. 1',
    'dda_scattering_plane_example',
    'dda_results_example');

CREATE TABLE dda_scattering_plane_example (phi VARCHAR(32), min VARCHAR(32), max VARCHAR(32), num VARCHAR(32));
INSERT INTO dda_scattering_plane_example VALUES ('0.', '0.', '180.', '30');
INSERT INTO dda_scattering_plane_example VALUES ('90.', '0.', '180.', '30');

CREATE TABLE dda_results_example (
    name VARCHAR(64),
    filename VARCHAR(255),
    data BLOB);