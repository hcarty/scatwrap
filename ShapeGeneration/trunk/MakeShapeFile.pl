#!/usr/bin/perl
#
# Shape generation for the ddscat program.
#
# Usage:
# ./TheScript.pl [input file] >shape.dat
#
# By Hezekiah M. Carty
# University of Maryland Department of Meteorology

#-----------------------------------------------------------------------------#
# TODO List for the ddscat shape generation script
# In no particular order.
#
# - Make the usage notes more verbose.
# - Write proper documentation for program use.
# - Create importers for other file formats.
# - Actually write the routine(s) to export the data to a format usable by
#   ddscat!
# - Document the requirements for the input shapes, and methods for shape
#   generation. (Each individual object must be a closed, convex hull.  If
#   Wings3D ever goes away, Blender, AC3D, and other programs can produce
#   appropriate output files and/or import filters can be written for those or
#   other file formats.
# - Add the ability to define 'normal' shapes (spheres, cubes, etc) to sprinkle
#   about the input data.  This may make some shape combinations easier and
#   more accurate than attempting to generate the whole thing in a 3D modeler.
# - Clean up the code.
#   - Remove extraneous debugging printS.
#   - Remove redundant code.
#   - Organize some of the functions into modules, specifically the shape
#     loading functions.
# - Change loadShape() so that it checks the file extension (or an optional
#   argument passed by the user) to call the proper shape loading routine.
#   This will make the addition of other supported filetypes more straight-
#   forward.
#
#-----------------------------------------------------------------------------#

#-------------------------------------------#
#
# NOTE:
# Beware the array slice.  It seems to be
# troublesome when used with an array ref.
#
#-------------------------------------------#

# Keep it clean.
use strict;

# Math and display routines.
use PDL;
use PDL::Graphics::TriD;
use PDL::Graphics::TriD::Image;
# For easy display of hashes and arrays.
use Data::Dumper;

#----------
# A (few) global variable(s)
#----------
# Debugging, or no?  Assume no, but it can be turned on by a command line
# option.
my $DEBUG = 0;
# The resolution to use when creating the dipoles.
my $XRES = 1.00;
my $YRES = 1.00;
my $ZRES = 0.25;

#----------
# Some subroutine predeclarations.
#----------
sub debugPrint;

#----------
# Start of the main program.
#----------

# Check to make sure the user isn't just asking for usage help.
if ($ARGV[0] =~ /--help/i)
{
    # Display the usage information, then quit.
    displayUsage();
    exit();
}
elsif (($ARGV[0] =~ /--debug/) || ($ARGV[1] =~ /--debug/))
{
    $DEBUG = 1;
}

my $shapeInfo = loadShape();
if ($shapeInfo->{error})
{
    die "Error loading shape:\n" . $shapeInfo->{error} . "\n";
}

debugPrint "Number of objects: " . scalar(@{$shapeInfo->{objects}}) . "\n";

# Select the dipole locations.
createDipoles($shapeInfo, {xres => $XRES, yres => $YRES, zres => $ZRES});

# Save the shape to disk.
saveDDAData('shape.dat', $shapeInfo);

# Display the shape on screen.
displayShape($shapeInfo);

print "Done.\n";

#-----
# The end.  Go home now.
#-----


#----------
# Subroutines 
#----------

####
#
# Description:
# Display a usage message on STDOUT for the user.
#
# Arguments:
# None.
#
# Returns:
# None.
#
####
sub displayUsage
{
    print "\n\n";
    print "$0\n";
    print "by Hezekiah M. Carty\n";
    print "Usage:\n";
    print "To generate shape information appropriate for the ddscat program:\n";
    print "$0 [input file] >shape.dat\n";
    print "The ddscat shape output will be written to STDOUT.\n\n";
    print "For this usage message:\n";
    print "$0 --help\n";
}

