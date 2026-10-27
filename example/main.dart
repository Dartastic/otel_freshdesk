// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_freshdesk/otel_freshdesk.dart';

/// Traces Freshdesk calls with OpenTelemetry.
///
/// `otel_freshdesk` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Freshdesk call in
/// [tracedFreshdesk]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'freshdesk-example');

  // Wraps any Freshdesk API call in a CLIENT span.
  final freshdeskId = await tracedFreshdesk<String>(
    resource: 'Order',
    action: 'example',
    domain: 'example',
    ticketId: 1,
    contactId: 1,
    invoke: () async {
      // Make the Freshdesk call here, then report what it returned.
      return 'freshdesk_8f3a2c';
    },
  );
  OTelLog.info('tracedFreshdesk returned $freshdeskId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutFreshdeskInstrumentationAsync.
  await runWithoutFreshdeskInstrumentationAsync(
    () => tracedFreshdesk<String>(
      resource: 'Order',
      action: 'example',
      domain: 'example',
      ticketId: 1,
      contactId: 1,
      invoke: () async {
        return 'freshdesk_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
