package Wocr::DB::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

our $DB_VERSION = '1';
our $VERSION = eval $DB_VERSION;

__PACKAGE__->load_namespaces;

1;
