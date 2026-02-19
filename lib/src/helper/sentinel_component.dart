part of '../image_response.dart';

class _SentinelComponent implements Component {
  const _SentinelComponent();

  @override
  Element createElement() {
    return span([
      .text(
        'Tried to invoke the inner component of ImageResponse()\n'
        'This should not occur in normal circumstances.',
      ),
    ]).createElement();
  }

  @override
  Key? get key => null;
}

const _sentinelComponent = _SentinelComponent();
