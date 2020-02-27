package Wocr::DB::Schema::Result::User;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('users');

__PACKAGE__->load_components(qw/EncodedColumn/);

__PACKAGE__->add_columns(
  'user_id',
  {data_type => 'integer', is_auto_increment => 1, is_nullable => 0},
  'name',
  {data_type => 'varchar', is_nullable => 0, size => 160},
  'alias',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 160},
  'trash',
  {data_type => 'tinyint', default_value => 0, is_nullable => 1},
  'active',
  {data_type => 'tinyint', default_value => 1, is_nullable => 1},
  'mail',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 100},
  'password',
  {
    data_type => 'CHAR',
    size      => 59,
    encode_column => 1,
    encode_class  => 'Crypt::Eksblowfish::Bcrypt',
    encode_args   => { key_nul => 0, cost => 8 },
    encode_check_method => 'check_password',
  },
);

=pod

column password => {
    data_type => 'CHAR',
    size      => 59,
    encode_column => 1,
    encode_class  => 'Crypt::Eksblowfish::Bcrypt',
    encode_args   => { key_nul => 0, cost => 8 },
    encode_check_method => 'check_password',
};

=cut

__PACKAGE__->set_primary_key('user_id');

__PACKAGE__->add_unique_constraint('name', ['name']);

__PACKAGE__->has_many(
  'user_roles',
  'Wocr::DB::Schema::Result::UserRole',
  {'foreign.user_id' => 'self.user_id'},
  {cascade_copy      => 0, cascade_delete => 0},
);

__PACKAGE__->many_to_many('roles', 'user_roles', 'role_id');

__PACKAGE__->has_many(
  'user_groups',
  'Wocr::DB::Schema::Result::UserGroup',
  {'foreign.user_id' => 'self.user_id'},
  {cascade_copy      => 0, cascade_delete => 0},
);

__PACKAGE__->many_to_many('groups', 'user_groups', 'group');

1;
