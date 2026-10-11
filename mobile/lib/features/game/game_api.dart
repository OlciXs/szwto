import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';
import '../friends/friends_api.dart';
import '../monuments/models/monument.dart';
import '../monuments/monuments_api.dart';
import 'models/duel.dart';

class GameApi {
  GameApi._();
  static final GameApi instance = GameApi._();

  final _client = ApiClient.instance;

  // Przechowywanie lokalnych pojedynków (fallback gdy backend nie jest jeszcze zaktualizowany na Renderze)
  final List<DuelSummary> _localDuels = [];
  final Map<int, DuelDetail> _localDuelDetails = {};

  Future<DuelEligibility> getEligibility() async {
    try {
      final data = await _client.get('/game/eligibility') as Map<String, dynamic>;
      return DuelEligibility.fromJson(data);
    } catch (_) {
      // Fallback: pobierz z FriendsApi i MonumentsApi
      final friendsOverview = await FriendsApi.instance.getOverview();
      final allMonuments = await MonumentsApi.instance.getMonuments();
      final visitedCount = allMonuments.where((m) => m.visited).length;

      final eligibleFriends = friendsOverview.friends.map((f) {
        return EligibleFriend(
          id: f.id,
          displayName: f.displayName,
          friendCode: f.friendCode,
          level: f.level,
          rankIndex: f.rankIndex,
          rankName: f.rankName,
          totalXp: f.totalXp,
          visitedCount: f.visitedCount,
          isEligible: f.visitedCount >= 10,
        );
      }).toList();

      return DuelEligibility(
        myVisitedCount: visitedCount,
        isEligible: visitedCount >= 10,
        minCardsRequired: 10,
        friends: eligibleFriends,
      );
    }
  }

