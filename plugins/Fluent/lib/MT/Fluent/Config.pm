package MT::Fluent::Config;

use strict;
use Sys::Hostname;
use warnings;
use MT::Fluent::Util;

sub system_config_template {
    my ( $plugin, $param, $scope ) = @_;
    my $app = MT->instance;

    my @fluents = (
        {
            key => 'fluent_log',
            label => plugin->translate('Log'),
            tag_key => 'fluent_log_tag',
            tag_label => plugin->translate('Log Tag'),
            description => plugin->translate('Send Movable Type logs to fluentd.'),
        },
        {
            key => 'fluent_usage',
            label => plugin->translate('Usage'),
            tag_key => 'fluent_usage_tag',
            tag_label => plugin->translate('Usage Tag'),
            description => plugin->translate('Send to fluentd log who used and how did it.'),
        },
        {
            key => 'fluent_error',
            label => plugin->translate('Error'),
            tag_key => 'fluent_error_tag',
            tag_label => plugin->translate('Error Tag'),
            description => plugin->translate('Send errors on Movable Type to fluentd.'),
        },
        {
            key => 'fluent_performance',
            label => plugin->translate('Performance'),
            tag_key => 'fluent_performance_tag',
            tag_label => plugin->translate('Performance Tag'),
            description => plugin->translate('Send performance time such as rebuilding to fluentd.'),
        },
    );

    $param->{fluents} = \@fluents;

    pp(\@fluents);

    # Hostname
    {
        my $hostname = 'localhost';
        my $cgi_path = $app->config->AdminCGIPath || $app->config->CGIPath;
        if ( $cgi_path =~ m!//(.+?)/! ) {
            $hostname = $1;
        } elsif ( my $http_host = $ENV{HTTP_HOST} ) {
            $hostname = $http_host;
        }

        $hostname =~ s!:(.+)!!;
        $hostname = hostname() if $hostname eq 'localhost';

        $param->{original_hostname} = $hostname;
        $param->{fluent_this_hostname} = $hostname
            if defined($param->{fluent_this_hostname}) && $param->{fluent_this_hostname} eq '0';
    }

    plugin->load_tmpl('system_config.tmpl');
}

sub blog_config_template {
    my ( $plugin, $param, $scope ) = @_;
    my $app = MT->instance;

    if ( $scope =~ /^blog:(\d+)/i ) {
        my @blog_ids = (0);
        my $blog_id = $1;
        if ( my $blog = MT->model('blog')->load($blog_id) ) {
            push @blog_ids, $blog_id;
            push @blog_ids, $blog->parent_id if $blog->is_blog;
        }

        my @templates = MT->model('template')->load({
            blog_id => \@blog_ids,
            type => 'custom',
        });

        @templates = sort {
            ( $a->{identifier} =~ /fluent/i ? -1 : 1 )
            || ( $a->{blog_id} <=> $b->{blog_id} );
        } map {
            +{
                template_id => $_->id,
                blog_id => $_->blog_id || 0,
                blog => $_->blog_id ? $_->blog->name : plugin->translate('System'),
                label => $_->name,
                identifier => $_->identifier || '',
            };
        } @templates;

        $param->{templates} = \@templates;
    }

    plugin->load_tmpl('blog_config.tmpl');
}

1;