####
#
# Description:
# Read the shape input file from disk.
#
# Arguments:
# None.
#
# Returns:
# A hashref holding the shape information.  TODO: Describe the structure of
# the hashref.
# Note - If the 'error' key is set in the returned hashref, there was an error.
# The error key's value is a message describing the problem.
#
####
sub loadShape_smf_old
{
    # Get the input filename from the command line.
    my $inputFilename = $ARGV[0];
    unless ($inputFilename)
    {
        # Exit the program if we don't have a filename to work with.
        return { error => "ERROR: You must provide an input filename on the command line\n" };
    }

    # Make sure we can open the file.
    open(SHAPEFILE, $inputFilename)
        || return { error => "ERROR: Cannot open $inputFilename: $!\n" };
    # Read the file in all in one shot.
    my @shapeData = <SHAPEFILE>;
    # Close the file.
    close(SHAPEFILE);

    my $shapeInfo;
    my @faces;
    my @vertices;
    my @normals;
    # Parse through the entire file, and take the parts we need.
    # This parsing routine is for the plain text 'Michael Garland's format'
    # (.smf) output from the ivcon program by John Burkardt.
    foreach my $line (@shapeData)
    {
        # TODO: EVERYTHING!
        # TODO: More specifically, change this so that it reads the information
        # in by FACE, rather than separating the vertex and normal data away
        # from one another.  This will take a bit more processing in here, but
        # should make code cleaner elsewhere.
        # Get rid of the newline character.
        chomp($line);
        if ($line =~ /^v /i)
        {
            # It's a vertex line.
            my @parts = split(' ', $line);
            push(@{$shapeInfo->{vertex}}, { x => $parts[1], y => $parts[2], z => $parts[3] });

            # Make a PDL object out of the vertex.
            push(@vertices, pdl(@parts[1 .. 3]));
        }
        elsif ($line =~ /^f /i)
        {
            # It's a face line.
            my @parts = split(' ', $line);
            # Get a slice of the array - this allows us to easily grab the
            # proper number of vertices from the line.
            #push(@{$shapeInfo->{face}}, @parts[1 .. (scalar(@parts) - 1)]);

            # Get the (index + 1) of the vertices that d;efine this face.
            # It's (index + 1) because Perl counts arrays from 0, but this file
            # format counts from 1.  So adjust for this!
            for my $i (1 .. (scalar(@parts) - 1))
            {
                $parts[$i] -= 1;
            }
            push(@faces, [@parts[1 .. (scalar(@parts) - 1)]]);
        }
        elsif ($line =~ /^n /i)
        {
            # XXX: NOTE -- It looks like there is no need to use these, as the
            # normals here are vertex normals, not face normals.
            # It's a normal line.
            my @parts = split(' ', $line);
            #push(@{$shapeInfo->{normal}}, { x => $parts[1], y => $parts[2], z => $parts[3] });

            # Make a PDL object out of the normal.
            my $tempNormal = pdl(@parts[1 .. 3]);
            # Make sure the normal is... normalized.
            $tempNormal /= $tempNormal->sumover->dummy(0);
            push(@normals, $tempNormal);
        }
        # else -- It's a comment, or something else we're not interested in.
    }
    
    # Ok, now that we have the raw shape data read in, let's make the planes
    # we will actually use for the data generation.
    foreach my $face (@faces)
    {
        my ($a, $b, $c, $d) = createPlane($vertices[$face->[0]], $vertices[$face->[1]], $vertices[$face->[2]]);
        my $vertices;
        for my $i (0 .. (scalar(@$face) - 1))
        {
            push(@$vertices, [$shapeInfo->{vertex}->[$face->[$i]]->{x},
                              $shapeInfo->{vertex}->[$face->[$i]]->{y},
                              $shapeInfo->{vertex}->[$face->[$i]]->{z}]);
        }
        push(@{$shapeInfo->{face}}, { plane    => { a => $a, b => $b, c => $c, d => $d },
                                      vertices => $vertices,
                                      normal   => pdl([$a->at(0), $b->at(0), $c->at(0)]) });
    }

    return $shapeInfo;
}

