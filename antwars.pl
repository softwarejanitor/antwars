#!/usr/bin/perl

#
# ants:
#
# TODO:
#  *add code to add red ants at random locations as score increases
#  *add "food" pellets which randomly appear and are worth 10 pts
#   don't allow ants to cross rock
#   make the background maps load levels
#   make the whole screen scroll over a larger area
#   draw the score and level information on the screen
#  *add a splash screen
#   add high scores
#   add sounds
#      game start
#     *player dies
#      new life start
#     *player gets extra life
#      player levels up
#      game over
#  *add 'lives'
#  *add brown ant for additional lives
#   add player death animation
#   add player extra life animation
#   add player level up animation
#   re-start level if player dies
#

use strict;
use SDL;
use SDL::Rect;
use SDL::Color;
use SDL::Video;
use SDL::Image;
use SDL::Surface;
use SDL::Event;
use SDL::Events;
use SDLx::App;
use SDLx::Rect;
use SDLx::Sprite;
use SDLx::Sound;
#use SDL::Mixer;
use SDLx::Text;
use POSIX qw ( floor ceil );

# playable screen size
use constant SCREEN_WIDTH  => 640;
use constant SCREEN_HEIGHT => 480;

# size of score/lives portion of window at bottom
use constant SCORE_SIZE    => 128;
# window size
use constant WINDOW_WIDTH  => SCREEN_WIDTH;
use constant WINDOW_HEIGHT => SCREEN_HEIGHT + SCORE_SIZE;

# size of ant sprites
use constant SPRITE_SIZE   =>  32;  # 32x32 pixels

# size of food sprite
use constant FOOD_SPRITE_SIZE =>  16;  # 16x16 pixels

# number of points for food
use constant FOOD_SCORE => 10;

# number of pixels to move
use constant MOVE_INCREMENT => 5;

# initial number of red ants
use constant MIN_RED_ANTS  =>   4;
# maximum number of red ants
use constant MAX_RED_ANTS  =>  16;

# how often to insert additional red ants
use constant RED_ANT_ADD_INTERVAL => 1000;

# for speed larger # is slower
# initial red ant speed
use constant MIN_RED_ANT_SPEED => 100;
# fastest red ant speed
use constant MAX_RED_ANT_SPEED => 2;
# how often to increase speed of red ants
use constant RED_ANT_SPEED_CHANGE_INTERVAL => 100;
# amount to change red ant speed each time
use constant RED_AND_SPEED_CHANGE_AMOUNT => 2;

# how often to insert brown ant
use constant BROWN_ANT_INTERVAL => 500;

# how often to insert food
use constant FOOD_INTERVAL => 50;

# symbolic direction numbers
use constant LEFT  => 0;
use constant RIGHT => 1;
use constant UP    => 2;
use constant DOWN  => 3;

# color for transparency
use constant COLORKEY_RED   => 224;
use constant COLORKEY_GREEN => 102;
use constant COLORKEY_BLUE  => 255;

# symbolic background texture numbers
use constant GRASS => 0;
use constant SAND  => 1;
use constant DIRT  => 2;
use constant ROCK  => 3;

# initial number of black ants
use constant INITIAL_LIVES => 3;

# symbolic background texture array
my @bgTextures = ( GRASS, SAND, DIRT, ROCK );

# bitmaps for background textures
my @bgBitmaps = ( 'grass.bmp', 'sand.bmp', 'dirt.bmp', 'rock.bmp' );

# this gets set when game is over
my $gameover = 0;

# initialize running counter of current black ants
my $lives = INITIAL_LIVES;

# initialize score
my $score = 0;

# initialize current number of red ants and speed
my $cur_red_ants = MIN_RED_ANTS;
my $cur_red_ant_speed = MIN_RED_ANT_SPEED;

# source and destination rectangles for black ant
my $blackAnt = SDLx::Rect->new(128, 0, SPRITE_SIZE, SPRITE_SIZE);
my $rcBlackAntSprite = SDLx::Rect->new(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, SPRITE_SIZE, SPRITE_SIZE);

# source and destination rectangles for red ants
my @rcRedAntSprite;
my @redAnt;
for (my $redant = 0; $redant < MAX_RED_ANTS; $redant++) {
  $redAnt[$redant] = SDLx::Rect->new(128, 0, SPRITE_SIZE, SPRITE_SIZE);
  $rcRedAntSprite[$redant] = SDLx::Rect->new(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, SPRITE_SIZE, SPRITE_SIZE);
}

