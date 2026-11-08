import '../../../create_post/domain/entities/help_post_data.dart';
import '../../../create_post/domain/services/auth_gateway.dart';
import '../models/economy_result.dart';
import '../repositories/economy_store.dart';
import 'economy_engine.dart';
import 'period_provider.dart';

final class ServiceEconomyEngine implements EconomyEngine {
  ServiceEconomyEngine({
    required this.store,
    required this.auth,
    required this.periods,
    bool Function()? writesEnabled,
  }) : _writesEnabled = writesEnabled ?? (() => periods is! FakePeriodProvider);

  final EconomyStore store;
  final AuthGateway auth;
  final PeriodProvider periods;
  final bool Function() _writesEnabled;

  @override
  String newOperationId() => store.newOperationId();

  @override
  Future<EconomyResult> award({
    required EconomySource source,
    required String sourceId,
    required String operationId,
    int? rating,
  }) {
    return switch (source) {
      EconomySource.serviceUse =>
      rating == null
          ? (throw const EconomyFailure(EconomyFailureReason.invalidRating))
          : confirmService(
        postId: sourceId,
        rating: rating,
        operationId: operationId,
      ),
      EconomySource.attendedEvent => _awardSingleUserActivity(
        sourceId: sourceId,
        operationId: operationId,
        movementType: 'event_attended',
        xp: EconomyResult.eventXp,
        coins: EconomyResult.eventCoins,
      ),
      EconomySource.backpackVerified => _awardSingleUserActivity(
        sourceId: sourceId,
        operationId: operationId,
        movementType: 'backpack_verified',
        xp: EconomyResult.backpackXp,
        coins: EconomyResult.backpackCoins,
      ),
      EconomySource.completedFavor =>
      throw const EconomyFailure(EconomyFailureReason.unsupportedSource),
    };
  }

  Future<EconomyResult> _awardSingleUserActivity({
    required String sourceId,
    required String operationId,
    required String movementType,
    required int xp,
    required int coins,
  }) async {
    if (!_writesEnabled()) {
      throw const EconomyFailure(EconomyFailureReason.simulationActive);
    }
    final uid = auth.currentUid;
    if (uid == null || uid.isEmpty) {
      throw const EconomyFailure(EconomyFailureReason.noSession);
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{16,80}$').hasMatch(operationId) ||
        sourceId.isEmpty ||
        sourceId.contains('/')) {
      throw const EconomyFailure(EconomyFailureReason.invalidOperation);
    }
    final period = periods.currentPeriod;
    final confirmationId = '${movementType}_$sourceId';
    final userPath = 'users/$uid';
    final accountPath = 'users/$uid/private/account';
    final movementPath = 'users/$uid/movimientos/$confirmationId';

    return store.runTransaction((tx) async {
      final existingMovement = await tx.get(movementPath);
      if (existingMovement != null) {
        return EconomyResult(
          confirmationId: confirmationId,
          period: existingMovement['period'] as String,
          slot: 1,
          alreadyApplied: true,
          clientXp: xp,
          providerXp: 0,
          coins: coins,
        );
      }

      if (movementType == 'event_attended') {
        final post = await tx.get('posts/$sourceId');
        final response = await tx.get('posts/$sourceId/attendance/$uid');
        if (post?['category'] != 'event' ||
            post?['status'] != 'active' ||
            post?['authorId'] == uid ||
            response?['response'] != 'going') {
          throw const EconomyFailure(EconomyFailureReason.activityNotEligible);
        }
      }
      final userData = await tx.get(userPath);
      final accountData = await tx.get(accountPath);
      _validateUser(userData, period);
      if (coins > 0 && accountData?['availableCoins'] is! num) {
        throw const EconomyFailure(EconomyFailureReason.profileNotReady);
      }
      final timestamp = store.serverTimestamp;
      final currentCoins =
          (accountData?['availableCoins'] as num?) ?? 0;

      tx.update(
        userPath,
        _reward(userData!, xp, period, confirmationId, timestamp, activity: true),
      );
      if (coins > 0) {
        tx.update(accountPath, {'availableCoins': currentCoins + coins});
      }
      tx.create(movementPath, {
        ..._movement(
          confirmationId, uid, uid, sourceId, period, movementType, xp, timestamp,
        ),
        'deltaCoins': coins,
      });

      return EconomyResult(
        confirmationId: confirmationId,
        period: period,
        slot: 1,
        clientXp: xp,
        providerXp: 0,
        coins: coins,
      );
    });
  }

