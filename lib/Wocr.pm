package Wocr;
use Mojo::Base 'Mojolicious';

use Data::Dumper;

our $VERSION = '0.01';

use File::Basename 'dirname';
use File::Spec;
use File::Spec::Functions qw'rel2abs catdir';
use File::ShareDir 'dist_dir';
use Cwd;

use Mojo::Home;

=pod

has db => sub {
  my $self         = shift;
  my $schema_class = $self->config->{db_schema}
    or die "Unknown DB Schema Class";
  eval "require $schema_class"
    or die "Could not load Schema Class ($schema_class), $@";

  my $db_connect = $self->config->{db_connect}
    or die "No DBI connection string provided";
  my @db_connect = ref $db_connect ? @$db_connect : ($db_connect);

  my $schema = $schema_class->connect(@db_connect)
    or die "Could not connect to $schema_class using $db_connect[0]";

  return $schema;
};

=cut

has ocr => sub {
    my $self = shift;
    return $self->config->{ocr};
};

has ocr_basedir => sub {
    my $self = shift;
    return $self->ocr->{basedir};
};

has app_debug => 0;

has home_path => sub {
    my $path = $ENV{MOJO_HOME} || getcwd;
    return File::Spec->rel2abs($path);
};

has config_file => sub {
    my $self = shift;
    return $ENV{WOCR_CONFIG} if $ENV{WOCR_CONFIG};

    return rel2abs('wocr.conf', $self->home_path);
};

sub startup {
    my $app = shift;

    $app->plugin('DefaultHelpers');

    $app->plugin(
        Config => {
            file    => $app->config_file,
            default => {
                'db_connect' => [
                    'dbi:SQLite:dbname=' . $app->home->rel_file('wocr.db'),
                    undef, undef, {'sqlite_unicode' => 1}
                ],
                'db_schema' => 'Wocr::DB::Schema',
                'secret'    => '47110815'
            },
        }
    );


    $app->plugin('I18N');
    $app->plugin('Mojolicious::Plugin::ServerInfo');

    #$app->plugin('Mojolicious::Plugin::DBInfo');

    {
        # use content from directories under share/files or using File::ShareDir
        my $lib_base = catdir(dirname(rel2abs(__FILE__)), '..', 'share', 'files');

        my $public = catdir($lib_base, 'public');

        $app->static->paths->[0]
            = -d $public ? $public : catdir(dist_dir('Wocr'), 'files', 'public');
        my $static_path = $app->static->paths->[0];

        #my $ocr_base = catdir(dirname(rel2abs(__FILE__)), '..', 'share','files');
        $app->static->paths->[1] = $app->ocr_basedir;

        my $templates = catdir($lib_base, 'templates');
        $app->renderer->paths->[0]
            = -d $templates ? $templates : catdir(dist_dir('Wocr'), 'files', 'templates');
    }

    push @{$app->commands->namespaces}, 'Wocr::Command';

    $app->secrets([$app->config->{secret}]);

    #$app->helper(schema => sub { shift->app->db });

    $app->helper('home_page' => sub {'/'});

    my $routes = $app->routes;

    $routes->get('/')->to('book#index');

    $routes->get('/book/*book')->to('book#show');

    #$routes->post('/book')->to('book#query');
    #$routes->get('/books' => sub { shift->render });
    $routes->get('/books')->to('book#index');

    $routes->get('/page/*page')->to('page#index');

    #$routes->post('/page')->to('page#query');
    #$routes->get('/pages' => sub { shift->render });

    $routes->any('/line/*line')->to('line#index');
    $routes->post('/change/*line')->to('line#change');

    $routes->any('/corr/*line')->to('corr#index');
    $routes->post('/docorr/*line')->to('corr#change');
    $routes->any('/corr')->to('corr#index');

    $routes->get('/about' => sub { shift->render });

} ## end sub startup

1;

__END__

