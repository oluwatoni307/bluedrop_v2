// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_logs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WaterLogs)
const waterLogsProvider = WaterLogsProvider._();

final class WaterLogsProvider
    extends $AsyncNotifierProvider<WaterLogs, WaterLoggingState> {
  const WaterLogsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waterLogsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waterLogsHash();

  @$internal
  @override
  WaterLogs create() => WaterLogs();
}

String _$waterLogsHash() => r'7b5cf34c73653a78b334dd5db299e04e7be64326';

abstract class _$WaterLogs extends $AsyncNotifier<WaterLoggingState> {
  FutureOr<WaterLoggingState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<WaterLoggingState>, WaterLoggingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WaterLoggingState>, WaterLoggingState>,
              AsyncValue<WaterLoggingState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
