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
    +{ 'W' => [ '┳┻', 'color:black; background:red' ],
       'w' => [ '┴┬', 'color:white; background:brown' ],
       ' ' => [ ' ', 'background:white' ],
       map { $_ => [ chr $_ + 10101, 'color:purple; background:white' ] }
           1 .. 9,
   }->{ +shift }
}


sub draw_grid {
    my $robot = shift;
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
                                  'color: blue; background: white' ];

    template 'index', { grid     => \@grid,
                        cover    => nice($robot->grid->at($robot->coords)),
                        running  => $robot->is_running,
                        commands => [qw[ left forward drop-mark pick-mark ]],
                        command  => body_parameters->get('command'),
                      };
}


sub initialize_robot {
    my $robot = session('robot') || 'Karel::Robot'->new;
    unless ($robot->can('grid')) {
        my $grid  = 'Karel::Grid'->new( x => 10, y => 10 );
        $grid->build_wall(3, 3);
        $grid->drop_mark(4, 5);
        $robot->set_grid($grid, 5, 1, 'S');
    }
    return $robot
}


any '/' => sub {
    my $robot = initialize_robot();
    draw_grid($robot);
};


post '/run' => sub {
    my $robot = initialize_robot();
    my $action = {
        Run  => sub { $robot->run(body_parameters->get('command')) },
        Step => sub { $robot->step },
        Stop => sub { $robot->stop },
    }->{ body_parameters->get('action') };
    $action->();
    session robot => $robot;
    draw_grid($robot);
};


true;
