package KM;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use Moose;
use URI::Escape;
use LWP::UserAgent;
use HTTP::Request;
use namespace::autoclean;

has 'id' => ( isa => 'Str', is => 'rw', clearer => 'clear_id' );
has 'host' => ( isa => 'Str', is => 'rw', default => 'trk.kissmetrics.com:80' );
has 'log_dir' => ( isa => 'Str', is => 'rw', default => '/tmp' );
has 'key' => ( isa => 'Str', is => 'rw', clearer => 'clear_key' );
has 'logs' => ( isa => 'HashRef', is => 'rw', default => sub { {} }, clearer => 'clear_logs' );
has 'user_agent' => ( isa => 'LWP::UserAgent', is => 'rw', lazy_build => 1 );
has 'to_stderr' => ( isa => 'Bool', is => 'ro', default => 1 );
has 'use_cron' => ( isa => 'Bool', is => 'ro' );

sub BUILD {
    my ($self, $params) = @_;
    $self->_log_dir_writeable;      
}

sub identify {
    my ($self, $id) = @_;
    $self->id($id);
}

sub record {
    my ($self, $action, $props) = @_;
    $props = {} unless defined ($props);
    return undef unless $self->_is_initialized_and_identified;
    return $self->set($action) if (ref($action) eq 'HASH');
    $props->{'_n'} = $action;
    $self->_generate_query('e', $props);
}

sub alias {
    my ($self, $name, $alias_to) = @_;
    return unless $self->_is_identified;
    $self->_generate_query('a', { '_n' => $alias_to, '_p' => $name }, 0);
}

sub set {
    my ($self, $data) = @_;
    return unless $self->_is_initialized_and_identified;
    $self->_generate_query('s', $data);
}

sub send_logged_queries {
    my $self = shift;
    my $line;
    
    return unless (-f $self->_log_name('query'));
    rename($self->_log_name('query'), $self->_log_name('send'));
    
    my $log = $self->_log_name('send');
    eval {
        open(SEND, "<", $log) or die "Couldn't open log file $log: $!";
        while (<SEND>) {
            chomp($_);
            eval {
                $self->_send_query($_);
            };
            if ($@) {
                $self->_log_query($_) if ($_);
                $self->_log_error($@);
            }
        }
        close SEND;
        unlink $log;
    };
    if ($@) {
        $self->_log_error($@);
    }
}

sub _reset {
    my $self = shift;
    $self->clear_id;
    $self->clear_key;
    $self->clear_logs;
}

sub _user_agent {
    
}

sub _log_name {
    my ($self, $type) = @_;
    return $self->logs->{$type} if ($self->logs->{$type});
    my $fname;
    if ($type eq 'error') {
        $fname = 'kissmetrics_error.log';
    }
    elsif ($type eq 'query') {
        $fname = 'kissmetrics_query.log';
    }
    elsif ($type eq 'send') {
        $fname = time . 'kissmetrics_sending.log';
    }
    $self->logs->{$type} = join '/', ($self->log_dir, $fname);
    return $self->logs->{$type};
}

sub _log_query {
    my ($self, $msg) = @_;
    $self->_log('query', $msg);
}

sub _log_send {
    my ($self, $msg) = @_;
    $self->_log('send', $msg);
}

sub _log_error {
    my ($self, $msg) = @_;
    $msg = sprintf("<%s> %s", (time, $msg));
    print STDERR $msg if ($self->to_stderr);
    $self->_log('error', $msg);
}

sub _log {
    my ($self, $type, $msg) = @_;
    my $log = $self->_log_name($type);
    eval {
        open(FH, ">>", $log) or die "Couldn't open log file $log: $!";
        print FH "$msg\n";
        close FH;        
    };
    if ($@) {
        # the Ruby method ignores this.
        # probably wise, since there's no place to log the error.
        # shoulders of giants, etc.
    }
    return;
}

sub _generate_query {
    my ($self, $type, $data, $update) = @_;
    $update = 1 unless defined ($update);
    my $query;
    my @query_params;
    $data->{'_p'} = $self->id unless ($update == 0);
    $data->{'_k'} = $self->key;
    $data->{'_t'} = time;
    foreach (keys %$data) {
        push @query_params, join '=', ( uri_escape($_) ,uri_escape($data->{$_}) );
    }
    my $params = join '&', @query_params;
    $query = join '', (
                            '/', 
                            $type,
                            '?', 
                            $params,
                      );
    if ($self->use_cron) {
        $self->_log_query($query);
    }
    else {
        eval {
            $self->_send_query($query);
        };
        if ($@) {
            $self->_log_query($query);
            $self->_log_error($@);
        }
    }
}

sub _send_query {
    my ($self, $line) = @_;
    my ($host, $port) = split ':', $self->host;
    my $uri  = "http://";
    $uri .= join '', ($self->host, $line); 
    my $request = HTTP::Request->new('GET' => $uri);
    print "sending $uri\n";
    eval {
        $self->user_agent->request($request);
    };
    if ($@) {
        $self->_log_error($@);
    }
}

sub _log_dir_writeable {
    my $self = shift;
    unless (-d $self->log_dir && -w $self->log_dir) {
        my $die_error = sprintf "Couldn't open %s for writing. Does %s exist? Permissions?", ($self->_log_name('query'), $self->log_dir);
        die $die_error;
    }
    return;
}

sub _is_identified {
    my $self = shift;
    if (!$self->id) {
        $self->_log_error("Need to identify first (\$KM->identify(<user>))");
        return undef;
    }
    return 1;
}

sub _is_initialized_and_identified {
    my $self = shift;
    return undef unless $self->_is_initialized;
    return $self->_is_identified;
}

sub _is_initialized {
    my $self = shift;
    if (!$self->key) {
        $self->_log_error("Need to initialize first (\$KM->init(<your_key>))");
        return undef;
    }
    return 1;
}

sub _build_user_agent {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $self->user_agent($ua);
}

__PACKAGE__->meta->make_immutable;

1;

