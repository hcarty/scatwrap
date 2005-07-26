#!/usr/bin/perl -w
#
# Wrapper for ddscat program.
# By Hezekiah M. Carty
# University of Maryland Department of Meteorology
#

# For database access.
use DBI;
# Only you can prevent ugly code.
use strict;


####
#
# Description:
# Opens a connection to the database and returns a database handle ready for use.
#
# Arguments:
# None.
#
# Returns:
# A database handle ready to use.
# OR
# null on failure.
#
####
sub openDB
{
    my $dbh = DBI->connect("dbi:SQLite:dbname=dda.db", "", "", { RaiseError => 1 });
    if ($dbh)
    {
        return $dbh;
    }
    else
    {
        return 'No good';
    }
}

####
#
# Description:
# Close a connection to the database.
#
# Arguments:
# A valid database handle.
#
# Returns:
# None.
#
####
sub closeDB
{
    my $dbh = shift;
    $dbh->disconnect();
}

####
#
# Description:
# Loads and returns the input parameters for the ddscat program.
#
# Arguments:
# None.
#
# Returns:
# 1. A hash reference containing the input parameter data.
#
####
sub getInputParameters
{
    # Get the subroutine argument(s).
    my $dbh = shift;

    # Nab the information from the database.
    my $pRef = $dbh->selectall_arrayref("SELECT * FROM dda_parameters WHERE name = 'Example DDA'");
    my @p = @{$pRef->[0]};

    ##
    # TODO: Set all of this up properly!
    # It should read from a file/database/something else.
    # Perhaps an argument could be added to define where the data should come
    # from.
    ##
    # For now, just return a hash with the example information filled in to
    # make sure we are doing this properly.
    my @dielectricTableFiles = split(' ', $p[13]);
    my $parameterHash = {
        torque => $p[2],
        solutionMethod => $p[3],
        fftAlgorithm => $p[4],
        dipolePolarizability => $p[5],
        binaryDump => $p[6],
        netCDF => $p[7],
        shape => $p[8],
        shapeParameters => $p[9],
        shapeData => $p[10],
        shapeDescription => $p[11],
        numDielectricTables => scalar(@dielectricTableFiles), # TODO: Make sure this is being properly handled...
        dielectricTableNames => $p[12],
        dielectricTableFiles => $p[13],
        init => $p[14],
        errorTolerance => $p[15],
        numThetas => $p[16],
        numPhis => $p[17],
        wavelengths => {
            first => $p[18],
            last => $p[19],
            number => $p[20],
            howChosen => $p[21]
        },
        radii => {
            first => $p[22],
            last => $p[23],
            number => $p[24],
            howChosen => $p[25]
        },
        polarization => $p[26],
        numPolarizationStates => $p[27],
        writeSCAFiles => $p[28],
        beta => $p[29],
        theta => $p[30],
        phi => $p[31]
    };

    my $scatteringPlaneTable = $p[32];
    my $sRef = $dbh->selectall_arrayref("SELECT * FROM $scatteringPlaneTable");

    for (my $i = 0; $i < scalar(@$sRef); $i++)
    {
        my $plane = join(' ', @{$sRef->[$i]});
        $parameterHash->{scatteringPlanes}->[$i] = $plane;
    }

    return $parameterHash;
}