# this is set when brown ant is on the screen
my $brownAntActive = 0;

# source and destination rectangles for brown ant
my $brownAnt = SDLx::Rect->new(128, 0, SPRITE_SIZE, SPRITE_SIZE);
my $rcBrownAntSprite = SDLx::Rect->new(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, SPRITE_SIZE, SPRITE_SIZE);

# this is set when food is on the screen
my $foodActive = 0;

# source and destination rectangles for food
my $food = SDLx::Rect->new(0, 0, FOOD_SPRITE_SIZE, FOOD_SPRITE_SIZE);  # SDL_Rect
my $rcFoodSprite = SDLx::Rect->new(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, FOOD_SPRITE_SIZE, FOOD_SPRITE_SIZE);

my @rcBgndRect;  # SDL_Rect

# initialize rectangles for each background texture type
foreach my $bgndtype (@bgTextures) {
  $rcBgndRect[$bgndtype] = SDLx::Rect->new(0, 0, SPRITE_SIZE, SPRITE_SIZE);
}

# handle events
sub HandleEvent()
{
  my $event = shift;  # SDL::Event

  my $event_type = $event->type;
  # close button clicked
  if ($event_type == SDL_QUIT) {
    # set game over
    $gameover = 1;
  # handle the keyboard
  } elsif ($event_type == SDL_KEYDOWN) {
    my $key_sym = $event->key_sym;
    if ($key_sym == SDLK_ESCAPE || $key_sym == SDLK_q) {
      # set game over
      $gameover = 1;
    } elsif ($key_sym == SDLK_LEFT) {
      # move black ant left
      if ( $blackAnt->x() == 192 ) {
        $blackAnt->x(224);
      } else {
        $blackAnt->x(192);
      }
      $rcBlackAntSprite->x($rcBlackAntSprite->x() - MOVE_INCREMENT);
    } elsif ($key_sym == SDLK_RIGHT) {
      # move black ant right
      if ( $blackAnt->x() == 64 ) {
        $blackAnt->x(96);
      } else {
        $blackAnt->x(64);
      }
      $rcBlackAntSprite->x($rcBlackAntSprite->x() + MOVE_INCREMENT);
    } elsif ($key_sym == SDLK_UP) {
      # move black ant up
      if ( $blackAnt->x() == 0 ) {
        $blackAnt->x(32);
      } else {
        $blackAnt->x(0);
      }
      $rcBlackAntSprite->y($rcBlackAntSprite->y() - MOVE_INCREMENT);
    } elsif ($key_sym == SDLK_DOWN) {
      # move black ant down
      if ( $blackAnt->x() == 128 ) {
        $blackAnt->x(160);
      } else {
        $blackAnt->x(128);
      }
      $rcBlackAntSprite->y($rcBlackAntSprite->y() + MOVE_INCREMENT);
    }
  }
}

# re-draw background just behind moving sprites
sub redraw_background
{
  my $screen = shift;
  my $x = shift;
  my $y = shift;
  my $size = shift;
  my $bgndRef = shift;
  my $rcBgndRectRef = shift;
  my $bgndSurfaceRef = shift;

  my @bgnd = @{$bgndRef};
  my @rcBgndRect = @{$rcBgndRectRef};
  my @bgndSurface = @{$bgndSurfaceRef};

  # only redraw the parts that changed
  my $redrawX1 = POSIX::floor(($x - $size) / $size) - 1;
  my $redrawY1 = POSIX::floor(($y - $size) / $size) - 1;
  my $redrawX2 = POSIX::ceil(($x + $size) / $size) + 1;
  my $redrawY2 = POSIX::ceil(($y + $size) / $size) + 1;

  if ($redrawX1 < 0) {
    $redrawX1 = 0;
  }
  if ($redrawX2 > (SCREEN_WIDTH / $size)) {
    $redrawX2 = SCREEN_WIDTH / $size;
  }
  if ($redrawY1 < 0) {
    $redrawY1 = 0;
  }
  if ($redrawY2 > (SCREEN_HEIGHT / $size)) {
    $redrawY2 = SCREEN_HEIGHT / $size;
  }

  # re-draw the grass/sand/dirt/rock
  for (my $x = $redrawX1; $x < $redrawX2; $x++) {
    for (my $y = $redrawY1; $y < $redrawY2; $y++) {
      my $bg = $bgnd[$x][$y];
      $rcBgndRect[$bg]->x($x * $size);
      $rcBgndRect[$bg]->y($y * $size);
      SDL::Video::blit_surface($bgndSurface[$bg], undef, $screen, $rcBgndRect[$bg]);
    }
  }
}

