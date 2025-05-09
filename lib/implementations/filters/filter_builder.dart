import 'package:abstractdb/implementations/filters/text.dart';
import 'package:collql/collql.dart' as collql show FilterBuilder;
import 'package:collql/collql.dart' hide FilterBuilder;

class FilterBuilder extends collql.FilterBuilder {
  FilterBuilder(super.field);

  Filter text(String value) => TextFilter(field, value);
}