package MT::Fluent::Util;

use strict;
use warnings;
use Data::Dumper;
use Fluent::Logger;
use MT::Log;

use base qw(Exporter);

our @EXPORT = qw(plugin pp plugin_config fluent_log mt_log);

sub plugin { MT->component('Fluent'); }

sub pp { print STDERR Dumper(@_); }

sub plugin_config {
    my ( $blog_id, $param ) = @_;
    my $scope = $blog_id ? "blog:$blog_id" : "system";

    my %config;
    plugin->load_config(\%config, $scope);

    my $saving = 0;
    if ( ref $param eq 'HASH' ) {
        foreach my $k ( %$param ) {
            $config{$k} = $param->{$k};
        }
        $saving = 1;
    } elsif ( ref $param eq 'CODE' ) {
        $saving = $param->(\%config);
    }

    plugin->save_config(\%config, $scope) if $saving;
    \%config;
}

sub fluent_log {
    my ( $tag, $message, $config ) = @_;
    $config ||= plugin_config(0);

    my $logger = Fluent::Logger->new(
        host => $config->{fluentd_host},
        port => $config->{fluentd_port},
    );

    $message->{hostname} ||= $config->{fluent_this_hostname} if $config->{fluent_this_hostname};

    $logger->post($tag, $message);
}

sub mt_log {
    my ( $message, $param ) = @_;

    my $level = $param->{level} && $param->{level} eq 'error'
            ? MT::Log::ERROR()
            : $param->{level};

    my $log = MT::Log->new;
    $log->message();
    $log->blog_id( $param->{blog}->id ) if $param->{blog};
    $log->level( $level || MT::Log::INFO() );
    $log->category($param->{category} || 'log');
    $log->class($param->{class} || 'fluent');
    MT->log($log);
}

1;
