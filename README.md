# Playlist


## Main Task

The app should show a list of songs. Every element of the list is a view that
represents Song. Let’s call the view SongView.
SongView has a button that represents Song state:
- need to download: triggers downloading of the related audio file
- downloading: shows downloading progress, user actions should be ignored
- play: current song is not playing, triggers playback
- pause: current song is playing, stops playback

#### Bonus task (optional):

The app data should be persistent. If the user has downloaded a few songs and
killed the app right after that, the Songs data such as info and audio files will
survive. The next time the user launches the app, the cached data should be shown
first and then the data should be updated from the server.

#### Pay attention

- Write scalable programming code;
-You are not allowed to use any third party libraries;
- The user should be able to download Songs simultaneously;
- SongView’s state should not be lost in the case when the user scrolls the list
up and down.

#### Resources:

- [This is](https://gist.githubusercontent.com/Lenhador/a0cf9ef19cd816332435316a2369bc00/raw/a1338834fc60f7513402a569af09ffa302a26b63/Songs.json) the link to fetch Songs.
- The design can be found in the Resource folder

## Architecture

This project uses the MVVM Design Pattern with separate classes for Services and Managers.

## Screenshot

![Screenshot](https://gitlab.com/kayla.serioso/playlist/-/raw/dev/screenshot.png)


