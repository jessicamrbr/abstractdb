import 'package:abstractdb/implementations/filters/filter_builder.dart';
import 'package:collql/collql.dart' hide FilterBuilder;

FilterBuilder where(FieldName field) => FilterBuilder(field);

extension TextFieldNameExt on FieldName {
  Filter text(String value) => where(this).text(value);
}

