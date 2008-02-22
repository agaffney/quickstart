#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Daemon;
use HTTP::Status;

my %conf = (
  port => 8899,
  bind_address => "0.0.0.0",
  debug => 1
);

sub debug {
  my $msg = shift;
  if($conf{debug}) {
    print "DEBUG: " . $msg . "\n";
  }
}

sub create_daemon {
  return HTTP::Daemon->new(
    LocalAddr => $conf{bind_address},
    LocalPort => $conf{port},
    Reuse => 1
  );
}

sub parse_request_url {
  my $url = shift;

  $url =~ /^([^?]+)(?:\?(.+))?$/;
  my $path = $1;
  my $args = {};
  if(defined $2) {
    foreach my $pair (split /&/, $2) {
      my @parts = split /=/, $pair;
      $args->{$parts[0]} = $parts[1];
    }
  }
  return ($path, $args);
}

sub send_response {
  my ($conn, $response) = @_;

  debug("Sending response: " . $response);
  $conn->send_basic_header(200);
  $conn->send_crlf;
  print $conn $response;
}

sub get_profile_path {
  my $mac = shift;

  my $profile_path;
  my @macparts = split /:/, $mac;

  if(0) {
    open TMP, "< /tmp/quickstartd.profiles";
    my @profiles;
    while(<TMP>) {
      chomp;
      my @parts = split /\s+/;
      push @profiles, \@parts;
    }
    close TMP;
  }

  my @profiles = (
    ["BB:CC:*", "/path/to/profile3"],
    ["AA:BB:CC:DD:*", "/path/to/profile1"],
    ["*", "/path/to/profile2"],
  );

  foreach my $profile (@profiles) {
    my @profile_macparts = split /:/, $profile->[0];
    my $match = 1;
    for(0..5) {
      last if($profile_macparts[$_] eq "*");
      if(lc($profile_macparts[$_]) ne lc($macparts[$_])) {
        $match = 0;
        last;
      }
    }
    if($match) {
      $profile_path = $profile->[1];
      last;
    }
  }

  if($profile_path =~ /^\//) {
    $profile_path = "quickstart://foo/get_profile?mac=" . $mac;
  }

  return $profile_path;
}

sub handle_request {
  my $conn = shift;

  my $request = $conn->get_request;
  my ($path, $args) = parse_request_url($request->url);

  my $debugargs = "";
  foreach(keys %{$args}) {
    $debugargs .= ($debugargs ? ", " : "") . $_ . "->" . $args->{$_};
  }
  debug("path=" . $path . ", args=" . $debugargs);

  if($request->method ne "GET") {
    $conn->send_error(RC_FORBIDDEN);
    return;
  }

  if($path eq "/get_profile_path") {
    send_response($conn, get_profile_path($args->{mac}));
  } elsif($path eq "/get_profile") {
    $conn->send_file_response(get_profile_path($args->{mac}));
  } else {
    debug("Sending 404");
    $conn->send_basic_header(404);
    $conn->send_crlf;
    print $conn "Unknown command";
  }
}

sub main {
  my $daemon = create_daemon();
  if(!defined $daemon) {
    print "!!! Could not create daemon\n";
    exit 1;
  }

  # Wait for connection
  while(my $conn = $daemon->accept) {
    debug("Accepted connection from " . $conn->peerhost() . ":" . $conn->peerport());
    handle_request($conn);
    $conn->close;
    debug("Connection closed");
  }

}

main();