# re-draw entire background
sub redraw_whole_background
{
  my $screen = shift;
  my $bgndRef = shift;
  my $rcBgndRectRef = shift;
  my $bgndSurfaceRef = shift;

  my @bgnd = @{$bgndRef};
  my @rcBgndRect = @{$rcBgndRectRef};
  my @bgndSurface = @{$bgndSurfaceRef};

  # re-draw the grass/sand/dirt/rock
  for (my $x = 0; $x < SCREEN_WIDTH / SPRITE_SIZE; $x++) {
    for (my $y = 0; $y < SCREEN_HEIGHT / SPRITE_SIZE; $y++) {
      my $bg = $bgnd[$x][$y];
      $rcBgndRect[$bg]->x($x * SPRITE_SIZE);
      $rcBgndRect[$bg]->y($y * SPRITE_SIZE);
      SDL::Video::blit_surface($bgndSurface[$bg], undef, $screen, $rcBgndRect[$bg]);
    }
  }
}

# check for an ant colliding with edge of screen
sub edge_collide
{
  my $mySprite = shift;
  my $size = shift;

  if ($mySprite->x() <= 0) {
    $mySprite->x(0);
  }
  if ($mySprite->x() >= SCREEN_WIDTH - $size)  {
    $mySprite->x(SCREEN_WIDTH - $size);
  }

  if ($mySprite->y() <= 0) {
    $mySprite->y(0);
  }
  if ($mySprite->y() >= SCREEN_HEIGHT - $size) {
    $mySprite->y(SCREEN_HEIGHT - $size);
  }
}

# check for collision between two sprites
sub collision_check
{
  my $x1 = shift;
  my $y1 = shift;
  my $x2 = shift;
  my $y2 = shift;
  my $size = shift;

  if ($x1 >= ($x2 - $size) &&
      $x1 <= ($x2 + $size) &&
      $y1 >= ($y2 - $size) &&
      $y1 <= ($y2 + $size)) {
    return 1;
  }
  return 0;
}