####
#
# Description:
# Read the shape input file in Wavefront (.obj, as exported from Wings3D)
# format from disk.
#
# Arguments:
# None.
#
# Returns:
# A hashref holding the shape information.
# Note - If the 'error' key is set in the returned hashref, there was an error.
# The error key's value is a message describing the problem.
#
# TODO:
# 1. Add (better) error checking to the file reading routines.
# 2. Describe the structure of the hashref returned by this function.
#
####
sub loadShape_obj_old
{
    # Get the input filename from the command line.
    my $inputFilename = $ARGV[0];
    unless ($inputFilename)
    {
        # Exit the program if we don't have a filename to work with.
        return { error => "ERROR: You must provide an input filename on the command line\n" };
    }

    # Make sure we can open the file.
    open(SHAPEFILE, $inputFilename)
        || return { error => "ERROR: Cannot open $inputFilename: $!\n" };

    # This is the final holding place for all of the shape information in the
    # file.
    my $shapeInfo;
    # Lists of faces and vertices and the nameof the current object -- scratch space more or less.
    # We're ignoring the vertex normals, as they are not of much use to us at
    # the moment.
    my @faces;
    my @vertices;
    my $objectName;

    # This keeps track of which object we're on in the file.
    my $currentObject = 0;

    # Parse through the entire file, and take the parts we need.
    #foreach my $line (@shapeData)
    while(<SHAPEFILE>)
    {
        my $line = $_;
        # Get rid of the newline character.
        chomp($line);
        if (($line =~ /^o /i) || eof(SHAPEFILE))
        {
            debugPrint "Foo.\n";
            if (scalar(@faces) > 0)
            {
                debugPrint "Current Object: $currentObject\n";
                # As long as we're not on just starting the first object,
                # store the current object's information and clear the
                # temporary storage variables.

                # Now that we have the raw shape data read in, let's make the planes
                # we will actually use for the data generation.
                foreach my $face (@faces)
                {
                    my ($a, $b, $c, $d) = createPlane($vertices[$face->[0]],
                                                      $vertices[$face->[1]],
                                                      $vertices[$face->[2]]);
                    debugPrint "@{$vertices[$face->[0]]}\n";
                    # Make sure we have a normalized normal.
                    my $normal = pdl([$a, $b, $c]);
                    $normal /= $normal->sumover->dummy(0);
                    # Collect this face's vertices.
                    my $numVerts = scalar(@$face);
                    my $faceVertices;
                    foreach my $index (@$face)
                    {
                        # TODO: MAKE SURE THIS IS READ IN PROPERLY!!!
                        push(@$faceVertices, $vertices[$index]);
                    }
                    debugPrint "Face vert: " . $faceVertices->[0]->[0] . "\n";
                    push(@{$shapeInfo->{objects}->[$currentObject]},
                         { name     => $objectName,
                           plane    => { a => $a, b => $b, c => $c, d => $d },
                           vertices => $faceVertices,
                           normal   => $normal });
                }
            }
            # On to the new object.
            $currentObject++;
            # Get the name of the current object.
            my @parts = split(' ', $line);
            $objectName = $parts[1];
            # Reset these temporary storage variables for use with the next object.
            @faces = undef;
        }
        elsif ($line =~ /^v /i)
        {
            # It's a vertex line.
            my @parts = split(' ', $line);
            # Put all of the vertices in a big glob to make it easier to
            # display them.
            push(@{$shapeInfo->{vertex}}, { x => $parts[1], y => $parts[2], z => $parts[3] });

            # Grab the vertex in a more immediately useful format.
            push(@vertices, [@parts[1 .. 3]]);
        }
        elsif ($line =~ /^f /i)
        {
            # It's a face line.
            my @parts = split(' ', $line);
            # Get the (index + 1) of the vertices that d;efine this face.
            # It's (index + 1) because Perl counts arrays from 0, but this file
            # format counts from 1.  So adjust for this!
            for my $i (1 .. (scalar(@parts) - 1))
            {
                # Some regexp trickery...
                # The face lines, for some reason, have a format similar to
                # this:
                # f 1//1 2//2 3//3
                # where 1, 2, and 3 are the #'s of the vertices that describe
                # the face.  So, to strip the '//1', '//2', etc, the following
                # regexp works wonderfully.
                $parts[$i] =~ s:^(\d+)//\d+:$1:;
                if ($parts[$i] =~ /[^\d]/)
                {
                    # This is in an attempt to pick up on bad formatting in the
                    # file.
                    return { error => "Badly formatted line:\n$line" };
                }
                $parts[$i] -= 1;
            }
            push(@faces, [@parts[1 .. (scalar(@parts) - 1)]]);
        }
        # else -- It's a comment, or something else we're not interested in.
    }

    # Close the file, because we're done with it.
    close(SHAPEFILE);

    return $shapeInfo;
}

