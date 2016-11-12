package MT::Fluent::System;

use strict;
use warnings;

use Time::HiRes qw(time);

use MT::Util;
use MT::Fluent::Util;
use MT::ErrorHandler;

sub install_fluent_log {
    my ( $config ) = @_;

    MT->add_callback( 'MT::Log::post_insert', 9, plugin, sub {
        my ( $cb, $log ) = @_;
        my %message = %{$log->{column_values}};

        my $blog = MT->model('blog')->load({id => $message{blog_id}});
        my $author = MT->model('author')->load({id => $message{author_id}});
        $message{blog} = $blog ? $blog->name : plugin->translate('System');
        $message{author} = $author->name if $author;

        fluent_log($config->{fluent_log_tag}, \%message, $config);
        1;
    });
}

sub install_fluent_error {
    my ( $config ) = @_;

    {
        # MT::ErrorHandler
        no warnings qw( redefine );
        my $__error = \&MT::ErrorHandler::error;
        *MT::ErrorHandler::error = sub {
            my ( $class, $msg ) = @_;
            my $app = MT->instance;

            if ( defined $msg ) {
                eval {
                    my %message = (error => 'mt');
                    if ( ref $class ) {
                        $message{class} = ref $class;
                        # foreach my $key (qw/id name title/) {
                        #     my $value = eval { $class->$key };
                        #     $message{$key} = $value if defined($value);
                        # }
                    } else {
                        $message{class} = $class;
                    }

                    if ( my $author = $app->user ) {
                        $message{author_id} = $author->id;
                        $message{author} = $author->name;
                    }

                    $message{message} = $msg;
                    $message{message} =~ s/\n+$//;
                    fluent_log($config->{fluent_error_tag}, \%message, $config);
                };
            }

            $__error->(@_);
        };
    }

    {
        my $__die = \&CORE::GLOBAL::die;
        *CORE::GLOBAL::die = sub {
            my ( $message ) = @_;
            my %message = ( source => 'die' );
            $message{message} = $message;
            eval {
                fluent_log($config->{fluent_error_tag}, \%message, $config);
            };
            $__die->(@_);
        };
    }
}

sub install_fluent_usage {
    my ( $config ) = @_;

    MT->add_callback( 'init_request', 0, plugin, sub {
        my ( $cb, $app ) = @_;
        my $req = $app->request;

        my %message = ( started => time );
        foreach my $key (qw/__mode _type id blog_id/) {
            my $value = $app->param($key);
            $message{$key} = $value if defined($value);
        }

        $req->cache('fluent_usage', \%message);

        1;
    });

    MT->add_callback('take_down', 8, plugin, sub {
        my ( $cb, $app ) = @_;
        my $req = $app->request;

        if ( my $message = $req->cache('fluent_usage') ) {
            my $finished = time;
            $message->{duration} = $finished - $message->{started};
            delete $message->{started};

            if ( my $user = $app->user ) {
                $message->{author_id} = $user->id;
                $message->{author} = $user->name;
            }

            if ( my $type = $message->{_type} ) {
                my $class_label = eval { MT->model($type)->class_label };
                $message->{class_label} = $class_label if defined $class_label;
            }

            if ( my $blog_id = $message->{blog_id} ) {
                if ( my $blog = MT->model('blog')->load({class => '*', id => $blog_id}) ) {
                    $message->{blog} = $blog->name;
                } else {
                    $message->{blog} = plugin->translate('System');
                }
            }

            fluent_log($config->{fluent_usage_tag}, $message, $config);
        }

        1;
    });
}

sub install_fluent_performance {
    my ( $config ) = @_;

    MT->add_callback('take_down', 9, plugin, sub {
        my ( $cb, $app ) = @_;
        my $timer = MT->get_timer() || return 1;

        my $req = $app->request->cache('fluent_usage');

        my $dur = $timer->{dur};
        foreach my $d ( @$dur ) {
            my %message = $req ? %$req : ();
            $message{duration} = $d->[2] || 0;

            my $label = $d->[1] || '';
            if ( $label =~ /^(.+?)\[(.+)\]/ ) {
                $message{mark} = $1;
                $message{arg} = $2;
                if ( $message{arg} =~ /[:;]/ ) {
                    my %args;
                    my @pairs = split(/;/, $message{arg});
                    foreach my $p ( @pairs ) {
                        my ( $key, $value ) = split(/:/, $p, 2);
                        $message{"arg_$key"} = $value;
                    }
                } else {
                    $message{arg_value} = $message{arg};
                }
            } else {
                $message{mark} = $1;
            }

            fluent_log($config->{fluent_performance_tag}, \%message, $config);
        }

        1;
    });
}

sub on_post_init {
    my ( $cb, $app ) = @_;
    return 1 if ref $app ne 'MT'; # Accept for only MT.

    my $config = plugin_config(0);

    install_fluent_log($config) if $config->{fluent_log};
    install_fluent_error($config) if $config->{fluent_error};
    install_fluent_usage($config) if $config->{fluent_usage};
    install_fluent_performance($config) if $config->{fluent_performance};

    1;
}

1;
