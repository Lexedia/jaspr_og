part of '../image_response.dart';

class _SentinelComponent implements Component {
  const _SentinelComponent();

  @override
  Element createElement() {
    throw UnimplementedError(
      'Tried to invoke the inner component of ImageResponse()\n'
      'This should not occur in normal circumstances.',
    );
  }

  @override
  Key? get key => throw UnimplementedError();
}

const _sentinelComponent = _SentinelComponent();
