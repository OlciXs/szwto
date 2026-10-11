import 'package:flutter_test/flutter_test.dart';
import 'package:zabytki_app/core/models/monument_category.dart';
import 'package:zabytki_app/core/models/rarity.dart';
import 'package:zabytki_app/features/achievements/models/achievement.dart';
import 'package:zabytki_app/features/achievements/models/progression.dart';
import 'package:zabytki_app/features/comments/models/comment.dart';
import 'package:zabytki_app/features/friends/models/friend.dart';
import 'package:zabytki_app/features/showcase/models/showcase.dart';
import 'package:zabytki_app/features/users/models/public_profile.dart';
import 'package:zabytki_app/features/monuments/models/monument.dart';

void main() {
  test('Monument.fromJson parsuje odpowiedź GET /monuments', () {
    final monument = Monument.fromJson({
      'id': 7,
      'name': 'Ratusz we Wrocławiu',
      'category': 'PUBLICZNY',
      'rawType': 'ratusz',
      'rarity': 'LEGENDARY',
      'latitude': 51.1096,
      'longitude': 17.0318,
      'thumbUrl': 'https://upload.wikimedia.org/x.jpg',
      'builtYear': 1250,
      'builtLabel': 'XIII wiek',
      'era': 'SREDNIOWIECZE',
      'xp': 150,
      'visitRadius': 75,
      'visited': true,
      'visitedAt': '2026-10-10T12:00:00.000Z',
    });

    expect(monument.id, 7);
    expect(monument.isMajor, isTrue); // brak pola (stary backend) -> widoczny
    expect(monument.category, MonumentCategory.publiczny);
    expect(monument.rarity, Rarity.legendary);
    expect(monument.visited, isTrue);
    expect(monument.visitedAt, isNotNull);
    expect(monument.subtitle, 'Ratusz · XIII wiek');
  });

  test('Monument.fromJson obsługuje brakujące pola i nieznane wartości', () {
    final monument = Monument.fromJson({
      'id': 2,
      'name': 'Kamienica',
      'category': 'COS_NOWEGO',
      'rarity': null,
      'latitude': 51,
      'longitude': 17,
      'visited': false,
      'visitedAt': null,
    });

    expect(monument.visited, isFalse);
    expect(monument.visitedAt, isNull);
    expect(monument.latitude, 51.0);
    expect(monument.category, MonumentCategory.architektura);
    expect(monument.rarity, Rarity.common);
    expect(monument.visitRadius, 50);
  });

  test('MonumentDetails: opis zablokowany przed wizytą', () {
    final details = MonumentDetails.fromJson({
      'id': 7,
      'name': 'Most Piaskowy',
      'category': 'MOST',
      'rarity': 'EPIC',
      'latitude': 51.11,
      'longitude': 17.04,
      'xp': 65,
      'visitRadius': 75,
      'visited': false,
      'teaser': 'Most · 1861 r.',
      'description': null,
      'descriptionLocked': true,
      'heritageLevel': 'REJESTR',
      'image': {
        'thumbUrl': 'https://upload.wikimedia.org/t.jpg',
        'fullUrl': 'https://upload.wikimedia.org/f.jpg',
        'pageUrl': 'https://commons.wikimedia.org/wiki/File:x.jpg',
      },
      'visitorsCount': 3,
    });

    expect(details.descriptionLocked, isTrue);
    expect(details.description, isNull);
    expect(details.paragraphs, isEmpty);
    expect(details.image?.pageUrl, contains('commons'));
    expect(details.monument.rarity, Rarity.epic);
  });

  test('MonumentDetails: zajawka zawsze, długi opis w akapitach po wizycie', () {
    final details = MonumentDetails.fromJson({
      'id': 9,
      'name': 'Ratusz',
      'category': 'PUBLICZNY',
      'rarity': 'LEGENDARY',
      'isMajor': true,
      'latitude': 51.11,
      'longitude': 17.03,
      'visited': true,
      'teaser': 'Ratusz · XIII wiek',
      'summary': 'Późnogotycki budynek na wrocławskim Rynku.',
      'description': 'Akapit pierwszy.\n\nAkapit drugi.\n\n\nAkapit trzeci.',
      'descriptionLocked': false,
    });

    expect(details.monument.isMajor, isTrue);
    expect(details.summary, startsWith('Późnogotycki'));
    expect(details.paragraphs, ['Akapit pierwszy.', 'Akapit drugi.', 'Akapit trzeci.']);
  });

  test('Rewards: awans i nowe osiągnięcia z odpowiedzi wizyty', () {
    final rewards = Rewards.fromJson({
      'progression': {'xpGained': 225, 'totalXp': 225, 'level': 3, 'levelUp': true, 'rank': 'Spacerowicz', 'rankUp': true, 'newPerks': ['2. miejsce w gablotce']},
      'newAchievements': [
        {'id': 'visits-1', 'name': 'Pierwszy krok', 'description': '…', 'icon': 'footprint', 'tier': null, 'xp': 25},
        {'id': 'sacral-1', 'name': 'Pielgrzym', 'description': '…', 'icon': 'church', 'tier': 'BRONZE', 'xp': 25},
      ],
    });
    expect(rewards.levelUp, isTrue);
    expect(rewards.xpGained, 225);
    expect(rewards.newPerks.single, '2. miejsce w gablotce');
    expect(rewards.newAchievements[1].tier, AchievementTier.bronze);
    expect(Rewards.fromJson({}).isEmpty, isTrue); // stary backend: brak nagród
  });

  test('Progression: poziom, postęp i nagrody', () {
    final p = Progression.fromJson({
      'totalXp': 225, 'level': 3, 'rank': {'index': 1, 'name': 'Spacerowicz'},
      'levelStartXp': 150, 'nextLevelXp': 300, 'progress': 0.5,
      'perks': {'discoveryRadius': 250, 'showcaseSlots': 2, 'radar': false},
      'nextUnlock': {'level': 4, 'label': 'Zasięg perełek 300 m'},
    });
    expect(p.xpIntoLevel, 75);
    expect(p.xpForLevel, 150);
    expect(p.perks.showcaseSlots, 2);
    expect(p.nextUnlockLevel, 4);
  });

  test('Showcase: miejsca puste, zajęte i zablokowane', () {
    final showcase = Showcase.fromJson({
      'unlockedSlots': 2,
      'maxSlots': 5,
      'slots': [
        {'slot': 0, 'locked': false, 'unlockLevel': 1, 'monument': {'id': 7, 'name': 'Ratusz', 'category': 'PUBLICZNY', 'rarity': 'LEGENDARY'}},
        {'slot': 1, 'locked': false, 'unlockLevel': 3, 'monument': null},
        {'slot': 4, 'locked': true, 'unlockLevel': 15, 'monument': null},
      ],
    });
    expect(showcase.slots.first.monument?.rarity, Rarity.legendary);
    expect(showcase.slots.last.locked, isTrue);
    expect(showcase.isEmpty, isFalse);
  });

  test('Komentarze i ranking – bez e-maila, z poziomem autora', () {
    final page = CommentsPage.fromJson({
      'total': 1, 'visited': false, 'visitRadius': 75, 'hasMore': false,
      'comments': [
        {'id': 1, 'body': 'Piękny gotyk', 'createdAt': '2026-10-11T10:00:00.000Z', 'isMine': false,
         'author': {'id': 2, 'displayName': 'Ola', 'level': 4, 'rankIndex': 1, 'rankName': 'Spacerowicz'}},
      ],
    });
    expect(page.visited, isFalse);
    expect(page.comments.single.author.level, 4);

    final board = Leaderboard.fromJson({
      'totalPlayers': 2,
      'entries': [
        {'position': 1, 'id': 2, 'displayName': 'Ola', 'totalXp': 300, 'level': 4, 'isMe': false},
      ],
      'me': {'position': 2, 'id': 3, 'displayName': 'Ja', 'totalXp': 0, 'isMe': true},
    });
    expect(board.me?.position, 2);
    expect(board.entries.single.isMe, isFalse);
    expect(board.entries.single.isFriend, isFalse);
  });

  test('Znajomi: kod, zaproszenia, status relacji i oznaczenia ZNAJOMY', () {
    final overview = FriendsOverview.fromJson({
      'myCode': 'K7Q2MX',
      'friends': [
        {'id': 2, 'displayName': 'Ola', 'friendCode': 'AB3CDE', 'level': 4, 'rankIndex': 1,
         'rankName': 'Spacerowicz', 'totalXp': 300, 'visitedCount': 3},
      ],
      'incoming': [
        {'id': 5, 'displayName': 'Kuba', 'friendCode': 'ZZ9XYW'},
      ],
      'outgoing': [],
    });
    expect(overview.myCode, 'K7Q2MX');
    expect(overview.friends.single.totalXp, 300);
    expect(overview.incoming.single.level, 1);
    expect(overview.outgoing, isEmpty);

    expect(FriendStatus.fromApi('FRIENDS'), FriendStatus.friends);
    expect(FriendStatus.fromApi('INCOMING'), FriendStatus.incoming);
    expect(FriendStatus.fromApi('PENDING'), FriendStatus.outgoing);
    expect(FriendStatus.fromApi(null), FriendStatus.none);

    final accepted = FriendActionResult.fromJson({
      'status': 'ACCEPTED',
      'message': 'Ola jest teraz Twoim znajomym!',
      'rewards': {'progression': {'xpGained': 25, 'level': 2}, 'newAchievements': []},
    });
    expect(accepted.status, FriendStatus.friends);
    expect(accepted.rewards?.xpGained, 25);
    final pending = FriendActionResult.fromJson({'status': 'PENDING', 'message': 'ok', 'rewards': null});
    expect(pending.rewards, isNull);

    final profile = PublicProfile.fromJson({
      'id': 2, 'displayName': 'Ola', 'friendCode': 'AB3CDE', 'createdAt': '2026-10-11T10:00:00.000Z',
      'isMe': false, 'friendStatus': 'FRIENDS', 'level': 4, 'rank': {'index': 1, 'name': 'Spacerowicz'},
    });
    expect(profile.isFriend, isTrue);
    expect(profile.copyWith(friendStatus: FriendStatus.none).isFriend, isFalse);
    expect(profile.copyWith(friendStatus: FriendStatus.none).friendCode, 'AB3CDE');

    final author = CommentAuthor.fromJson({'id': 2, 'displayName': 'Ola', 'isFriend': true});
    expect(author.isFriend, isTrue);
    final entry = LeaderboardEntry.fromJson({'position': 1, 'id': 2, 'displayName': 'Ola', 'isFriend': true});
    expect(entry.isFriend, isTrue);
  });
}