####
#
# Description:
# Read the shape input file in Wavefront (.obj, as exported from Wings3D)
# format from disk.
#
# Arguments:
# None.
#
# Returns:
# A hashref holding the shape information.
# Note - If the 'error' key is set in the returned hashref, there was an error.
# The error key's value is a message describing the problem.
#
# TODO:
# 1. Add (better) error checking to the file reading routines.
# 2. Describe the structure of the hashref returned by this function.
#
####
sub loadShape
{
    # Get the filename from the command line.
    my $filename = $ARGV[0];
    
    # Open the file.
    open(SHAPEFILE, $filename) ||
        return { error => "Can't open $filename: $!" };

    # The data from the file, in a more usable format.
    my $shapeInfo;
    # Save the filename we loaded this from.
    $shapeInfo->{filename} = $filename;
    # A list of all of the objects in the file.
    my @objects;
    # A list of all of the vertices in the all of the objects.
    my @vertices;
    # The current object we're loading from the file.
    my $currentObject;

    # Read in the file.
    while(<SHAPEFILE>)
    {
        my $thisLine = $_;
        if ($thisLine !~ /^[vfo] /i)
        {
            # Skip the line if it isn't a vertex, face, or new object.
            next;
        }
        else
        {
            # Break the line into parts.
            my @parts = split(' ', $thisLine);

            # Find out which type of line we're on.
            if (lc($parts[0]) eq 'o')
            {
                # The start of a new object.
                if (exists($currentObject->{name}))
                {
                    # If we already have an object ready to go, save it.
                    push(@objects, $currentObject);
                }

                # Clear out the old data.
                $currentObject = undef;
                # Grab the new object name.
                $currentObject->{name} = $parts[1];
                debugPrint "Reading object: " . $currentObject->{name} . "\n";
            }
            elsif (lc($parts[0]) eq 'v')
            {
                # Handle a vertex.
                # Just grab the vertex information and push it onto the end of the list.
                push(@vertices, [@parts[1 .. 3]]);
                debugPrint "Vertex: @parts[1 .. 3]\n";
            }
            elsif (lc($parts[0]) eq 'f')
            {
                # Handle a face.
                for my $i (1 .. (scalar(@parts) - 1))
                {
                    # Some regexp trickery...
                    # The face lines, for some reason, have a format similar to
                    # this:
                    # f 1//1 2//2 3//3
                    # where 1, 2, and 3 are the #'s of the vertices that describe
                    # the face.  So, to strip the '//1', '//2', etc, the following
                    # regexp works wonderfully.
                    $parts[$i] =~ s:^(\d+)//\d+:$1:;
                    if ($parts[$i] =~ /[^\d]/)
                    {
                        # This is in an attempt to pick up on bad formatting in the
                        # file.
                        return { error => "Badly formatted line:\n$thisLine" };
                    }
                    # Change the numbers to be Perl-array-offset friendly, ie
                    # count from 0 rather than 1.
                    $parts[$i]--;
                }
                # Find out which vertices it uses.
                # XXX: NOTE -- This assumes that all of the vertices have
                #              been read in already.
                my $thisFace;
                foreach my $vertIndex (@parts[1 .. (scalar(@parts) - 1)])
                {
                    push(@{$thisFace->{vertices}}, $vertices[$vertIndex]);
                }

                # Get the equation for the plane that makes up this face.
                debugPrint "Using points: @{$thisFace->{vertices}->[0]}\n";
                debugPrint "Using points: @{$thisFace->{vertices}->[1]}\n";
                debugPrint "Using points: @{$thisFace->{vertices}->[2]}\n";
                my ($a, $b, $c, $d) = createPlane($thisFace->{vertices}->[0],
                                                  $thisFace->{vertices}->[1],
                                                  $thisFace->{vertices}->[2]);
                debugPrint "Created plane: $a $b $c $d\n";
                # Add the plane definition to the object.
                $thisFace->{plane} = [$a, $b, $c, $d];

                # Add this face to the list.
                push(@{$currentObject->{faces}}, $thisFace);
            }
        }
    }

    # Push the last object onto the list.
    if (exists($currentObject->{name}))
    {
        # If we already have an object ready to go, save it.
        push(@objects, $currentObject);
    }

    # We're done with the file, close it up.
    close(SHAPEFILE);

    # Record the object information.
    $shapeInfo->{objects} = \@objects;
    # Record the vertex information.
    $shapeInfo->{vertices} = \@vertices;
    
    debugPrint "Structure of the loaded data:\n";
    debugPrint Dumper($shapeInfo);

    # Return the information.
    return $shapeInfo;
}

