package Wocr::Page;
use Mojo::Base 'Mojolicious::Controller';

#use Mojo::Dom;
use XML::Twig;

use Data::Dumper;

my $xml  = {};
my $Page_imageFilename = '';

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

  my $page_image = '';
  for my $dir (keys %{$self->stash->{'config'}->{'ocr'}->{'pages'}}) {
    my $dir_name = $ocr_basedir . $self->stash->{'config'}->{'ocr'}->{'pages'}->{$dir};

    if (-f "$dir_name/$page.xml") {
      parse_xml("$dir_name/$page.xml",$lines);
      $page_image = $Page_imageFilename;
    }
    #if (-f "$dir_name/$page.jpg") {
    #  $page_image = "$page.jpg";
    #}
    #elsif (-f "$dir_name/$page.tif") {
    #  $page_image = "$page.jpg";
    #}
    #elsif (-f "$dir_name/$page.png") {
    #  $page_image = "$page.png";
    #}
  }

  #$self->app->log->debug(Dumper($xml));
  $self->app->log->debug("page_image: [$page_image]");

  my $line_count = 0;
  #/Users/helmut/github/ocr-gt/AustrianNewspapers/ gt/eval/  ONB_aze_18950706_4/ONB_aze_18950706_4.jpg_tl_1.gt.txt
  # $xml->{$RegionRefIndexed_index}->{$readingOrder} = $TextLine_id;
  for my $RegionRefIndexed_index (sort { $a <=> $b } keys %{$xml}) {
    $self->app->log->debug("RegionRefIndexed_index: [$RegionRefIndexed_index]");
    for my $readingOrder (sort { $a <=> $b } keys %{$xml->{$RegionRefIndexed_index}}) {
      $self->app->log->debug("readingOrder: [$readingOrder]");
      $line_count++;
      my $TextLine_id = $xml->{$RegionRefIndexed_index}->{$readingOrder};
      $self->app->log->debug("TextLine_id: [$TextLine_id]");
      # ONB_aze_18950706_4.jpg_line_1545181572766_4.gt.txt
      my $text_line_file = $page_image . '_' . $TextLine_id . '.gt.txt';
      $lines->{$line_count} = $text_line_file;
    }
  }

  $self->render_not_found
    unless $self->render(template => "page");
}

sub parse_xml {
  my ($xmlfile, $lines) = @_;
  $xml = {};
  my $twig = XML::Twig->new(
    #remove_cdata => 1,
    TwigHandlers => {
  	  '/PcGts/Page' => \&parse_page,
    },
  );
  eval { $twig->parsefile($xmlfile); };

  if ($@) {
    #print STDERR "XML PARSE ERROR: " . $@;
    die "XML PARSE ERROR: " . $@;
  }
  return ($xml);

}

#<ReadingOrder>
#      <OrderedGroup id="ro_1567004082174" caption="Regions reading order">
#        <RegionRefIndexed index="0" regionRef="r_1_1"/>

sub parse_page {
  my ($twig, $Page) = @_;

  # /PcGts
  # <Page imageFilename="ONB_ibn_18640702_006.tif"

  $Page_imageFilename = $Page->att('imageFilename');

  # <ReadingOrder>
  #    <OrderedGroup id="ro_1567004082174" caption="Regions reading order">
  #      <RegionRefIndexed index="0" regionRef="r_1_1"/>

  my $regions = {};

  my $ReadingOrder = $Page->first_child( 'ReadingOrder');
  my $OrderedGroup = $ReadingOrder->first_child( 'OrderedGroup');

  my @RegionRefIndexed = $OrderedGroup->children( 'RegionRefIndexed');
  for my $RegionRefIndexed (@RegionRefIndexed) {
    my $RegionRefIndexed_index = $RegionRefIndexed->att('index');
    my $regionRef = $RegionRefIndexed->att('regionRef');
    $xml->{$RegionRefIndexed_index} = {};
    #$xml->{'regions'}->{$regionRef} = $RegionRefIndexed_index;
    $regions->{$regionRef} = $RegionRefIndexed_index;
  }

  # <TextRegion type="paragraph" id="r_1_1" custom="readingOrder {index:0;}">
  #      <Coords points="737,35 836,35 836,79 737,79"/>
  #      <TextLine id="tl_1" primaryLanguage="German" custom="readingOrder {index:0;}">

  my @TextRegions = $Page->children('TextRegion');
  for my $TextRegion (@TextRegions) {
    my $RegionRef = $TextRegion->att('id');
    my $RegionRefIndexed_index = $regions->{$RegionRef};

    #my $textlines = {}; # collect textlines from line_files

    my @TextLines = $TextRegion->children( 'TextLine');

    for my $TextLine (@TextLines) {

	  my $TextLine_id  = $TextLine->att( 'id');
  	  my $custom       = $TextLine->att( 'custom');

	  my $readingOrder;
	  if ($custom =~ m/readingOrder\s*\{\s*index\s*:\s*(\d+)\s*;\s*\}/) {
   		$readingOrder = $1;
   		$xml->{$RegionRefIndexed_index}->{$readingOrder} = $TextLine_id;
   	  }
    }
  }
  return 1;
}



sub query {
  my $self = shift;
  my $page = $self->param('page');

  $self->redirect_to("/book/$page");
}



1;
