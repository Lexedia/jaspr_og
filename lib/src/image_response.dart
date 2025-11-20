import 'package:jaspr/server.dart';
import 'package:jaspr_og/src/helper/from_component.dart';
import 'package:takumi/takumi.dart';

part './helper/sentinel_component.dart';

String mimeType(OutputFormat format) => switch (format) {
  .png => 'image/png',
  .webp => 'image/webp',
  .avif => 'image/avif',
  .jpeg => 'image/jpeg',
  .raw => throw UnsupportedError('raw format isnt in this context'),
};

/// An [AsyncStatelessComponent] that serves an image.
///
/// You might also be interested in [ImageResponse] for a synchronous variant.
class ImageResponse extends AsyncStatelessComponent {
  /// The component that will be used to generate the image.
  final Component component;

  /// The options for generating the image.
  final RenderOptions options;

  /// Creates an [ImageResponse] with the given [component] and [options].
  const ImageResponse(
    this.component, {
    this.options = const RenderOptions(),
  });

  @override
  Future<Component> build(BuildContext ctx) async {
    ctx.setHeader('Content-Type', mimeType(options.format ?? .webp));
    final renderer = Renderer();
    final bytes = await renderer.render(
      await fromComponent(component),
      options,
    );
    renderer.dispose();
    ctx.setStatusCode(200, responseBody: bytes);

    return _sentinelComponent;
  }
}
