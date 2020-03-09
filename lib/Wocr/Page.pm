package Wocr::Page;
use Mojo::Base 'Mojolicious::Controller';

#use Mojo::Dom;

sub index {
  my $self = shift;

  my $page = $self->param('page');
  #/Users/helmut/github/ocr-gt/AustrianNewspapers/
  my $ocr_basedir = $self->stash->{'config'}->{'ocr'}->{'basedir'};

  my $lines = {};
  my $pagedir = '';
  my $book = '';

  $self->stash('_book'    => $book);
  $self->stash('_pagedir' => $pagedir);
  $self->stash('_page'    => $page);
  $self->stash('_lines'   => $lines);

  #/Users/helmut/github/ocr-gt/AustrianNewspapers/ gt/eval/  ONB_aze_18950706_4/ONB_aze_18950706_4.jpg_tl_1.gt.txt
  for my $dir (keys %{$self->stash->{'config'}->{'ocr'}->{'lines'}}) {
    my $dir_name = $ocr_basedir . $self->stash->{'config'}->{'ocr'}->{'lines'}->{$dir};
    opendir(my $dir_dh, "$dir_name") || die "Can't opendir $dir_name: $!";
    my @subdirs = grep { /^[^._]/ && -d "$dir_name/$_" } readdir($dir_dh);
    closedir $dir_dh;

    # ONB_aze_18950706_4
    for my $subdir (@subdirs) {
        next unless ($subdir eq $page);
        $pagedir = $subdir;
        $book = $subdir;
        $book =~ s/_\d+$//; # remove page number

        my $subdir_name = $dir_name . '/' . $subdir;
        opendir(my $subdir_dh, "$subdir_name") || die "Can't opendir $subdir_name: $!";
        my @lines = grep { /^[^._]/ && /\.txt$/i && -f "$subdir_name/$_" } readdir($subdir_dh);
        closedir $subdir_dh;

        # ONB_aze_18950706_4.jpg_tl_1.gt.txt
        for my $line (@lines) {
            my $line_no = 0;
            if ($line =~m/_(\d+)\.gt\.txt$/) {
                $line_no = $1;
            }
            $lines->{$line_no} = $line;
        }
    }
  }

  $self->render_not_found
    unless $self->render(template => "page");
}


sub query {
  my $self = shift;
  my $page = $self->param('page');

  $self->redirect_to("/book/$page");
}

=pod

sub show {
  my $self = shift;

  # /skins/<%= $skin %>/css/bootstrap.min.css
  my $file1 = '/Users/helmut/github/perl/Wocr/share/files/public/pages/isis_152.hocr.html';
  my $scan = '/pages/isis_152.jpg';

  open(my $in1,"<:encoding(UTF-8)",$file1) or die "cannot open $file1: $!";

  my $html = '';
  while (my $line = <$in1>) { $html .= $line;}

  my $dom = Mojo::DOM->new($html);

  my $content = $dom->at('div.ocr_page');

  #$self->stash(hocr => $content);
  #$self->stash(hocr => 'test');
  $self->stash->{hocr} = $content;
  $self->stash->{scan} = $scan;

  # Render $page
  #$self->render_not_found  unless
    $self->render();
}

=cut

1;