# main
{
  my $screen;  # SDL_Surface
  my $temp;  # SDL_Surface
  my $blackAntSprite;  # SDL_Surface
  my $redAntSprite;  # SDL_Surface
  my $brownAntSprite;  # SDL_Surface
  my @bgndSurface;  # SDL_Surface
  my $foodSprite;  # SDL_Surface
  my $colorkey = 0;

  srand(time());

  # set the title bar
  my $app = SDLx::App->new( 
      title  => 'Ant Wars',
      width  => WINDOW_WIDTH,
      height => WINDOW_HEIGHT,
      depth  => 32
  );

  # initialize SDL
  SDL::init(SDL_INIT_VIDEO);

  # create window
  $screen = SDL::Video::set_video_mode(WINDOW_WIDTH, WINDOW_HEIGHT, 0, 0);

  # set keyboard repeat
  SDL::Events::enable_key_repeat(70, 70);

  # set up sound
  my $snd = SDLx::Sound->new();

  # set up sound files
  #my %sndFiles = (
  #  die       => "/die.wav",
  #  extralife => "/extralife.wav"
  #);

  # load in sound files for realtime play
  #$snd->load(%sndFiles);

  # set volume on all sound files to 100%
  #foreach my $sndFile (keys %sndFiles) {
  #  $snd->loud($sndFile, 100);
  #}
  #my $sndDie = SDLx::Sound->new();
  #$sndDie->load('die.wav');
  #my $sndExtralife = SDLx::Sound->new();
  #$sndExtralife->load('extralife.wav');
  #my $mixer = SDL::Mixer->new(
  #  -frequency => MIX_DEFAULT_FREQUENCY,
  #  -format    => MIX_DEFAULT_FORMAT,
  #  -channels  => MIX_DEFAULT_CHANNELS,
  #  -size      => 4096
  #);

  #my $dieSound = new SDL::Sound('die.wav');
  #$dieSound->volume(128);
  #my $extralifeSound = new SDL::Sound('extralife.wav');
  #$extralifeSound->volume(128);

  #$mixer->music_volume(MIX_MAX_VOLUME);

  # load black ant sprite
  $temp   = SDL::Video::load_BMP("blackants.bmp");
  $blackAntSprite = SDL::Video::display_format($temp);

  # load red ant sprite
  $temp   = SDL::Video::load_BMP("redants.bmp");
  $redAntSprite = SDL::Video::display_format($temp);

  # load brown ant sprite
  $temp   = SDL::Video::load_BMP("brownants.bmp");
  $brownAntSprite = SDL::Video::display_format($temp);

  # load food sprite
  $temp   = SDL::Video::load_BMP("food.bmp");
  $foodSprite = SDL::Video::display_format($temp);

  # setup colorkey
  $colorkey = SDL::Video::map_RGB($screen->format, COLORKEY_RED, COLORKEY_GREEN, COLORKEY_BLUE);

  # setup black ant sprite colorkey and turn on RLE
  SDL::Video::set_color_key($blackAntSprite, SDL_SRCCOLORKEY | SDL_RLEACCEL, $colorkey);

  # setup red ant sprite colorkey and turn on RLE
  SDL::Video::set_color_key($redAntSprite, SDL_SRCCOLORKEY | SDL_RLEACCEL, $colorkey);

  # setup brown ant sprite colorkey and turn on RLE
  SDL::Video::set_color_key($brownAntSprite, SDL_SRCCOLORKEY | SDL_RLEACCEL, $colorkey);

  # setup food sprite colorkey and turn on RLE
  SDL::Video::set_color_key($foodSprite, SDL_SRCCOLORKEY | SDL_RLEACCEL, $colorkey);

  # load background textures
  foreach my $bg (@bgTextures) {
    $temp  = SDL::Video::load_BMP($bgBitmaps[$bg]);
    $bgndSurface[$bg] = SDL::Video::display_format($temp);
  }

  # set initial black ant position
  $rcBlackAntSprite->x(SCREEN_WIDTH / 2);
  $rcBlackAntSprite->y(SCREEN_HEIGHT / 2);

  # set initial red ant positions
  $rcRedAntSprite[0]->x(SPRITE_SIZE);
  $rcRedAntSprite[0]->y(SPRITE_SIZE);
  $rcRedAntSprite[1]->x(SCREEN_WIDTH - SPRITE_SIZE);
  $rcRedAntSprite[1]->y(SPRITE_SIZE);
  $rcRedAntSprite[2]->x(SPRITE_SIZE);
  $rcRedAntSprite[2]->y(SCREEN_HEIGHT - SPRITE_SIZE);
  $rcRedAntSprite[3]->x(SCREEN_WIDTH - SPRITE_SIZE);
  $rcRedAntSprite[3]->y(SCREEN_HEIGHT - SPRITE_SIZE);

  # set black ant animation frame
  $blackAnt->x(128);
  $blackAnt->y(0);
  $blackAnt->w(SPRITE_SIZE);
  $blackAnt->h(SPRITE_SIZE);

  # Set red ant animation frames
  for (my $redant = 0; $redant < MAX_RED_ANTS; $redant++) {
    $redAnt[$redant]->x(128);
    $redAnt[$redant]->y(0);
    $redAnt[$redant]->w(SPRITE_SIZE);
    $redAnt[$redant]->h(SPRITE_SIZE);
  }

  # set brown ant animation frame
  $brownAnt->x(128);
  $brownAnt->y(0);
  $brownAnt->w(SPRITE_SIZE);
  $brownAnt->h(SPRITE_SIZE);

  # set food animation frame
  $food->x(0);
  $food->y(0);
  $food->w(FOOD_SPRITE_SIZE);
  $food->h(FOOD_SPRITE_SIZE);

  # display splash screen
  my $splash = SDL::Image::load('antwars.bmp');
  SDL::Video::blit_surface($splash, SDL::Rect->new(0, 0, $splash->w, $splash->h), $screen, SDL::Rect->new(0, 0, $screen->w, $screen->h));
  SDL::Video::update_rect($screen, 0, 0, 0, 0);

  sleep(5);

  # erase splash
  my $blackColor = SDL::Video::map_RGBA($screen->format(), 0, 0, 0, 0);
  SDL::Video::fill_rect($screen, SDL::Rect->new(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT), $blackColor);
  SDL::Video::update_rect($screen, 0, 0, 0, 0);

  my @bgnd = ();
  # initially draw the grass/sand/dirt/rock
  for (my $x = 0; $x < SCREEN_WIDTH / SPRITE_SIZE; $x++) {
    for (my $y = 0; $y < SCREEN_HEIGHT / SPRITE_SIZE; $y++) {
      my $bg = int(rand(4));
      $bgnd[$x][$y] = $bg;
      $rcBgndRect[$bg]->x($x * SPRITE_SIZE);
      $rcBgndRect[$bg]->y($y * SPRITE_SIZE);
      SDL::Video::blit_surface($bgndSurface[$bg], undef, $screen, $rcBgndRect[$bg]);
    }
  }

  # set initial directions for red ants
  my @redAntDirection;
  for (my $redant = 0; $redant < MAX_RED_ANTS; $redant++) {
    $redAntDirection[$redant] = int(rand(4));
  }

  # set initial directions for brown ant
  my $brownAntDirection = int(rand(4));

  # display ready message
  my $ready_x = 10;
  my $ready_y = 490;
  my $readyTextObj = SDLx::Text->new();
  $readyTextObj->color([255,255,255]);
  $readyTextObj->write_xy($app, $ready_x, $ready_y, "Get ready...");
  my $ready_w = $readyTextObj->w();
  my $ready_h = $readyTextObj->h();
  $app->update();

  sleep(5);

  # erase ready message
  SDL::Video::fill_rect($screen, SDL::Rect->new($ready_x, $ready_y, $ready_x + $ready_w, $ready_y + $ready_h), $blackColor);
  SDL::Video::update_rect($screen, 0, 0, 0, 0);

  # draw score message
  my $score_x = 10;
  my $score_y = 490;
  my $scoreTextObj = SDLx::Text->new();
  $scoreTextObj->color([255, 255, 255]);
  $scoreTextObj->write_xy($app, $score_x, $score_y, "Score: ");
  my $score_w = $scoreTextObj->w();
  my $score_h = $scoreTextObj->h();
  my $n_score_x = $score_x + $score_w;
  my $n_score_y = $score_y;
  $scoreTextObj->write_xy($app, $n_score_x, $n_score_y, $score);
  my $n_score_w = $scoreTextObj->w();
  my $n_score_h = $scoreTextObj->h();
print "n_score_h=$n_score_h\n";

  # draw lives message
  my $lives_x = 10;
  my $lives_y = 490 + ($score_h * 2);
  my $n_lives_w;
  my $n_lives_h;
  my $livesTextObj = SDLx::Text->new();
  $livesTextObj->color([255, 255, 255]);
  $livesTextObj->write_xy($app, $lives_x, $lives_y, "Lives: ");
  my $lives_w = $livesTextObj->w();
  my $lives_h = $livesTextObj->h();
  my $n_lives_x = $lives_x + $lives_w;
  my $n_lives_y = $lives_y;
  $livesTextObj->write_xy($app, $n_lives_x, $n_lives_y, $lives);
  my $n_lives_w = $livesTextObj->w();
  my $n_lives_h = $livesTextObj->h();

  SDL::Video::update_rect($screen, 0, 0, 0, 0);

  # count of ticks through loop
  my $loopc = 0;

  # message pump
  while (!$gameover) {
    $loopc++;
    my $event = SDL::Event->new();
		
    # look for an event
    if (SDL::Events::poll_event($event)) {
      &HandleEvent($event);
    }

    # control for red ants
    if (($loopc % $cur_red_ant_speed) == 0) {
      $score += 1;

      # increase red ant speed as score increases
      if (($score % RED_ANT_SPEED_CHANGE_INTERVAL) == 0) {
        $cur_red_ant_speed -= RED_AND_SPEED_CHANGE_AMOUNT;
        if ($cur_red_ant_speed < MAX_RED_ANT_SPEED) {
          $cur_red_ant_speed = MAX_RED_ANT_SPEED;
        }
      }

      # Insert brown ant every given number of points.
      if (($score % BROWN_ANT_INTERVAL) == 0) {
        $brownAntActive = 1;

        # set initial brown ant position
        if ($rcBlackAntSprite->x() <= (SCREEN_WIDTH / 2)) {
          $rcBrownAntSprite->x(SCREEN_WIDTH - SPRITE_SIZE);
        } else {
          $rcBrownAntSprite->x(SPRITE_SIZE);
        }
        if ($rcBlackAntSprite->y() <= (SCREEN_HEIGHT / 2)) {
          $rcBrownAntSprite->y(SCREEN_HEIGHT - SPRITE_SIZE);
        } else {
          $rcBrownAntSprite->y(SPRITE_SIZE);
        }

        # set initial brown ant direction
        $brownAntDirection = int(rand(4));
      }

      # add food
      if (($foodActive == 0) && (($score % FOOD_INTERVAL) == 0)) {
        $foodActive = 1;
        # set food position
        if ($rcBlackAntSprite->x() <= (SCREEN_WIDTH / 2)) {
          $rcFoodSprite->x(SCREEN_WIDTH - (FOOD_SPRITE_SIZE * 2));
        } else {
          $rcFoodSprite->x(SPRITE_SIZE);
        }
        if ($rcBlackAntSprite->y() <= (SCREEN_HEIGHT / 2)) {
          $rcFoodSprite->y(SCREEN_HEIGHT - (FOOD_SPRITE_SIZE * 2));
        } else {
          $rcFoodSprite->y(SPRITE_SIZE);
        }
      }

      # add more red ants as score increases
      if (!($score % RED_ANT_ADD_INTERVAL) && $cur_red_ants < MAX_RED_ANTS) {
        $cur_red_ants++;
        # set initial new red ant position
        if ($rcBlackAntSprite->x() <= (SCREEN_WIDTH / 2)) {
          $rcRedAntSprite[$cur_red_ants]->x(SCREEN_WIDTH - SPRITE_SIZE);
        } else {
          $rcRedAntSprite[$cur_red_ants]->x(SPRITE_SIZE);
        }
        if ($rcBlackAntSprite->y() <= (SCREEN_HEIGHT / 2)) {
          $rcRedAntSprite[$cur_red_ants]->y(SCREEN_HEIGHT - SPRITE_SIZE);
        } else {
          $rcRedAntSprite[$cur_red_ants]->y(SPRITE_SIZE);
        }
      }

      # semi-random movement for red ants
      # Note that red ants try to move towards the black ant when they make
      # 'smart' moves
      for (my $redant = 0; $redant < $cur_red_ants; $redant++) {
        my $rand1 = int(rand(20)) - 1;
        if ($rand1 == -1) {
           # random move
           $redAntDirection[$redant] = int(rand(4));
        # smart moves
        # 0-3 one direction smart
        # 4 & 5 two directions smart
        } elsif ($rand1 == LEFT || $rand1 == 4) {
           if ($rcRedAntSprite[$redant]->x() > $rcBlackAntSprite->x()) {
             $redAntDirection[$redant] = LEFT;
           }
        } elsif ($rand1 == RIGHT || $rand1 == 5) {
           if ($rcRedAntSprite[$redant]->x() < $rcBlackAntSprite->x()) {
             $redAntDirection[$redant] = RIGHT;
           }
        } elsif ($rand1 == UP || $rand1 == 4) {
           if ($rcRedAntSprite[$redant]->y() > $rcBlackAntSprite->y()) {
             $redAntDirection[$redant] = UP;
           }
        } elsif ($rand1 == DOWN || $rand1 == 5) {
           if ($rcRedAntSprite[$redant]->y() < $rcBlackAntSprite->y()) {
             $redAntDirection[$redant] = DOWN;
           }
        # anything from 6+ keep moving same direction
        }

        # move the red ant
        if ($redAntDirection[$redant] == LEFT) {
          if ( $redAnt[$redant]->x() == 192 ) {
            $redAnt[$redant]->x(224);
          } else {
            $redAnt[$redant]->x(192);
          }
          $rcRedAntSprite[$redant]->x($rcRedAntSprite[$redant]->x() - MOVE_INCREMENT);
        } elsif ($redAntDirection[$redant] == RIGHT) {
          if ( $redAnt[$redant]->x() == 64 ) {
            $redAnt[$redant]->x(96);
          } else {
            $redAnt[$redant]->x(64);
          }
          $rcRedAntSprite[$redant]->x($rcRedAntSprite[$redant]->x() + MOVE_INCREMENT);
        } elsif ($redAntDirection[$redant] == UP) {
          if ( $redAnt[$redant]->x() == 0 ) {
            $redAnt[$redant]->x(32);
          } else {
            $redAnt[$redant]->x(0);
          }
          $rcRedAntSprite[$redant]->y($rcRedAntSprite[$redant]->y() - MOVE_INCREMENT);
        } elsif ($redAntDirection[$redant] == DOWN) {
          if ( $redAnt[$redant]->x() == 128 ) {
            $redAnt[$redant]->x(160);
          } else {
            $redAnt[$redant]->x(128);
          }
          $rcRedAntSprite[$redant]->y($rcRedAntSprite[$redant]->y() + MOVE_INCREMENT);
        }
      }

      # collision check between black and red ants
      for (my $redant = 0; $redant < $cur_red_ants; $redant++) {
        if (&collision_check($rcBlackAntSprite->x(), $rcBlackAntSprite->y(), $rcRedAntSprite[$redant]->x(), $rcRedAntSprite[$redant]->y(), (SPRITE_SIZE / 2))) {
          # decrement lives if a red ant and the black ant touch
          # game is over if lives < 1
          $lives--;

          # erase lives
          SDL::Video::fill_rect($screen, SDL::Rect->new($n_lives_x, $n_lives_y, $n_lives_x + $n_lives_w, $n_lives_y + $n_lives_h), $blackColor);
          # draw number of lives
          $livesTextObj->write_xy($app, $n_lives_x, $n_lives_y, $lives);
          $n_lives_w = $livesTextObj->w();
          $n_lives_h = $livesTextObj->h();

          #$snd->play('die', 1);
          #$sndDie->play();
          #$mixer->play_channel(0, $dieSound, 0);
          $snd->play('die.wav');
          sleep(1);
          $snd->stop();
          if ($lives < 1) {
            # game over
            $gameover = 1;
            print "Score = " . $score . "!\n";
          } else {
            # player still has lives

            # re-set initial black ant position
            $rcBlackAntSprite->x(SCREEN_WIDTH / 2);
            $rcBlackAntSprite->y(SCREEN_HEIGHT / 2);

            # re-set initial red ant positions
            $rcRedAntSprite[0]->x(SPRITE_SIZE);
            $rcRedAntSprite[0]->y(SPRITE_SIZE);
            $rcRedAntSprite[1]->x(SCREEN_WIDTH - SPRITE_SIZE);
            $rcRedAntSprite[1]->y(SPRITE_SIZE);
            $rcRedAntSprite[2]->x(SPRITE_SIZE);
            $rcRedAntSprite[2]->y(SCREEN_HEIGHT - SPRITE_SIZE);
            $rcRedAntSprite[3]->x(SCREEN_WIDTH - SPRITE_SIZE);
            $rcRedAntSprite[3]->y(SCREEN_HEIGHT - SPRITE_SIZE);

            # take away extra life chance if it was there
            $brownAntActive = 0;

            # take away food if it was there
            $foodActive = 0;

            # re-draw entire screen
            &redraw_whole_background($screen, \@bgnd, \@rcBgndRect, \@bgndSurface);
          }
        }
      }

      # semi-random movement for brown ant
      # Note that the brown ant tries to get away from the black ant when
      # it makes 'smart' moves
      if ($brownAntActive) {
        my $rand1 = int(rand(20)) - 1;
        if ($rand1 == -1) {
           # random move
           $brownAntDirection = int(rand(4));
        # smart moves
        # 0-3 one direction smart
        # 4 & 5 two directions smart
        } elsif ($rand1 == LEFT || $rand1 == 4) {
           if ($rcBrownAntSprite->x() < $rcBlackAntSprite->x()) {
             $brownAntDirection = LEFT;
           }
        } elsif ($rand1 == RIGHT || $rand1 == 5) {
           if ($rcBrownAntSprite->x() > $rcBlackAntSprite->x()) {
             $brownAntDirection = RIGHT;
           }
        } elsif ($rand1 == UP || $rand1 == 4) {
           if ($rcBrownAntSprite->y() < $rcBlackAntSprite->y()) {
             $brownAntDirection = UP;
           }
        } elsif ($rand1 == DOWN || $rand1 == 5) {
           if ($rcBrownAntSprite->y() > $rcBlackAntSprite->y()) {
             $brownAntDirection = DOWN;
           }
        # anything from 6+ keep moving same direction
        }

        # move the brown ant
        if ($brownAntDirection == LEFT) {
          if ($brownAnt->x() == 192) {
            $brownAnt->x(224);
          } else {
            $brownAnt->x(192);
          }
          $rcBrownAntSprite->x($rcBrownAntSprite->x() - MOVE_INCREMENT);
        } elsif ($brownAntDirection == RIGHT) {
          if ($brownAnt->x() == 64) {
            $brownAnt->x(96);
          } else {
            $brownAnt->x(64);
          }
          $rcBrownAntSprite->x($rcBrownAntSprite->x() + MOVE_INCREMENT);
        } elsif ($brownAntDirection == UP) {
          if ($brownAnt->x() == 0) {
            $brownAnt->x(32);
          } else {
            $brownAnt->x(0);
          }
          $rcBrownAntSprite->y($rcBrownAntSprite->y() - MOVE_INCREMENT);
        } elsif ($brownAntDirection == DOWN) {
          if ($brownAnt->x() == 128) {
            $brownAnt->x(160);
          } else {
            $brownAnt->x(128);
          }
          $rcBrownAntSprite->y($rcBrownAntSprite->y() + MOVE_INCREMENT);
        }

        # collision check between black and brown ant
        if (&collision_check($rcBlackAntSprite->x(), $rcBlackAntSprite->y(), $rcBrownAntSprite->x(), $rcBrownAntSprite->y(), (SPRITE_SIZE / 2))) {
          # give the player a free life
          $lives++;

          # erase lives
          SDL::Video::fill_rect($screen, SDL::Rect->new($n_lives_x, $n_lives_y, $n_lives_x + $n_lives_w, $n_lives_y + $n_lives_h), $blackColor);
          # draw number of lives
          $livesTextObj->write_xy($app, $n_lives_x, $n_lives_y, $lives);
          $n_lives_w = $livesTextObj->w();
          $n_lives_h = $livesTextObj->h();

          $brownAntActive = 0;
          #$snd->play('extralife', 1);
          #$sndExtralife->play();
          #$mixer->play_channel(1, $extralifeSound, 0);
          $snd->play('extralife.wav');
          sleep(1.5);
          $snd->stop();
        }
      }

      # collision check between black and food
      if ($foodActive && &collision_check($rcBlackAntSprite->x(), $rcBlackAntSprite->y(), $rcFoodSprite->x(), $rcFoodSprite->y(), (FOOD_SPRITE_SIZE / 2))) {
        $foodActive = 0;
        $score += FOOD_SCORE;
        #$snd->play('food.wav');
        &redraw_background($screen, $rcFoodSprite->x(), $rcFoodSprite->y(), FOOD_SPRITE_SIZE, \@bgnd, \@rcBgndRect, \@bgndSurface);
      }
    }

    # check for black ant collision with edges of screen
    &edge_collide($rcBlackAntSprite, SPRITE_SIZE);

    # check for red ants collision with edges of screen
    for (my $redant = 0; $redant < $cur_red_ants; $redant++) {
      &edge_collide($rcRedAntSprite[$redant], SPRITE_SIZE);
    }

    # check for brown ant collision with edges of screen
    &edge_collide($rcBrownAntSprite, SPRITE_SIZE);

    # redraw background behind black ant
    &redraw_background($screen, $rcBlackAntSprite->x(), $rcBlackAntSprite->y(), SPRITE_SIZE, \@bgnd, \@rcBgndRect, \@bgndSurface);

    # redraw background behind red ants
    for (my $redant = 0; $redant < $cur_red_ants; $redant++) {
      &redraw_background($screen, $rcRedAntSprite[$redant]->x(), $rcRedAntSprite[$redant]->y(), SPRITE_SIZE, \@bgnd, \@rcBgndRect, \@bgndSurface);
    }

    # redraw background behind brown ant
    &redraw_background($screen, $rcBrownAntSprite->x(), $rcBrownAntSprite->y(), SPRITE_SIZE, \@bgnd, \@rcBgndRect, \@bgndSurface);

    # draw the black ant
    SDL::Video::blit_surface($blackAntSprite, $blackAnt, $screen, $rcBlackAntSprite);

    # draw the red ants
    for (my $redant = 0; $redant < $cur_red_ants; $redant++) {
      SDL::Video::blit_surface($redAntSprite, $redAnt[$redant], $screen, $rcRedAntSprite[$redant]);
    }

    # draw the brown ant
    if ($brownAntActive) {
      SDL::Video::blit_surface($brownAntSprite, $blackAnt, $screen, $rcBrownAntSprite);
    }

    # draw the food
    if ($foodActive) {
      SDL::Video::blit_surface($foodSprite, $food, $screen, $rcFoodSprite);
    }

    # erase score
    SDL::Video::fill_rect($screen, SDL::Rect->new($n_score_x, $n_score_y, $n_score_x + $n_score_w, $n_score_y + $n_score_h), $blackColor);

    # draw score
    $scoreTextObj->write_xy($app, $n_score_x, $n_score_y, $score);
    $n_score_w = $scoreTextObj->w();
    $n_score_h = $scoreTextObj->h();

    # update the screen
    SDL::Video::update_rect($screen, 0, 0, 0, 0);
  }
}

1;