####
#
# Description:
# Draw the shape on the screen.
#
# Arguments:
# The $shapeInfo hashref.
#
# Returns:
# None.
#
####
sub displayShape
{
    my $shapeInfo = shift;
    debugPrint Dumper($shapeInfo->{vertices});
    my @a;
    my @b;
    my @c;
    foreach my $vertex (@{$shapeInfo->{vertices}})
    {
        debugPrint Dumper($vertex);
        push(@a, $vertex->[0]);
        push(@b, $vertex->[1]);
        push(@c, $vertex->[2]);
    }
    debugPrint Dumper(@a);
    my $x = pdl(@a);
    my $y = pdl(@b);
    my $z = pdl(@c);
    debugPrint "Bounding values:\n";
    debugPrint 'x: ' . minimum($x) . ' => ' . maximum($x) . "\n";
    debugPrint 'y: ' . minimum($y) . ' => ' . maximum($y) . "\n";
    debugPrint 'z: ' . minimum($z) . ' => ' . maximum($z) . "\n";
    points3d([$x, $y, $z]);
}


####
#
# Description:
# Check a point to see if it is inside the given shape.
#
# Arguments:
# 1. The point we are checking, in the format: [x, y, z].
# 2. The shapeInfo hashref.
#
# Returns:
# None.
#
####
sub pointInside
{
    my ($checkPoint, $shapeInfo) = @_;
    my $checkPoint = pdl($checkPoint);
    OBJECT: foreach my $object (@{$shapeInfo->{objects}})
    {
        FACE: foreach my $face (@{$object->{faces}})
        {
            my $planePoint = pdl($face->{vertices}->[0]);
            my $planeNormal = pdl($face->{plane}->[0],
                                  $face->{plane}->[1],
                                  $face->{plane}->[2]);
            $planeNormal /= $planeNormal->sumover->dummy(0);
            my $point1 = pdl($face->{vertices}->[0]);
            my $point2 = pdl($face->{vertices}->[1]);
            my $point3 = pdl($face->{vertices}->[2]);
            my $vector1 = $point1 - $point2;
            my $vector2 = $point3 - $point2;
            $planeNormal = crossp($vector2, $vector1);
            $planeNormal = norm($planeNormal);
            my $distance = dotProduct(($checkPoint - $planePoint), $planeNormal);
            debugPrint "\n\nPlane Point: $planePoint\n";
            debugPrint "Checking point: " . $checkPoint . "\n";
            debugPrint "Face points: $point1 $point2 $point3\n";
            debugPrint "Vector1: $vector1\n";
            debugPrint "Vector2: $vector2\n";
            debugPrint "Normal: $planeNormal\n";
            debugPrint "Object: " . $object->{name} . "\n";
            debugPrint "Distance: $distance\n";
            # There is no point in continuing with this object if a point is
            # outside any of the faces, so skip to the next one if/when this
            # is the case.
            next OBJECT if ($distance > 0);
        }
        # If we get here, the point is inside an object.
        return 1;
    }

    # If we made it to here, the point is outside.
    return undef;
}

####
#
# Description:
# Create a plane, given a set of 3 coordinates.
#
# Arguments:
# 1-3. [x1 y1 z1], [x2 y2 z2], [x3 y3 z3] - The 3 points we're building the plane from.  As pdls.
#
# Returns:
# 1. [a b c d] - The coefficients for the equation of the line, in the form:
#    ax + by + cz + d = 0
#
####
sub createPlane
{
    # Argument(s) - the 3 points that define the plane.
    my ($p1, $p2, $p3) = @_;
    debugPrint "[@$p1] [@$p2] [@$p3] - In createPlane\n";

    # A x + B y + C z + D = 0 (??)
    my $D = determinant(pdl([[$p1->[0], $p2->[0], $p3->[0]],
                             [$p1->[1], $p2->[1], $p3->[1]],
                             [$p1->[2], $p2->[2], $p3->[2]]]));
    my $A = determinant(pdl([[1, $p2->[0], $p3->[0]],
                             [1, $p2->[1], $p3->[1]],
                             [1, $p2->[2], $p3->[2]]]));
    my $B = determinant(pdl([[$p1->[0], 1, $p3->[0]],
                             [$p1->[1], 1, $p3->[1]],
                             [$p1->[2], 1, $p3->[2]]]));
    my $C = determinant(pdl([[$p1->[0], $p2->[0], 1],
                             [$p1->[1], $p2->[1], 1],
                             [$p1->[2], $p2->[2], 1]]));

    return $A->at(0), $B->at(0), $C->at(0), $D->at(0);
}

