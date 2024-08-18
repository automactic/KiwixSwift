## 3.5.1

## 3.5.0
  - NEW:
    - Implement „Find in page" (@BPerlakiH #849 #872)
    - Support range requests for video content (@BPerlakiH @rgaudin #894)
    - Integrate Codecov to the CI (@BPerlakiH #907)
    - Download error feedback (@BPerlakiH #912)
  - UPDATE:
    - Remove bookmark image and snippets (@BPerlakiH #830)
    - Change search snippets settings to be a toggle (@BPerlakiH #873)
    - Resolve Swift Package Dependencies Automatically on checkout (@BPerlakiH #864)
    - Remove BackPorts dependency (@BPerlakiH #867)
    - Search in descriptions of ZIM files as well (@BPerlakiH #904 #910)
    - Auto update of library, remove iOS background processing (@BPerlakiH #926)
  - FIX:
    - After resuming iOS app video displayed black (@BPerlakiH #801 #846)
    - ZIM metadata „illustration“ is not read properly (@BPerlakiH #811)
    - Export of a PDF fails iOS (@BPerlakiH #820 #840)
    - Content default positioning is not always correct (@BPerlakiH #841)
    - Nightly CD build (@BPerlakiH #845)
    - Double-clicking on a ZIM in mac finder opens a new Kiwix window (@BPerlakiH #860)
    - Crash Library Parsing (@BPerlakiH #868)
    - Crash by removing html parsed snippets (@BPerlakiH #865)
    - Search crash and improve efficiency (@BPerlakiH #862)
    - Pop over crash by removing modal style (@BPerlakiH #876)
    - Multiple language ZIM files to show up (@BPerlakiH #870)
    - UTF-8 checking before parsing library data (@BPerlakiH #884)
    - DB Crash with Single background contex (@BPerlakiH #879)
    - Fix DB leading to mac UI crash on listing downloads (@BPerlakiH #882)
    - iOS Accessibility of icons when large text is set (@BPerlakiH #886)
    - mac video fullscreen sizing when paused (@BPerlakiH #893)
    - mac video sound kept playing after tab is closed (@BPerlakiH #891)
    - WebKitHandler concurrency fix (@BPerlakiH #896)
    - mac window closing should stop video (@BPerlakiH #899)
    - Library language count for multi-language ZIM files (@HiroyasuNishiyama @BPerlakiH #906)
    - mac Video playing right click problems (@BPerlakiH #918)
    - video starting with a black screen on iOS 17 iPhone (@BPerlakiH #924)
    - iPhone backgrounding makes the inline video black (@BPerlakiH #937)
    - On fresh install opening a ZIM file directly after download crashes the app on iPad (@BPerlakiH #921)
    - iOS double sheet for Library (@BPerlakiH 925)
    - Translation issues with help buttons (@HiroyasuNishiyama @BPerlakiH #929 #930)
    - iOS Add space in article count label (@BPerlakiH #932)

## 3.4.0
  - FIX: 
    - Empty screen after re-opening ZIM home page (@BPerlakiH #834)
    - tab reconfiguration, improve the look of icons (@BPerlakiH #832)
    - bookmark titles for non html content (@BPerlakiH #826)
    - javascript console errors (@BPerlakiH #825)
    - html offset and animation issues (@BPerlakiH #823)
    - exporting PDF content (@BPerlakiH #820)
    - ZIM fav icons of opened files (not added via catalog download) (@BPerlakiH #811)
    - macOS tab update after unlinkning a ZIM file (@BPerlakiH #810)
    - video display is black after resuming app on iOS (@BPerlakiH #801)
    - stop video when a tab is closed (@BPerlakiH #806)
    - mailto links for iOS (@BPerlakiH #802 #792)
    - support ZIM entries ending in "/" (@BPerlakiH #797)
    - open links in new tab (@BPerlakiH #800 #783)
    - macOS webView full-screen mode (@BPerlakiH #791)
    - video full screen mode for macOS (@BPerlakiH #763)
    - CI/CD target FTP folder for release (@rgaudin #757)
  - NEW: 
    - stream data in chunks for compressed data via libzim (@BPerlakiH #790)
    - stream uncompressed data in chunks (@BPerlakiH #778 #774)
    - full screen reading mode for iOS (@TheRealAnt @BPerlakiH #771 #764)
  - UPDATE: 
    - Translations (#833, #821, #813, #777, #770, #761)
    - to libkiwix 13.1.0-4 (@BPerlakiH #836)
    - readme on how to debug webviews (@BPerlakiH #822)
    - video readme (@BPerlakiH #812)
    - minimum version to mac 13 and iOS 16 (@BPerlakiH #796 #794)
    - Release notes (@BPerlakiH #758)

## 3.3.0

- NEW: Introduce CI & CD (@rgaudin #538 #544 #546 #560 #568 @BPerlakiH #606 #610 #614 #625 #646 #648 #671)
- NEW: Introduce localisation with help of Translatewiki (@tvision251 #537 #574 @BPerlakiH #585 #605 #628 #670 #672 #684)
- NEW: Introduce ability to build custom apps (@BPerlakiH #550 #554 #555 #565 #573 #576 #584 #595)
- NEW: Build nightlies (@rgaudin #560)
- NEW: Migrate bookmarks - in custom apps (@BPerlakiH #688)
  - Multiple fixes around 'wicked' download (@BPerlakiH #563 #686)
  - Default language content filtering (@BPerlakiH #652)
  - Stop display empty categories (@BPerlakiH #657)
  - One search crashing scenario (@BPerlakiH #637)
- UPDATE: Introduce libkiwix 13 support (@rgaudin #534)
- UPDATE: Improved README file (@kelson42 #533 #683 @BPerlakiH #658)
- UPDATE: Use latest feed from library.kiwix.org (@BPerlakiH #653)
- DEL: Old Wikimed related code - is now a proper custom app (@BPerlakiH #636)
  - iOS tab selection after the selected tab is deleted (@BPerlakiH #692)
- UPDATE: Add background processing and audio capabilities for video playback (@BPerlakiH #738)
- NEW: Print an article on macOS (@BPerlakiH #736)
  - Exception handling in corrupted ZIM files (@BPerlakiH #622)
- NEW: Export and share an article (@BPerlakiH #729)
- UPDATE: LibKiwix 13.1.0-1 (@BPerlakiH #731)
  - Dismiss iOS modals (@BPerlakiH #728)
  - Invalid tab state after unlinking ZIM file on macOS (@BPerlakiH #723)
- UPDATE: Readme on XCode white space settings (@BPerlakiH #722)
- UPDATE: File headers and new file template to GPL-3 (@kelson42 @BPerlakiH #719)
- NEW: Add support menu item on macOS (@DobleV55 @BPerlakiH #705)
  - Custom apps should request only necessary permissions (@BPerlakiH #712)
  - UTF-8 encoding for HTTP headers for text/plain type (@BPerlakiH #707)
- NEW: Remove long press from bookmarks menu item (@BPerlakiH #695)
- NEW: Re-arrange menu items, remove long press functionality (@BPerlakiH #694)
  - Tab selection after deleting a tab (@BPerlakiH #693)
- DELETE: Support menu item on macOS (@BPerlakiH #752)

## 3.2

- Browse with multiple tabs on iOS and iPadOS
- On iPadOS, table of contents is now displayed as popover instead of menu
- Dropped support for iOS 14 & iPadOS 14

## 3.1.1

- Reverted a change around HTTP partial content handling that resulted in worse video playback experience for iOS / iPadOS

## 3.1

- Notification for when a download task complete
- Improved handling and error surfacing for failed download tasks
- Fixed an issue where tasks are not labeled as failed when app is force quit (iOS & iPadOS)
- Implemented HTTP partial content response, which may help with video playback

## 3.0

- Kiwix for iOS & iPadOS is now also on macOS
- Library now has opened, categories, downloads, and new sections
- Zim file list in library and bookmark list has new design

## 1.16

- Tabbed library UI with opened, categories, download tasks and new zim files section
- Articles also have a new look in bookmark and search results
- Streamlined settings UI
- Add iOS 16 compatibility and remove iOS 13 support

## 1.15.5

- libkiwix 10 & libzim 7 compatibility

## 1.15.4

- Attempt to address some crash reports

## 1.15.3

- Revert libkiwix and libzim to the last known stable release (9.4.1 and 6.3.2 respectively)
- Added version notation of libkiwix and libzim to the about page

## 1.15.2

- Fixed an issue where press random button could lead to app crash

## 1.15.1

- Fixed an issue where open in places zim files are identified as corrupted.

## 1.15

- Half sheet table of contents (iOS 15 & horizontally compact interfaces)
- Using quicklook to preview zim files in the files app
- Bookmark UI is made consistent with other article list UI (e.g. search results)

## 1.14.5

- Fixed crashes that could happen during search result snippet parsing

## 1.14.4

- Added iOS 15 compatibility and dropped iOS 12 support
- Performance improvements and optimization for library search and category list

## 1.14.3

- Library zim file detail now show file descriptions
- Technical implementation improvements for library on iOS 13 & 14 (Mostly SwiftUI)
- Fixed an issue where recent search button doesn't do anything if the search text contains spaces
- Note: we will drop support for iOS 12 once iOS 15 is released, we support the last three major iOS versions

## 1.14.2

- Search result UI tweaks
- Stability Improvements & crash fixes

Technical:

- Search result UI is rewritten with SwiftUI on iOS 13 & 14

## 1.14.1

- Hides zim files that requires service worker to function
- The zim file detail view now show progress on iOS 14 when downloading

Technical:

- The zim file detail view is rewrote with SwiftUI on iOS 14

## 1.14

- iPad: a new design with all UI controls at the top bar
- Random Article Button: tap to load a random article in the current zim file
- Main Page Button: tap to go to main page of the current article
- Long press on random article or main page button to choose from all on device zim files (not available on iOS 12 & 13) 
- Link Preview: tap and hold on a link to see preview of the article (not available on iOS 12)
- UI updates in app settings  (not available on iOS 12)
- Remove support for iOS 11 (We are committed to support last three major OS)
  - library related crashings 
  - zim file icon transluency

Technical:

- use html parsing to extract table of content hierarchy

## 1.13.7

- Disabled gesture that reveals the sidebar (iPad)
- populate group ID (aka name) when refresh the library
- tweak to the favicon, which IMO looks much nicer, especially on dark mode
- fixed an issue where unlink file could result in app crashes
- this will be the last version that supports iOS 11

## 1.13.6

- add TED category
- fixed an issue where it could lead to app launch crashes on iOS 12 (iPhone or iPad horizontally compact interface)

## 1.13.5

- added alert for when zim file of a bookmarked article is missing
- article loading speed improvements (especially on articles with a lot of images and on more recent devices)
- updated libkiwix version
- iOS 14 compatibility

## 1.13.4

- bookmark snippets are now using the first sentence (iOS 12 and above) or the first paragraph (iOS 11)
- small tweaks of sidebar and outline for a better UX
  - now use zim file title as bookmark title when the article doesn't have a title

## 1.13.3

- stability improvements to the under the hood file download sub-system
- stability improvements to search filters

## 1.13.2

- updated version of libkiwix and dependencies to resolve an issue where the app couldn't open some of the latest zim files
- updated version of realm to 5.2


## 1.13.1

- Resource unavailable alert: shown when a link was taped on, but the zim file is deleted.
- Fixed an issue where app is launched into the incorrect view for iPhones / iPod touch on iOS 11 and 12
- Prevent the snippet from showing up if all it contains is empty chars or new lines

## 1.13

- article outline improvements:
  - show article title in the navigation bar if available
  - prevent too much indentation when there is only one `h1` element in the article
  - list row separators now indent together with the text (so that it is easier to figure out the structure)
  - iPad: fixed an issue where search is not hidden if already visible when tapping on a outline row
  - for MediaWiki based zim files, sections are expanded when reading on horizontally narrow interface; if a section is already collapsed, tap on a outline item will expand that section
- iPad users can customize how side bar is displayed -- automatic, side by side or overlay
- setting for excluding zim files in backup is moved inside the library info interface
- bring back title based search results
- (iOS 13) some UI improvement / updates in search filter interface
  - the "All" button would now change to "None" if all zim files are included in search

Technical:

- Migrated database to Realm 5.0.2. Note once you install the beta app, you will be upgrade to the new database version, which is incompatible with the App Store production version.
- Migrated usage of SwiftyUserDefaults to Defaults. Tester should see if their old settings like external load policy, selected language filter, etc. are persisted after upgrading from App Store production version to 1.13 beta.
- The search filter interface is rewritten with SwiftUI. I have recently seen an uptick of crashes in this area. The old solution is rather hacky anyway, so I just rewrote this in SwiftUI so that issue would be fixed for most users. This is also the first SwiftUI interface in the app.

## 1.12

Speed improvements and more options for search snippets:

- Disabled: no search snippet, fastest
- First Paragraph: first paragraph of the article, max four lines
- First Sentence: from first paragraph, further extract the first sentence with iOS natural language processing engine
- Matches: highlight search term matches in the article (slowest, what we offer before)

Other New Stuff: 

- updated app icon
- new design of search result list

Bug fixes:

  - swipe back gesture was not working due to conflict with gesture to show sidebar
  - favicon would disappear for existing zim files after library manual refresh
  - sometimes the search filters fails to update when a zim file has been added or removed
  - Incorrect alphabetical ordering for library lanugage selector

## 1.11.1 (May 7, 2020)

  - font size not applied after article is loaded
  - snippet text color is too dark to read in dark mode
  - sometimes the font size setting prview becomes too tall
  - app launching issue for iOS 11 & 12 users
- new: integration with OPDS API for library catalog refreshing


## 1.11 (Jan 12, 2020)

A redesigned iPad interface
Fixing an issue where app creashed when attempting to save image to photo library


## 1.10 (Aug 10, 2019)

Now you can importing zim files by:
- open a zim file in the Files app
- use "open in" feature from any app
Better Files app integration:
- manage files stored in kiwix in Files app

## 1.9.7 (Jul 7, 2019)

  - memory usage issue when performing searches
- maintance updates:
  - swift 5.2, version bump of libkiwix, realm and SwiftyUserDefaults
  - removed third party library ProcedureKit, now use Foundation.OperationQueue to handle async tasks

## 1.9.6 (May 10, 2019)

- updated user feedback email address to `contact.kiwix.org`
- dropped support for external indexes
- improved iOS 12 support
- new version of libkiwix and Swift 4.2

## 1.9.4 (August 22, 2018)
- NEW: sort languages in library language filter both by count or alphabetically
- NEW: search for a zim file by name in library online catalog

## 1.9.1 (June 10, 2018)
- Use Realm in replace of CoreData as database
- Added Wiktionary, Wikiquote and Wikisource categories
  - unable to detect embedded index in some situations
  - unable to cancel erroneous download tasks

## 1.9.0 (May 09, 2018)

- New Library Design:
  - ZIM files are grouped by topic categories
  - ZIM file detail view
  - Downloading content and catalog are displayed in one place
  - On iPads, using a split view with ZIM file / categories on the left and detail on the right
- Bookmark
  - Now displayed as a side panel on iPad
  - Add / remove bookmark interface is now presented as a HUD and does not cover up all the screen space
- Reading
  - Now ask users for confirmation when opening external links. Can be turned on or off in settings
- Core
  - Massive multiple improvement of the ZIM file mgmt through introduction of Kiwix lib 2.0.
- An effort has been made to keep compatibility with iOS 10.

## 1.8.0 (March 03, 2017)

- Library has a new look
- Support zim files with build in index
- Performance optimization
- Now in Swift 3.1

## 1.7.1 (September 14, 2016)

- Improved iOS 10 compatibility

## 1.7.0 (August 05, 2016)

- Informative bookmarks
- New add / remove bookmarks interface
- Bookmarks Today Widget
- Bug fixes and performance improvements

## 1.6.0 (July 07, 2016)

### New
- show recent search terms
- search system now fetch result from both title search and index search and use a new ranking system to sort them
- table of content
- enhanced layout javascript on iPhone
- Use SafariViewController to handle external links
- access download.kiwix.org using https
- enhanced UI when hSizeClass is regular

### Fixed
- downloading / paused book purged when they are removed from online library
- removed code that mistakenly indicates app use Wallet
- open main page when first book finish downloaded