  Future<List<DuelSummary>> getDuels() async {
    try {
      final list = await _client.get('/game/duels') as List<dynamic>;
      return list
          .map((d) => DuelSummary.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List.unmodifiable(_localDuels);
    }
  }

  Future<Map<String, dynamic>> createDuel({
    int? opponentId,
    bool isBot = false,
  }) async {
    try {
      final body = <String, dynamic>{
        if (opponentId != null) 'opponentId': opponentId,
        if (isBot) 'isBot': true,
      };
      final data = await _client.post('/game/duels', body) as Map<String, dynamic>;
      return data;
    } catch (_) {
      // Lokalny fallback pojedynku
      return await _createLocalDuel(opponentId: opponentId, isBot: isBot);
    }
  }

  Future<DuelDetail> getDuel(int duelId) async {
    try {
      final data = await _client.get('/game/duels/$duelId') as Map<String, dynamic>;
      return DuelDetail.fromJson(data);
    } catch (_) {
      final local = _localDuelDetails[duelId];
      if (local != null) return local;
      throw ApiException(404, 'Nie znaleziono pojedynku.');
    }
  }

  Future<void> removeDuel(int duelId) async {
    try {
      await _client.delete('/game/duels/$duelId');
    } catch (_) {
      if (!_localDuels.any((duel) => duel.id == duelId)) rethrow;
      _localDuels.removeWhere((duel) => duel.id == duelId);
      _localDuelDetails.remove(duelId);
    }
  }

  Future<DuelAnswersResult> submitAnswers(
    int duelId,
    List<String> answers,
  ) async {
    try {
      final data = await _client.post(
        '/game/duels/$duelId/answers',
        {'answers': answers},
      ) as Map<String, dynamic>;
      return DuelAnswersResult.fromJson(data);
    } catch (_) {
      return _submitLocalAnswers(duelId, answers);
    }
  }

  Future<Map<String, dynamic>> _createLocalDuel({
    int? opponentId,
    bool isBot = false,
  }) async {
    final monuments = await MonumentsApi.instance.getMonuments();
    final visited = monuments.where((m) => m.visited).toList();

    var myPool = visited;
    if (myPool.length < 10) {
      // W trybie demo jeśli gracz ma mniej niż 10 kart, użyj dostępnych zabytków
      myPool = monuments.take(15).toList();
    }

    String opponentName = 'Wrocławski Przewodnik';
    if (opponentId != null && !isBot) {
      final overview = await FriendsApi.instance.getOverview();
      final friend = overview.friends.where((f) => f.id == opponentId).firstOrNull;
      if (friend != null) opponentName = friend.displayName;
    }

    final rng = Random();
    final duelId = DateTime.now().millisecondsSinceEpoch % 1000000;
    final code = rng.nextInt(900000 + 100000).toString();

    // Generowanie 3 rund
    final rounds = <DuelRoundData>[];
    final usedCenter = <int>{};
    final usedCreator = <int>{};

    for (int r = 1; r <= 3; r++) {
      var availableCreator = myPool.where((m) => !usedCreator.contains(m.id)).toList();
      if (availableCreator.isEmpty) availableCreator = myPool;
      final cCard = availableCreator[rng.nextInt(availableCreator.length)];
      usedCreator.add(cCard.id);

      final otherMonuments = monuments.where((m) => m.id != cCard.id).toList();
      final oCard = otherMonuments[rng.nextInt(otherMonuments.length)];

      final centerPool = monuments
          .where((m) => m.id != cCard.id && m.id != oCard.id && !usedCenter.contains(m.id))
          .toList();
      final centerCard = centerPool.isNotEmpty
          ? centerPool[rng.nextInt(centerPool.length)]
          : monuments.first;
      usedCenter.add(centerCard.id);

      final cDist = Geolocator.distanceBetween(
        centerCard.latitude,
        centerCard.longitude,
        cCard.latitude,
        cCard.longitude,
      ).round();

      final oDist = Geolocator.distanceBetween(
        centerCard.latitude,
        centerCard.longitude,
        oCard.latitude,
        oCard.longitude,
      ).round();

      final closer = cDist <= oDist ? 'CREATOR' : 'OPPONENT';

      rounds.add(DuelRoundData(
        roundNumber: r,
        centerMonument: _toDuelCard(centerCard),
        creatorMonument: _toDuelCard(cCard),
        opponentMonument: _toDuelCard(oCard),
        creatorDistanceMeters: cDist,
        opponentDistanceMeters: oDist,
        closer: closer,
      ));
    }

    final detail = DuelDetail(
      id: duelId,
      code: code,
      roundsCount: 3,
      isCreator: true,
      creatorName: _client.displayName ?? 'Ty',
      opponentName: opponentName,
      isBot: isBot || opponentId == null,
      rounds: rounds,
      hasPlayed: false,
      isFinished: false,
    );

    _localDuelDetails[duelId] = detail;

    final summary = DuelSummary(
      id: duelId,
      code: code,
      rounds: 3,
      createdAt: DateTime.now(),
      isCreator: true,
      creatorName: _client.displayName ?? 'Ty',
      opponentName: opponentName,
      isBot: isBot || opponentId == null,
      hasPlayed: false,
      opponentHasPlayed: false,
      isFinished: false,
      status: 'YOUR_TURN',
    );
    _localDuels.insert(0, summary);

    return {'id': duelId, 'code': code};
  }

  DuelAnswersResult _submitLocalAnswers(int duelId, List<String> answers) {
    final detail = _localDuelDetails[duelId];
    if (detail == null) {
      throw ApiException(404, 'Nie znaleziono pojedynku.');
    }

    int score = 0;
    final results = <RoundResultData>[];

    for (int i = 0; i < detail.rounds.length; i++) {
      final round = detail.rounds[i];
      final answer = i < answers.length ? answers[i] : 'CREATOR';
      final isCorrect = answer == round.closer;
      if (isCorrect) score++;

      results.add(RoundResultData(
        roundNumber: round.roundNumber,
        yourChoice: answer,
        closer: round.closer,
        isCorrect: isCorrect,
        centerMonument: round.centerMonument,
        creatorMonument: round.creatorMonument,
        opponentMonument: round.opponentMonument,
        creatorDistanceMeters: round.creatorDistanceMeters,
        opponentDistanceMeters: round.opponentDistanceMeters,
      ));
    }

    final botScore = 1 + Random().nextInt(3);

    // Zaktualizuj stan lokalny
    final updatedDetail = DuelDetail(
      id: detail.id,
      code: detail.code,
      roundsCount: detail.roundsCount,
      isCreator: detail.isCreator,
      creatorName: detail.creatorName,
      opponentName: detail.opponentName,
      isBot: detail.isBot,
      myScore: score,
      opponentScore: botScore,
      hasPlayed: true,
      isFinished: true,
      rounds: detail.rounds,
    );
    _localDuelDetails[duelId] = updatedDetail;

    final sumIdx = _localDuels.indexWhere((d) => d.id == duelId);
    if (sumIdx != -1) {
      _localDuels[sumIdx] = DuelSummary(
        id: detail.id,
        code: detail.code,
        rounds: 3,
        createdAt: _localDuels[sumIdx].createdAt,
        finishedAt: DateTime.now(),
        isCreator: true,
        creatorName: detail.creatorName,
        opponentName: detail.opponentName,
        isBot: detail.isBot,
        myScore: score,
        opponentScore: botScore,
        hasPlayed: true,
        opponentHasPlayed: true,
        isFinished: true,
        status: 'FINISHED',
      );
    }

    final winner = score > botScore ? 'YOU' : (score < botScore ? 'OPPONENT' : 'DRAW');

    return DuelAnswersResult(
      score: score,
      totalRounds: 3,
      isFinished: true,
      myScore: score,
      opponentScore: botScore,
      winner: winner,
      roundResults: results,
    );
  }

  DuelCardItem _toDuelCard(Monument m) {
    return DuelCardItem(
      id: m.id,
      name: m.name,
      category: m.category,
      rawType: m.rawType,
      rarity: m.rarity,
      builtLabel: m.builtLabel,
      thumbUrl: m.thumbUrl,
      latitude: m.latitude,
      longitude: m.longitude,
    );
  }
}
