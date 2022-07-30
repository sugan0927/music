import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/homePage.dart';
import 'package:musify/ui/player.dart';
import 'package:musify/ui/playlistsPage.dart';
import 'package:musify/ui/searchPage.dart';
import 'package:musify/ui/settingsPage.dart';

class Musify extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

ValueNotifier<int> activeTab = ValueNotifier<int>(0);

class AppState extends State<Musify> {
  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  @override
  void dispose() {
    audioPlayer?.dispose();
    super.dispose();
  }

  void initAudioPlayer() {
    audioPlayerStateSubscription =
        audioPlayer?.playerStateStream.listen((playerState) async {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        buttonNotifier.value = MPlayerState.loading;
      } else if (!isPlaying) {
        buttonNotifier.value = MPlayerState.paused;
      } else if (processingState != ProcessingState.completed) {
        buttonNotifier.value = MPlayerState.playing;
      } else {
        await audioPlayer?.seek(Duration.zero);
        await audioPlayer?.pause();
        if (hasNext) {
          if (activePlaylist.isEmpty && playNextSongAutomatically.value) {
            await playSong(await getRandomSong());
          } else {
            await playSong(activePlaylist[id + 1]);
            id = id + 1;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(),
      SearchPage(),
      PlaylistsPage(),
      SettingsPage(),
    ];
    return Scaffold(
      bottomNavigationBar: getFooter(),
      body: ValueListenableBuilder<int>(
        valueListenable: activeTab,
        builder: (_, value, __) {
          return Row(children: <Widget>[
            NavigationRail(
              backgroundColor: bgLight,
              selectedIconTheme: IconThemeData(
                color: accent != const Color(0xFFFFFFFF)
                    ? Colors.white
                    : Colors.black,
              ),
              selectedLabelTextStyle: TextStyle(color: accent),
              unselectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white),
              useIndicator: true,
              indicatorColor: accent,
              selectedIndex: value,
              onDestinationSelected: (int index) {
                activeTab.value = index;
              },
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(MdiIcons.homeOutline),
                  selectedIcon: const Icon(MdiIcons.home),
                  label: Text(AppLocalizations.of(context)!.home),
                ),
                NavigationRailDestination(
                  icon: const Icon(MdiIcons.magnifyMinusOutline),
                  selectedIcon: const Icon(MdiIcons.magnifyMinus),
                  label: Text(AppLocalizations.of(context)!.search),
                ),
                NavigationRailDestination(
                  icon: const Icon(MdiIcons.bookOutline),
                  selectedIcon: const Icon(MdiIcons.book),
                  label: Text(AppLocalizations.of(context)!.playlists),
                ),
                NavigationRailDestination(
                  icon: const Icon(MdiIcons.cogOutline),
                  selectedIcon: const Icon(MdiIcons.cog),
                  label: Text(AppLocalizations.of(context)!.settings),
                ),
              ],
            ),

            const VerticalDivider(thickness: 1, width: 1),
            // This is the main content.
            Expanded(child: pages[value]),
          ]);
        },
      ),
    );
  }

  Widget getFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 75,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            color: bgLight,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 2),
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    top: 7,
                    bottom: 7,
                    right: 15,
                    left: 15,
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: highResImage,
                    builder: (_, value, __) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: value,
                          fit: BoxFit.fill,
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(30, 255, 255, 255),
                                  Color.fromARGB(30, 233, 233, 233),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  MdiIcons.musicNoteOutline,
                                  size: 30,
                                  color: accent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ValueListenableBuilder<String>(
                        valueListenable: title,
                        builder: (_, value, __) {
                          return Text(
                            value.length > 15
                                ? '${title.value.substring(0, 15)}...'
                                : title.value,
                            style: TextStyle(
                              color: accent,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: artist,
                        builder: (_, value, __) {
                          return Text(
                            value.length > 15
                                ? '${artist.value.substring(0, 15)}...'
                                : artist.value,
                            style: TextStyle(
                              color: accent,
                              fontSize: 15,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: songLikeStatus,
                  builder: (_, value, __) {
                    if (value == true) {
                      return IconButton(
                        color: accent,
                        icon: const Icon(MdiIcons.star),
                        onPressed: () => {
                          removeUserLikedSong(ytid),
                          songLikeStatus.value = false
                        },
                      );
                    } else {
                      return IconButton(
                        color: Colors.white,
                        icon: const Icon(MdiIcons.starOutline),
                        onPressed: () => {
                          addUserLikedSong(ytid),
                          songLikeStatus.value = true
                        },
                      );
                    }
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: shuffleNotifier,
                  builder: (_, value, __) {
                    return IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        MdiIcons.shuffle,
                        color: value ? accent : Colors.white,
                      ),
                      onPressed: changeShuffleStatus,
                    );
                  },
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.skip_previous,
                    color: hasPrevious ? Colors.white : Colors.grey,
                  ),
                  onPressed: playPrevious,
                ),
                ValueListenableBuilder<MPlayerState>(
                  valueListenable: buttonNotifier,
                  builder: (_, value, __) {
                    return IconButton(
                      icon: buttonNotifier.value == MPlayerState.playing
                          ? const Icon(MdiIcons.pause)
                          : const Icon(MdiIcons.playOutline),
                      color: accent,
                      splashColor: Colors.transparent,
                      onPressed: () {
                        setState(() {
                          if (buttonNotifier.value == MPlayerState.playing) {
                            audioPlayer?.pause();
                          } else if (buttonNotifier.value ==
                              MPlayerState.paused) {
                            audioPlayer?.play();
                          }
                        });
                      },
                      iconSize: 45,
                    );
                  },
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.skip_next,
                    color: hasNext ? Colors.white : Colors.grey,
                  ),
                  onPressed: playNext,
                ),
                ValueListenableBuilder<bool>(
                    valueListenable: repeatNotifier,
                    builder: (_, value, __) {
                      return IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          MdiIcons.repeat,
                          color: value ? accent : Colors.white,
                        ),
                        onPressed: changeLoopStatus,
                      );
                    }),
                ValueListenableBuilder<bool>(
                  valueListenable: playNextSongAutomatically,
                  builder: (_, value, __) {
                    return IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        MdiIcons.chevronRight,
                        color: value ? accent : Colors.white,
                      ),
                      onPressed: changeAutoPlayNextStatus,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