####
#
# Description:
# Calculate the dot product of two 3-element pdls.
#
# Arguments:
# 1-2. Two 3 element pdls
#
# Returns:
# A scalar value (the dot product)
#
####
sub dotProduct
{
    my ($a, $b) = @_;
    return sum($a * $b);
}

####
#
# Description:
# Select locations for dipoles to approximate the given shape.
#
# Arguments:
# 1. The $shapeInfo hashref.
# 2. A hashref with the x, y, and z resolution to use when creating the
#    dipoles.  It should be of the form:
#    { xres => x,
#      yres => y,
#      zres => z }
#
# Returns:
# None.
#
####
sub createDipoles
{
    # Arguments.
    my ($shapeInfo, $resolution) = @_;
    # Get the max and min range for x, y, z
    my @a;
    my @b;
    my @c; 
    foreach my $vertex (@{$shapeInfo->{vertices}})
    {
        push(@a, $vertex->[0]);
        push(@b, $vertex->[1]);
        push(@c, $vertex->[2]);
    }
    my $xVals = pdl(@a);
    my $yVals = pdl(@b);
    my $zVals = pdl(@c);
    my $xMin = minimum($xVals);
    my $xMax = maximum($xVals);
    my $yMin = minimum($yVals);
    my $yMax = maximum($yVals);
    my $zMin = minimum($zVals);
    my $zMax = maximum($zVals);
    for (my $x = $xMin->at(0); $x <= $xMax->at(0); $x += $resolution->{xres})
    {
        for (my $y = $yMin->at(0); $y <= $yMax->at(0); $y += $resolution->{yres})
        {
            for (my $z = $zMin->at(0); $z <= $zMax->at(0); $z += $resolution->{zres})
            {
                debugPrint "Checking: [$x, $y, $z]\n";
                if (pointInside([$x, $y, $z], $shapeInfo))
                {
                    # Record the dipole location.
                    debugPrint "Point inside: [$x, $y, $z]\n";
                    push(@{$shapeInfo->{vertices}}, [$x, $y, $z]);
                }
            }
        }
    }
}

####
#
# Description:
# Like 'print', but only works if the $DEBUG variable is set to a true value.
#
# Arguments:
# Whatever you'd like to print.
#
# Returns:
# Whatever 'print' returns
# OR
# undef if $DEBUG is false.
#
####
sub debugPrint
{
    if ($DEBUG)
    {
        return print @_;
    }
    else
    {
        return undef;
    }
}

####
#
# Description:
# Write the generated dipole information out to disk in a formay usable by
# ddscat.
# WARNING: The given filename will be overwritten if it already exists.
#
# Arguments:
# 1. Filename to save the data to.
# 2. The shapeInfo hashref.
#
# Returns:
# undef on success
# OR
# Scalar string containing the error message on failure.
#
####
sub saveDDAData
{
    # Get the shape data.
    my $filename = shift;
    my $shapeInfo = shift;

    # Open the file for writing.
    # WARNING:  This will overwrite the file if it already exists.
    open(OUTFILE, ">$filename") ||
        return "Unable to open $filename for writing: $!";

    # Print out a descriptive header.
    print OUTFILE "Shape information for $shapeInfo->{filename}\n";
    print OUTFILE scalar(@{$shapeInfo->{vertices}}) . " = Number of dipoles in the system\n";
    print OUTFILE "1 1 1 = x, y, z components of a1\n";
    print OUTFILE "1 1 1 = x, y, z components of a2\n";
    print OUTFILE "xPos yPos zPos xComposition yComposition zComposition\n";
    
    # Now list out all of the vertices.
    ##
    # TODO: Allow for non-isotropic materials?
    # This would require changing the '1 1 1' to some given composition
    # values.
    ##
    for (my $i = 0; $i < scalar(@{$shapeInfo->{vertices}}); $i++)
    {
        print OUTFILE $i + 1 . " @{$shapeInfo->{vertices}->[$i]} 1 1 1\n";
    }

    # We're finished.  Close the file.
    close(OUTFILE);

    # Success!
    return undef;
}
