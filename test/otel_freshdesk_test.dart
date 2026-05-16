// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_freshdesk/otel_freshdesk.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_freshdesk-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('tickets.create records CLIENT span', () async {
    await tracedFreshdesk<String>(
      resource: 'tickets',
      action: 'create',
      domain: 'acme.freshdesk.com',
      ticketId: 42,
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('freshdesk tickets.create')!);
    expect(a['freshdesk.resource'], 'tickets');
    expect(a['freshdesk.action'], 'create');
    expect(a['freshdesk.operation'], 'tickets.create');
    expect(a['freshdesk.domain'], 'acme.freshdesk.com');
    expect(a['freshdesk.ticket.id'], 42);
  });

  test('suppression skips spans', () async {
    await runWithoutFreshdeskInstrumentationAsync(() async {
      await tracedFreshdesk<String>(
        resource: 'tickets',
        action: 'create',
        domain: 'd',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('freshdesk '), isEmpty);
  });
}
