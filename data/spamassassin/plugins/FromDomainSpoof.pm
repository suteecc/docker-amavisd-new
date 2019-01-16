package FromDomainSpoof;
my $VERSION = 0.8;

use strict;

use Mail::SpamAssassin::Plugin;
use List::Util ();
use Mail::SpamAssassin::Util;

use vars qw(@ISA);
@ISA = qw(Mail::SpamAssassin::Plugin);

sub uri_to_domain {
  my ($self, $domain) = @_;

  return unless defined $domain;

  if ($Mail::SpamAssassin::VERSION <= 3.004000) {
    Mail::SpamAssassin::Util::uri_to_domain($domain);
  } else {
    $self->{main}->{registryboundaries}->uri_to_domain($domain);
  }
}

# constructor: register the eval rule
sub new
{
  my $class = shift;
  my $mailsaobject = shift;

  # some boilerplate...
  $class = ref($class) || $class;
  my $self = $class->SUPER::new($mailsaobject);
  bless ($self, $class);


  # the important bit!
  $self->register_eval_rule("check_fromname_domainname_differ");
  $self->register_eval_rule("check_fromname_contains_domain");
  return $self;
}

sub check_fromname_domainname_differ
{
  my ($self, $pms) = @_;
  $self->_check_fromdomainspoof($pms);
  return $pms->{fromname_domain_different};
}

sub check_fromname_contains_domain
{
  my ($self, $pms) = @_;
  $self->_check_fromdomainspoof($pms);
  return $pms->{fromname_contains_domain};
}

sub _check_fromdomainspoof
{
  my ($self, $pms) = @_;

  return if (defined $pms->{fromname_contains_domain});

  $pms->{fromname_contains_domain} = 0;
  $pms->{fromname_domain_different} = 0;

  foreach my $addr (split / /, $pms->get_tag('DKIMDOMAIN') || '') {
    return 0 if ($self->{main}{conf}{fns_ignore_dkim}{$addr});
  }

  foreach my $iheader (keys %{$self->{main}{conf}{fns_ignore_header}}) {
    return 0 if ($pms->get($iheader));
  }

  my $list_refs = {};

  foreach my $conf (keys %{$self->{main}{conf}}) {
    if ($conf =~ /^FNS_/) {
      $list_refs->{$conf} = $self->{main}{conf}{$conf};
    }
  }

  my %fnd = ();
  my %fad = ();

  $fnd{'addr'} = $pms->get("From:name");

  if ($fnd{'addr'} =~ /\b([\w\-\.]+\.[\w\-\.]++)\b/i) {

    my $nochar = ($fnd{'addr'} =~ y/A-Za-z0-9//c);
    $nochar -= ($1 =~ y/A-Za-z0-9//c);

    return 0 unless ((length($fnd{'addr'})+$nochar) - length($1) <= $self->{main}{conf}{'fns_extrachars'});

    $fnd{'addr'} = lc $1;
  } else {
    return 0;
  }

  $fad{'addr'} = lc $pms->get("From:addr");

  $fnd{'domain'} = $self->uri_to_domain($fnd{'addr'});
  $fad{'domain'} = $self->uri_to_domain($fad{'addr'});

  return 0 unless (defined $fnd{'domain'} && defined $fad{'domain'});

  $pms->{fromname_contains_domain} = 1;

  $pms->{fromname_domain_different} = 1 if ($fnd{'domain'} ne $fad{'domain'});

}

1;