  @override
  Future<void> confirmFavor({
    required String postId,
    required String helperUid,
  }) async {
    if (!_writesEnabled()) {
      throw const EconomyFailure(EconomyFailureReason.simulationActive);
    }
    final author = auth.currentUid;
    if (author == null || author.isEmpty) {
      throw const EconomyFailure(EconomyFailureReason.noSession);
    }
    if (postId.isEmpty ||
        postId.contains('/') ||
        helperUid.isEmpty ||
        helperUid.contains('/') ||
        author == helperUid) {
      throw const EconomyFailure(EconomyFailureReason.invalidOperation);
    }
    final period = periods.currentPeriod;
    final offerPath = 'posts/$postId/helpOffers/$helperUid';
    final userPath = 'users/$helperUid';
    final movementId = 'favor_completed_$postId';
    const xp = EconomyResult.favorXp;
    const coins = EconomyResult.favorCoins;
    await store.runTransaction((tx) async {
      final post = await tx.get('posts/$postId');
      if (post?['category'] != 'help' ||
          post?['status'] != 'active' ||
          post?['authorId'] != author) {
        throw const EconomyFailure(EconomyFailureReason.activityNotEligible);
      }
      final offer = await tx.get(offerPath);
      if (offer == null) {
        throw const EconomyFailure(EconomyFailureReason.activityNotEligible);
      }
      if (offer['confirmedAt'] != null) return;
      final timestamp = store.serverTimestamp;
      if (HelpPostData.hasAuthorReward(post!['details'])) {
        tx.update(offerPath, {'confirmedAt': timestamp});
        return;
      }
      final helper = await tx.get(userPath);
      _validateUser(helper, period);
      tx.update(offerPath, {'confirmedAt': timestamp});
      tx.update(
        userPath,
        _reward(helper!, xp, period, movementId, timestamp, activity: true),
      );
      tx.increment('$userPath/private/account', 'availableCoins', coins);
      tx.create(
        '$userPath/movimientos/$movementId',
        {
          ..._movement(
            movementId, helperUid, author, postId, period, 'favor_completed', xp, timestamp,
          ),
          'deltaCoins': coins,
        },
      );
    });
  }