####
#
# Description:
# Write the input parameters for the ddscat program to the 'ddscat.par' file.
#
# Arguments:
# 1. A hash reference containing the input parameter data.
#
# Returns:
# None.
#
####
sub writeInputParametersToDisk
{
    my $parameters = shift;
    # If we can't open the file, quit!
    unless (open(OUTFILE, '>ddscat.par'))
    {
        die "I couldn't open the ddscat.par file for writing: $!\n";
    }

    ##
    # Write the goodies out to disk.
    ##
    # Two lines of comments.
    print OUTFILE "'ddscat parameter file'\n";
    print OUTFILE "'Automatically generated by DDAWrapper.pl'\n";
    # Torque handling.
    print OUTFILE "'$parameters->{torque}'\n";
    # Solution method.
    print OUTFILE "'$parameters->{solutionMethod}'\n";
    # FFT method.
    print OUTFILE "'$parameters->{fftAlgorithm}'\n";
    # Dipole Polarizability.
    print OUTFILE "'$parameters->{dipolePolarizability}'\n";
    # Binary dump (or not?).
    print OUTFILE "'$parameters->{binaryDump}'\n";
    # netCDF (y/n).
    print OUTFILE "'$parameters->{netCDF}'\n";
    # Shape.
    print OUTFILE "'$parameters->{shape}'\n";
    # Shape parameters.
    print OUTFILE "$parameters->{shapeParameters}\n";
    # Number of dielectric tables.
    print OUTFILE "$parameters->{numDielectricTables}\n";
    # Dielectric table names.
    print OUTFILE "'$parameters->{dielectricTableNames}'\n";
    # Dielectric table files.
    print OUTFILE "'$parameters->{dielectricTableFiles}'\n";
    # A comment line.
    print OUTFILE "'Conjugate gradient definitions'\n";
    # INIT value.
    print OUTFILE "$parameters->{init}\n";
    # Allowed error.
    print OUTFILE "$parameters->{errorTolerance}\n";
    # Another comment line.
    print OUTFILE "'Angles'\n";
    # Thetas!
    print OUTFILE "$parameters->{numThetas}\n";
    # Phis!
    print OUTFILE "$parameters->{numPhis}\n";
    # And another comment line.
    print OUTFILE "'Wavelengths'\n";
    # Wavelength info (microns).
    print OUTFILE join(' ', ($parameters->{wavelengths}->{first},
                             $parameters->{wavelengths}->{last},
                             $parameters->{wavelengths}->{number},
                             $parameters->{wavelengths}->{howChosen})) . "\n";
    # One more comment line.
    print OUTFILE "'Effective radii'\n";
    # Effective radii (microns).
    print OUTFILE join(' ', ($parameters->{radii}->{first},
                             $parameters->{radii}->{last},
                             $parameters->{radii}->{number},
                             $parameters->{radii}->{howChosen})) . "\n";
    # Another comment coming your way.
    print OUTFILE "'Incident polarizations'\n";
    # Incident polarization.
    print OUTFILE "$parameters->{polarization}\n";
    # Which polarizations to calculate.
    print OUTFILE "$parameters->{numPolarizationStates}\n";
    # Write .sca files?
    print OUTFILE "$parameters->{writeSCAFiles}\n";
    # Second to last comment line.
    print OUTFILE "'Target rotations'\n";
    # Beta
    print OUTFILE "$parameters->{beta}\n";
    # Theta
    print OUTFILE "$parameters->{theta}\n";
    # Phi
    print OUTFILE "$parameters->{phi}\n";
    # The last comment line.
    print OUTFILE "'Scattered directions.'\n";
    # Scattering plane(s).
    foreach my $plane (@{$parameters->{scatteringPlanes}})
    {
        print OUTFILE "$plane\n";
    }

    close(OUTFILE);
}

####
#
# Description:
# Save the results of a ddscat run to the database.
#
# Arguments:
# 1. A valid DBI database handle, ready to use.
#
# Returns:
# undef on success
# OR
# A scalar string describing the problem on an error.
#
####
sub saveResultsToDB
{
    # Get our database handle.
    my $dbh = shift;

    # A list of files we need to get.
    my %fileList = (
        mtable => 'The mtable file',
        qtable => 'The qtable file',
        qtable2 => 'The qtable2 file'
    );
    # TODO: Also load and save the w*r*.avg file(s) to the database.

    foreach my $filename (keys(%fileList))
    {
        # Read in the results from this run.
        open(INFILE, $filename) ||
            return "Unable to open $filename: $!\n";
        my $fileData = join("", <INFILE>);
        close(INFILE);
        # TODO: Fix this so that it always uses the proper db table.
        my $sql = qq/INSERT INTO dda_results_example VALUES (?, ?, ?)/;
        my $exec = $dbh->prepare($sql);
        $exec->execute($fileList{$filename}, $filename, $fileData);
    }
}

#-----
# Start of the main program.
#-----
my $dbh = openDB();
if($dbh eq 'No good')
{
    print "Oh no!\n";
    exit(0);
}

# Get the parameters and write them out to disk.
my $inputRef = getInputParameters($dbh);
writeInputParametersToDisk($inputRef);

# Run the ddscat program.
my $programOutput = `/home/hcarty/Documents/Goddard/DDA/Perl/ddscat`;

# Save the output data to the database.
if(my $error = saveResultsToDB($dbh))
{
    print "ERROR: $error\n";
}

# Close all of our connections and clean up.
closeDB($dbh);
print "All done.\n";

#-----
# We're all done.  Nap time.
#-----
