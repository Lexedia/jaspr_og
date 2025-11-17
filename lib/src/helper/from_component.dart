import 'package:jaspr_og/src/helper/presets.dart';
import 'package:jaspr/jaspr.dart';
import 'package:takumi/takumi.dart' hide Style;

const voidElements = {'head', 'meta', 'script', 'link', 'style'};

/// A helper function that converts a [Component] into a [Node].
Node fromComponent(Component component) {
  final result = fromComponentInternal(component);

  if (result.isEmpty) {
    return ContainerNode();
  }

  if (result.length == 1) {
    return result.first;
  }

  return ContainerNode(
    children: result,
    rawStyle: {'width': '100%', 'height': '100%'},
  );
}

List<Node> fromComponentInternal(Component component) {
  assert(
    component is Fragment ||
        component is Text ||
        component is DomComponent ||
        component is StatelessComponent,
    'Cannot collect from anything but Fragment|DomComponent|Text|StatelessComponent',
  );

  return processComponent(component);
}

List<Node> fromChildren(List<Component> component) => component
    .map((component) => fromComponentInternal(component))
    .expand((e) => e)
    .toList();

List<Node> processComponent(Component component) {
  if (component is Text) {
    return [TextNode(component.text, rawStyle: stylePresets['span'])];
  }

  if (component is Fragment) {
    return fromChildren(component.children);
  }

  if (component is StatelessComponent) {
    // im not too sure about this tbh
    final el = component.createElement();
    // ignore: invalid_use_of_protected_member
    return processComponent(component.build(el));
  }

  final type = (component as DomComponent).tag;

  if (voidElements.contains(type)) {
    return [];
  }

  if (isHtmlElement(component, 'br')) {
    return [
      TextNode('\n', rawStyle: stylePresets['span'], tw: component.classes),
    ];
  }

  if (isHtmlElement(component, 'img')) {
    return [createImageElement(component)];
  }

  if (isHtmlElement(component, 'svg')) {
    return [createSvgElement(component)];
  }

  final style = extractStyle(component);

  if (component.children == null) {
    return [];
  }

  final children = fromChildren(component.children!);

  return [
    ContainerNode(children: children, rawStyle: style, tw: component.classes),
  ];
}


bool isHtmlElement(DomComponent component, String tag) => component.tag == tag;

List<String> attrsToAttrsString(Map<String, String> attrs) {
  final c = {...attrs};
  c.remove('class');
  return c.entries.map((e) => '${e.key}="${e.value}"').toList();
}

String serialise(Map<String, String> attrs, DomComponent component) {
  final serialisedAttrs = attrsToAttrsString(attrs);
  final childrenString = component.children?.map(
    (c) {
      final child = c as DomComponent;
      return serialise(child.attributes!, child);
    },
  ).join('');
  return '<${component.tag}${serialisedAttrs.isNotEmpty ? ' ${serialisedAttrs.join(' ')}' : ''}>${childrenString ?? ''}</${component.tag}>';
}

String serialiseSvg(DomComponent component) {
  final attrs = component.attributes!;

  if (!attrs.containsKey('xmlns')) {
    final cloned = {...attrs, 'xmlns': 'http://www.w3.org/2000/svg'};

    return serialise(cloned, component);
  }

  return serialise(attrs, component);
}

ImageNode createSvgElement(DomComponent component) {
  final style = extractStyle(component);
  final svg = serialiseSvg(component);

  return ImageNode(svg, rawStyle: style, tw: component.classes);
}

ImageNode createImageElement(DomComponent component) {
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

Map<String, String>? extractStyle(DomComponent component) {
  final styles = component.styles;
  if (styles == null) {
    return null;
  }
  var base = <String, String>{};
  final camelisedStyles = Map.fromEntries(
    component.styles!.properties.entries.map(
      (e) => MapEntry(kebabToCamel(e.key), e.value),
    ),
  );

  if (stylePresets.containsKey(component.tag)) {
    base = {...stylePresets[component.tag]!};
  }

  return {...base, ...camelisedStyles};
}

String kebabToCamel(String kebab) {
  return kebab.split('-').map((word) {
    if (word == kebab.split('-').first) {
      return word;
    } else {
      return word[0].toUpperCase() + word.substring(1);
    }
  }).join('');
}