  @override
  Future<EconomyResult> confirmService({
    required String postId,
    required int rating,
    required String operationId,
  }) async {
    if (!_writesEnabled()) {
      throw const EconomyFailure(EconomyFailureReason.simulationActive);
    }
    final client = auth.currentUid;
    if (client == null || client.isEmpty) {
      throw const EconomyFailure(EconomyFailureReason.noSession);
    }
    if (rating < 1 || rating > 5) {
      throw const EconomyFailure(EconomyFailureReason.invalidRating);
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{16,80}$').hasMatch(operationId) ||
        postId.isEmpty ||
        postId.contains('/')) {
      throw const EconomyFailure(EconomyFailureReason.invalidOperation);
    }
    final receiptPath = 'users/$client/serviceOperations/$operationId';
    return store.runTransaction((tx) async {
      // Check first, so a committed operation remains idempotent across months,
      // or after a post was deleted. No fresh reward is issued in this branch.
      final receipt = await tx.get(receiptPath);
      if (receipt != null) {
        if (receipt['postId'] != postId || receipt['rating'] != rating) {
          throw const EconomyFailure(EconomyFailureReason.operationConflict);
        }
        return EconomyResult(
          confirmationId: receipt['confirmationId'] as String,
          period: receipt['period'] as String,
          slot: receipt['slot'] as int,
          alreadyApplied: true,
          coins: (receipt['coins'] as num?)?.toInt() ?? 0,
        );
      }
      final post = await tx.get('posts/$postId');
      if (post == null || post['category'] != 'service') {
        throw const EconomyFailure(EconomyFailureReason.serviceNotFound);
      }
      if (post['status'] != 'active') {
        throw const EconomyFailure(EconomyFailureReason.inactiveService);
      }
      // Never accept providerUid from the caller.
      final provider = post['authorId'];
      if (provider is! String || provider.isEmpty || provider.contains('/')) {
        throw const EconomyFailure(EconomyFailureReason.serviceNotFound);
      }
      if (provider == client) {
        throw const EconomyFailure(EconomyFailureReason.selfConfirmation);
      }
      final requestPath = 'posts/$postId/serviceRequests/$client';
      final request = await tx.get(requestPath);
      if (request?['providerCompletedAt'] == null ||
          request?['completionOperationId'] != operationId ||
          request?['completedAt'] != null) {
        throw const EconomyFailure(EconomyFailureReason.serviceNotDelivered);
      }
      final clientPath = 'users/$client';
      final providerPath = 'users/$provider';
      final clientData = await tx.get(clientPath);
      final providerData = await tx.get(providerPath);
      final period = periods.currentPeriod;
      _validateUser(clientData, period);
      _validateUser(providerData, period);
      final firstId = confirmationId(period, client, provider, 1);
      final secondId = confirmationId(period, client, provider, 2);
      final first = await tx.get('serviceConfirmations/$firstId');
      final second = await tx.get('serviceConfirmations/$secondId');
      if (first != null && second != null) {
        throw const EconomyFailure(
          EconomyFailureReason.monthlyPairLimitReached,
        );
      }
      final slot = first == null ? 1 : 2;
      final id = slot == 1 ? firstId : secondId;
      final timestamp = store.serverTimestamp;
      final count = (providerData!['reviewCount'] as num).toInt();
      final average = (providerData['averageStars'] as num).toDouble();
      final confirmation = <String, dynamic>{
        'id': id,
        'clientUid': client,
        'providerUid': provider,
        'postId': postId,
        'period': period,
        'slot': slot,
        'rating': rating,
        'operationId': operationId,
        'createdAt': timestamp,
      };
      // The completion and both rewards share one transaction.
      tx.update(
        clientPath,
        _reward(clientData!, EconomyResult.serviceClientXp, period, id, timestamp),
      );
      tx.update(providerPath, {
        ..._reward(providerData, EconomyResult.serviceProviderXp, period, id, timestamp),
        'reviewCount': count + 1,
        'averageStars': (average * count + rating) / (count + 1),
      });
      tx.increment('$clientPath/private/account', 'availableCoins', EconomyResult.serviceCoins);
      tx.increment('$providerPath/private/account', 'availableCoins', EconomyResult.serviceCoins);
      tx.update(requestPath, {
        'completedAt': timestamp,
        'confirmationId': id,
      });
      tx.create('serviceConfirmations/$id', confirmation);
      tx.create(receiptPath, {
        'confirmationId': id,
        'postId': postId,
        'providerUid': provider,
        'period': period,
        'slot': slot,
        'rating': rating,
        'coins': EconomyResult.serviceCoins,
        'createdAt': timestamp,
      });
      tx.create(
        '$clientPath/movimientos/$id',
        {
          ..._movement(
          id,
          client,
          provider,
          postId,
          period,
          'service_used_client',
          EconomyResult.serviceClientXp,
          timestamp,
          ),
          'deltaCoins': EconomyResult.serviceCoins,
        },
      );
      tx.create(
        '$providerPath/movimientos/$id',
        {
          ..._movement(
          id,
          provider,
          client,
          postId,
          period,
          'service_provided',
          EconomyResult.serviceProviderXp,
          timestamp,
          ),
          'deltaCoins': EconomyResult.serviceCoins,
        },
      );
      return EconomyResult(
        confirmationId: id,
        period: period,
        slot: slot,
        coins: EconomyResult.serviceCoins,
      );
    });
  }

  static String confirmationId(
      String period,
      String client,
      String provider,
      int slot,
      ) => '${period}_${client}_${provider}_$slot';

  void _validateUser(Map<String, dynamic>? data, String period) {
    if (data == null) {
      throw const EconomyFailure(EconomyFailureReason.userNotFound);
    }
    if (data['profileVersion'] != 1 ||
        data['xp'] is! num ||
        data['monthlyXp'] is! num ||
        data['rankingPeriod'] is! String ||
        data['averageStars'] is! num ||
        data['reviewCount'] is! num) {
      throw const EconomyFailure(EconomyFailureReason.profileNotReady);
    }
    if ((data['rankingPeriod'] as String).compareTo(period) > 0) {
      throw const EconomyFailure(EconomyFailureReason.futurePeriod);
    }
  }

  Map<String, dynamic> _reward(
      Map<String, dynamic> data,
      int xp,
      String period,
      String confirmation,
      Object timestamp, {
      bool activity = false,
      }) => {
    'xp': (data['xp'] as num) + xp,
    'monthlyXp':
    (data['rankingPeriod'] == period ? data['monthlyXp'] as num : 0) + xp,
    'rankingPeriod': period,
    (activity ? 'lastActivityReward' : 'lastServiceConfirmation'): confirmation,
    'updatedAt': timestamp,
  };

  Map<String, dynamic> _movement(
      String id,
      String uid,
      String counterpart,
      String postId,
      String period,
      String type,
      int xp,
      Object timestamp,
      ) => {
    'id': id,
    'confirmationId': id,
    'uid': uid,
    'counterpartyUid': counterpart,
    'type': type,
    'sourceId': postId,
    'deltaXpTotal': xp,
    'deltaXpMonth': xp,
    'deltaCoins': 0,
    'period': period,
    'status': 'released',
    'createdAt': timestamp,
  };
}
