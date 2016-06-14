package Karel::UI::Web;
use Dancer2;
use utf8;

use Karel::Robot;
use Karel::Grid;

our $VERSION = '0.1';


{   # For DEBUG only!
    package Karel::Parser::Exception;
    use Data::Dumper;

    use overload '""' => sub { Dumper(@_) };

}


sub nice {
    +{ 'W' => [ '┳┻', 'thickwall' ],
       'w' => [ '┴┬', 'thinwall' ],
       ' ' => [ ' ', 'empty' ],
       map { $_ => [ chr $_ + 10101, 'mark' ] }
           1 .. 9,
   }->{ +shift }
}


sub draw_grid {
    my ($robot) = @_;
    my @grid;
    for my $x (0 .. $robot->grid->x + 1) {
        for my $y ( 0 .. $robot->grid->y + 1) {
            $grid[$y][$x] = nice($robot->grid->at($x, $y));
        }
    }
    $grid[$robot->y][$robot->x] = [ { N => '⬆',
                                      S => '⬇',
                                      W => '⬅',
                                      E => '➡'
                                    }->{ $robot->direction },
                                  'robot' ];

    template 'index', { grid     => \@grid,
                        cover    => nice($robot->grid->at($robot->coords)),
                        running  => $robot->is_running,
                        commands => [qw[ left forward drop-mark pick-mark ],
                                     keys %{ $robot->knowledge // {} } ],
                        command  => body_parameters->get('command') || body_parameters->get('last_command'),
                        fast     => session 'fast',
                      };
}


sub initialize_robot {
    my $robot = session('robot') || 'Karel::Robot'->new;
    unless ($robot->can('grid')) {
        my $grid  = 'Karel::Grid'->new( x => 9, y => 9 );
        $grid->build_wall(@$_) for [2, 2], [8, 2], [2, 8], [8, 8];
        my @marks = ( [4, 4], [5, 4], [6, 4],
                      [4, 5], [5, 5], [6, 5],
                      [4, 6], [5, 6], [6, 6],
                     );
        do { $grid->drop_mark(@$_) for @marks } while shift @marks;
        $robot->set_grid($grid, 5, 1, 'S');
    }
    return $robot
}


any '/' => sub {
    my $robot = initialize_robot();
    my $action = {
        Start => sub { session fast => 0; $robot->run(body_parameters->get('command')) },
        Step  => sub { $robot->step },
        Stop  => sub { session fast => 0; $robot->stop },
        Run   => sub { session fast => 1; $robot->step },
        Learn => sub { $robot->learn(body_parameters->get('editor')) },
    }->{ body_parameters->get('action') };
    if ($action) {
        $action->();
        session robot => $robot;
    }
    draw_grid($robot);
};


post '/upload' => sub {
    my $file = upload('source');
    my $FH = $file->file_handle;
    my $robot = initialize_robot();
    $FH->input_record_separator(undef);
    $robot->learn(<$FH>);
    session robot => $robot;
    forward '/'
};

true;
