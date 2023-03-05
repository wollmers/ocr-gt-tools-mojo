package Wocr::Book;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;

    #/Users/helmut/github/ocr-gt/AustrianNewspapers/
    #my $ocr_basedir = $self->stash->{'config'}->{'ocr'}->{'basedir'};
    my $ocr_basedir = $self->app->ocr_basedir;
    my $ocr_conf = $self->app->ocr;

    my $books = {};

    $self->stash('_books' => $books);

#/Users/helmut/github/ocr-gt/AustrianNewspapers/ gt/eval/  ONB_aze_18950706_4/ONB_aze_18950706_4.jpg_tl_1.gt.txt
    for my $dir (qw(train eval)) {
        #my $ocr_conf = $self->app->ocr;
        my $dir_name
            #= $ocr_basedir . $self->stash->{'config'}->{'ocr'}->{'lines'}->{$dir};
            = $ocr_basedir . $ocr_conf->{'lines'}->{$dir};
        opendir(my $dir_dh, "$dir_name") || die "Can't opendir $dir_name: $!";
        my @subdirs = grep { /^[^._]/ && -d "$dir_name/$_" } readdir($dir_dh);
        closedir $dir_dh;

        # ONB_aze_18950706_4
        for my $subdir (@subdirs) {
            my $page_no = 0;
            if ($subdir =~ m/_(\d+)$/) {
                $page_no = $1;
            }

            my $book = $subdir;
            $book =~ s/_\d+$//;    # remove page number

            $books->{$book}->{$page_no} = $subdir;
        } ## end for my $subdir (@subdirs)
    } ## end for my $dir (qw(train eval))

    #$self->render_not_found unless $self->render(template => "books");
    $self->reply->not_found unless $self->render(template => "books");
} ## end sub index

sub query {
    my $self = shift;
    my $book = $self->param('book');

    $self->redirect_to("/book/$book");
}

sub show {
    my $self = shift;

    # Render $page
    $self->reply->not_found unless $self->render();
}

1;
