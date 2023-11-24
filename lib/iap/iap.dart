/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' as foundation;
import 'package:gitjournal/logger/logger.dart';
import 'package:gitjournal/settings/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:universal_io/io.dart' show Platform;

class GitJournalInAppPurchases {
  static Future<void> confirmProPurchaseBoot() async {
    confirmPendingPurchases();

    var appConfig = AppConfig.instance;
    if (!appConfig.validateProMode) {
      return;
    }

    if (appConfig.proMode) {
      Log.i("confirmProPurchaseBoot: Already in ProMode");
      return;
    }
    if (foundation.kDebugMode) {
      Log.d("Ignoring IAP pro check - debug mode");
      return;
    }

    restorePurchases();
  }

  static Future<void> restorePurchases() async {
    Log.i("Trying to confirmProPurchase");
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e, stackTrace) {
      Log.e("Failed to get subscription status", ex: e, stacktrace: stackTrace);
      Log.i("Disabling Pro mode");

      Log.i("... Well actually... Enabling Pro mode!");
      AppConfig.instance.proMode = false;
      AppConfig.instance.save();
    }

    Log.i("(LB): ... Well actually... Enabling Pro mode!");
    AppConfig.instance.proMode = true;
    AppConfig.instance.save();
  }

  static Future<void> confirmPendingPurchases() async {
    /*
    // On iOS this results in a "Sign in with Apple ID" dialog
    if (!Platform.isAndroid) {
      return;
    }

    var availability = await GoogleApiAvailability.instance
        .checkGooglePlayServicesAvailability();
    if (availability != GooglePlayServicesAvailability.success) {
      Log.e("Google Play Services Not Available");
      return;
    }

    InAppPurchaseConnection.enablePendingPurchases();
    final iapCon = InAppPurchaseConnection.instance;

    var pastPurchases = await iapCon.queryPastPurchases();
    for (var pd in pastPurchases.pastPurchases) {
      if (pd.pendingCompletePurchase) {
        Log.i("Pending Complete Purchase - ${pd.productID}");

        try {
          var _ = await iapCon.completePurchase(pd);
        } catch (e, stackTrace) {
          logException(e, stackTrace);
        }
      }
    }
    */
  }
}

const base_url = 'https://us-central1-gitjournal-io.cloudfunctions.net';
const ios_url = '$base_url/IAPIosVerify';
const android_url = '$base_url/IAPAndroidVerify';

Future<DateTime?> getExpiryDate(
    String receipt, String sku, bool isPurchase) async {
  assert(receipt.isNotEmpty);

  var body = {
    'receipt': receipt,
    "sku": sku,
    'pseudoId': '',
    'is_purchase': isPurchase,
  };
  Log.i("getExpiryDate ${json.encode(body)}");

  var url = Uri.parse(Platform.isIOS ? ios_url : android_url);
  var response = await http.post(url, body: json.encode(body));
  if (response.statusCode != 200) {
    Log.e("Received Invalid Status Code from GCP IAP Verify", props: {
      "code": response.statusCode,
      "body": response.body,
    });
    throw IAPVerifyException(
      code: response.statusCode,
      body: response.body,
      receipt: receipt,
      sku: sku,
      isPurchase: isPurchase,
    );
  }

  Log.i("IAP Verify body: ${response.body}");

  var b = json.decode(response.body) as Map?;
  if (b == null || !b.containsKey("expiry_date")) {
    Log.e("Received Invalid Body from GCP IAP Verify", props: {
      "code": response.statusCode,
      "body": response.body,
    });
    return null;
  }

  var expiryDateMs = b['expiry_date'] as int;
  return DateTime.fromMillisecondsSinceEpoch(expiryDateMs, isUtc: true);
}

class SubscriptionStatus {
  final bool _isPro;

  SubscriptionStatus.basic() : _isPro = false;
  SubscriptionStatus.pro() : _isPro = true;

  bool get isActive => _isPro;

  @override
  String toString() => "SubscriptionStatus{isActive: $isActive}";
}

Future<SubscriptionStatus> verifyPurchase(PurchaseDetails purchase) async {
  var dt = await getExpiryDate(
    purchase.verificationData.serverVerificationData,
    purchase.productID,
    _isPurchase(purchase),
  );
  if (dt == null) {
    return SubscriptionStatus.basic();
  }
  return SubscriptionStatus.pro();
}

// Checks if it is a subscription or a purchase
bool _isPurchase(PurchaseDetails purchase) {
  var sku = purchase.productID;
  return !sku.contains('monthly') && !sku.contains('_sub_');
}

class IAPVerifyException implements Exception {
  final int code;
  final String body;
  final String receipt;
  final String sku;
  final bool isPurchase;

  IAPVerifyException({
    required this.code,
    required this.body,
    required this.receipt,
    required this.sku,
    required this.isPurchase,
  });

  @override
  String toString() {
    return "IAPVerifyException{code: $code, body: $body, receipt: $receipt, $sku: sku, isPurchase: $isPurchase}";
  }
}
