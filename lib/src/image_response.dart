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

/// An [Component] that serves an image.
class ImageResponse extends StatelessComponent {
  /// The component that will be used to generate the image.
  final Component component;

  /// The options for generating the image.
  final RenderOptions options;

  /// Creates an [ImageResponse] with the given [component] and [options].
  ImageResponse(this.component, {this.options = const RenderOptions()});

  @override
  Component build(BuildContext ctx) {
    ctx.setHeader('Content-Type', mimeType(options.format ?? .webp));
    final renderer = Renderer();
    final bytes = renderer.renderSync(fromComponent(component), options);
    renderer.dispose();
    ctx.setStatusCode(200, responseBody: bytes);

    return _sentinelComponent;
  }
}
