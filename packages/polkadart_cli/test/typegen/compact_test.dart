import 'package:polkadart_cli/polkadart_cli.dart'
    show CompactDescriptor, EmptyDescriptor, VariantBuilder, parseTypes;
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart' show ByteInput;
import 'package:substrate_metadata/substrate_metadata.dart' as metadata;
import 'package:test/test.dart';

/// Registry mirroring `MultiAddress<AccountId32, ()>`, the Substrate default for
/// any chain without an `indices` pallet: `AccountIndex` resolves to `()`, so
/// `MultiAddress::Index` is a bare variant byte on the wire.
final registry = <metadata.PortableType>[
  metadata.PortableType(
    id: 0,
    type: metadata.PortableTypeDef(
      path: ['sp_runtime', 'multiaddress', 'MultiAddress'],
      params: [],
      typeDef: metadata.TypeDefVariant(
        variants: [
          metadata.VariantDef(
            name: 'Id',
            index: 0,
            fields: [metadata.Field(type: 1, typeName: 'AccountId')],
          ),
          metadata.VariantDef(
            name: 'Index',
            index: 1,
            fields: [metadata.Field(type: 4, typeName: 'AccountIndex')],
          ),
        ],
      ),
    ),
  ),
  metadata.PortableType(
    id: 1,
    type: metadata.PortableTypeDef(
      path: [],
      params: [],
      typeDef: metadata.TypeDefArray(length: 32, type: 2),
    ),
  ),
  metadata.PortableType(
    id: 2,
    type: metadata.PortableTypeDef(
      path: [],
      params: [],
      typeDef: metadata.TypeDefPrimitive(metadata.Primitive.U8),
    ),
  ),
  // The unit type `()`
  metadata.PortableType(
    id: 3,
    type: metadata.PortableTypeDef(
      path: [],
      params: [],
      typeDef: metadata.TypeDefTuple(fields: []),
    ),
  ),
  // `Compact<()>`
  metadata.PortableType(
    id: 4,
    type: metadata.PortableTypeDef(path: [], params: [], typeDef: metadata.TypeDefCompact(type: 3)),
  ),
  metadata.PortableType(
    id: 5,
    type: metadata.PortableTypeDef(
      path: [],
      params: [],
      typeDef: metadata.TypeDefPrimitive(metadata.Primitive.U32),
    ),
  ),
  // `Compact<u32>`
  metadata.PortableType(
    id: 6,
    type: metadata.PortableTypeDef(path: [], params: [], typeDef: metadata.TypeDefCompact(type: 5)),
  ),
];

void main() {
  group('Compact<T>', () {
    final generators = parseTypes(registry, './types');

    test('Compact<()> is zero sized', () {
      expect(generators[4], isA<EmptyDescriptor>());
      expect(generators[4]!.codec('./types').symbol, 'NullCodec');
    });

    test('Compact<u32> stays a compact integer', () {
      expect(generators[6], isA<CompactDescriptor>());
      expect(generators[6]!.codec('./types').symbol, 'CompactBigIntCodec');
    });

    test('MultiAddress::Index decodes from a single byte', () {
      final input = ByteInput.fromBytes([0x01]);
      (generators[0] as VariantBuilder).valueFrom('./types', input);
      expect(input.remainingLength, 0);
    });

    test('MultiAddress::Index encodes to a single byte', () {
      final generated = (generators[0] as VariantBuilder).build().build();

      expect(generated, isNot(contains('CompactBigIntCodec')));
      expect(
        generated,
        contains(
          'void encodeTo(_i1.Output output) {\n'
          '    _i1.U8Codec.codec.encodeTo(\n'
          '      1,\n'
          '      output,\n'
          '    );\n'
          '    _i1.NullCodec.codec.encodeTo(\n'
          '      value0,\n'
          '      output,\n'
          '    );\n'
          '  }',
        ),
      );
    });
  });
}
