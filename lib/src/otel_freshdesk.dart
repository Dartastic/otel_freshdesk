// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_freshdesk_suppression.dart';

const _tracerName = 'dartastic_otel_libs_freshdesk';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps any Freshdesk API call in a CLIENT span.
Future<T> tracedFreshdesk<T>({
  required String resource,
  required String action,
  required String domain,
  required Future<T> Function() invoke,
  int? ticketId,
  int? contactId,
}) async {
  if (freshdeskInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'freshdesk.resource': resource,
    'freshdesk.action': action,
    'freshdesk.operation': '$resource.$action',
    'freshdesk.domain': domain,
  };
  if (ticketId != null) m['freshdesk.ticket.id'] = ticketId;
  if (contactId != null) m['freshdesk.contact.id'] = contactId;

  final span = _tracer().startSpan(
    'freshdesk $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
