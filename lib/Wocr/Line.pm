package Wocr::Line;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $self = shift;

  my $line = $self->param('line');
  #/Users/helmut/github/ocr-gt/AustrianNewspapers/
  my $ocr_basedir = $self->stash->{'config'}->{'ocr'}->{'basedir'};

  my $page = $line;
  $page =~ s/\.(jpg|tif).*$//i;

  my $book = $page;
  $book    =~ s/_\d+$//; # remove page number

  my $lines = {};
  my $pagedir = '';

  my $text  = '###not found###';
  my $image = '###not found###';

  $self->stash('_book'    => $book);
  $self->stash('_text'    => $text);
  $self->stash('_image'   => $image);
  $self->stash('_pagedir' => $pagedir);
  $self->stash('_page'    => $page);
  $self->stash('_line'    => $line);
  $self->stash('_ocr_basedir'    => $ocr_basedir);

  #/Users/helmut/github/ocr-gt/AustrianNewspapers/ gt/eval/  ONB_aze_18950706_4/ONB_aze_18950706_4.jpg_tl_1.gt.txt
  #                                                                             ONB_aze_18950706_4.jpg_tl_1.png
  #for my $dir (qw(line_train line_eval)) {
  for my $dir (keys %{$self->stash->{'config'}->{'ocr'}->{'lines'}}) {
    my $dir_name = $ocr_basedir . $self->stash->{'config'}->{'ocr'}->{'lines'}->{$dir};
    opendir(my $dir_dh, "$dir_name") || die "Can't opendir $dir_name: $!";
    my @subdirs = grep { /^[^._]/ && /$page/ && -d "$dir_name/$_" } readdir($dir_dh);
    closedir $dir_dh;

    # ONB_aze_18950706_4
    for my $subdir (@subdirs) {
        $self->app->log->debug("subdir: [$subdir] page: [$page]");
        #next unless ($subdir eq $page);
        next unless ($subdir =~ m/$page/);
        $self->app->log->debug("found page: [$page]");
        $pagedir = $subdir;

        my $subdir_name = $dir_name . '/' . $subdir;

        my $text_file = $subdir_name . '/' . $line;

        $self->app->log->debug("text_file: [$text_file]");

        #if (-f $text_file) {
            open(my $in,"<:encoding(UTF-8)",$text_file)
              #or die "cannot open $text_file: $!";
              or $self->app->log->debug("cannot open $text_file: $!");

            $text = <$in>;
            chomp $text;
        $self->app->log->debug("text: [$text]");
        $self->stash('_text'   => $text);
            close $in;
        #}

        $image = '/' . $self->stash->{'config'}->{'ocr'}->{'lines'}->{$dir}
            . '/' . $subdir . '/' . $line;
        $image =~ s/gt\.txt/png/;
        $self->app->log->debug("image: [$image]");
        $self->stash('_image'   => $image);
        last;
    }
  }

  $self->render_not_found
    unless $self->render(template => "line");
}




# http://127.0.0.1:3000/gt/train/ONB_aze_18950706_1/ONB_aze_18950706_1.jpg_tl_1.gt.txt
# http://127.0.0.1:3000/gt/train/ONB_aze_18950706_1/ONB_aze_18950706_1.jpg_tl_1.png

1;
