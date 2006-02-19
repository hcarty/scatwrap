# The module is split in to sub-packages because it's a little cleaner and
# easier to work with Class::DBI this way.  ScatWrap::Database is the only bit
# which should be used by the outside world.
package ScatWrap::Database;

use ScatWrap::Database::DB;
use ScatWrap::Database::DDAShapes;
use ScatWrap::Database::DDAParameters;
use ScatWrap::Database::DDAResults;
use ScatWrap::Database::DDARuns;
use ScatWrap::Database::DDAScatteringPlanes;

1;
