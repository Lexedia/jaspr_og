import 'dart:async';

import 'package:jaspr/server.dart';
// ignore: implementation_imports
import 'package:jaspr/src/server/child_nodes.dart';
import 'package:jaspr_og/src/helper/presets.dart';
// ignore: implementation_imports
import 'package:shelf/src/headers.dart';
import 'package:takumi/takumi.dart' hide Style;

const voidElements = {'head', 'meta', 'script', 'link', 'style'};

Future<Node> fromComponent(Component component) async {
  final result = await fromComponentInternal(component);

  if (result.isEmpty) {
    return ContainerNode(rawStyle: {'width': '100%', 'height': '100%'});
  }

  if (result.length == 1) {
    return result.first;
  }

  return ContainerNode(
    children: result,
    rawStyle: {'width': '100%', 'height': '100%'},
  );
}

FutureOr<List<Node>> fromComponentInternal(Component component) async {
  final binding = ServerAppBinding((
    url: '/',
    headers: Headers.empty(),
  ), loadFile: (_) => Future.value(null));

  binding.initializeOptions(Jaspr.options);
  binding.attachRootComponent(component);

  final rootElement = binding.rootElement;
  if (rootElement == null) return [];

  if (rootElement.owner.isFirstBuild) {
    final completer = Completer<Null>.sync();
    rootElement.binding.addPostFrameCallback(completer.complete);
    await completer.future;
  }

  final rootElementRenderObject =
      binding.rootElement!.renderObject as MarkupRenderObject;

  return processComponent(rootElementRenderObject);
}

List<Node> fromChildren(ChildList component) => component
    .map((component) => processComponent(component))
    .expand((e) => e)
    .toList();

List<Node> processComponent(MarkupRenderObject renderObject) {
  if (renderObject is MarkupRenderText) {
    return [TextNode(renderObject.text, rawStyle: stylePresets['span']!)];
  }

  if (renderObject is MarkupRenderFragment) {
    return fromChildren(renderObject.children);
  }

  if (renderObject is MarkupRenderElement) {
    final tag = renderObject.tag;

    if (voidElements.contains(tag)) {
      return [];
    }

    switch (tag) {
      case 'br':
        return [
          TextNode(
            '\n',
            rawStyle: stylePresets['span']!,
            tw: renderObject.classes,
          ),
        ];
      case 'img':
        return [createImageElement(renderObject)];
      case 'svg':
        return [createSvgElement(renderObject)];
    }

    final style = extractStyle(renderObject);

    if (renderObject.children.isEmpty) {
      return [];
    }

    final children = fromChildren(renderObject.children);

    return [
      ContainerNode(
        children: children,
        rawStyle: style,
        tw: renderObject.classes,
      ),
    ];
  }

  return fromChildren(renderObject.children);
}

ImageNode createSvgElement(MarkupRenderElement component) {
  final style = extractStyle(component);
  final svg = component.renderToHtml();

  return ImageNode(svg, rawStyle: style, tw: component.classes);
}

ImageNode createImageElement(MarkupRenderElement component) {
  if (component.attributes?.containsKey('src') == false) {
    throw Exception('Image element must have a `src` attribute');
  }

  final style = extractStyle(component);

  return ImageNode(
    component.attributes!['src'] as String,
    rawStyle: style,
    tw: component.classes,
  );
}

Map<String, String>? extractStyle(MarkupRenderElement component) {
  final styles = component.styles;
  if (styles == null) {
    return null;
  }
  var base = <String, String>{};
  final camelisedStyles = Map.fromEntries(
    component.styles!.entries.map(
      (e) => MapEntry(kebabToCamel(e.key), e.value),
    ),
  );

  if (stylePresets.containsKey(component.tag)) {
    base = {...stylePresets[component.tag]!};
  }

  return {...base, ...camelisedStyles};
}

String kebabToCamel(String kebab) {
  return kebab
      .split('-')
      .map((word) {
        if (word == kebab.split('-').first) {
          return word;
        } else {
          return word[0].toUpperCase() + word.substring(1);
        }
      })
      .join('');
}
