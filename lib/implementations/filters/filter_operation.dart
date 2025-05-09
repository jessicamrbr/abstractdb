import 'package:abstractdb/implementations/filters/text.dart';
import 'package:collql/abstractions/types.dart' as collql show FilterOperation;
import 'package:collql/collql.dart' hide FilterOperation;

class FilterOperation extends collql.FilterOperation {
  static final and = collql.FilterOperation.and;
  static final or = collql.FilterOperation.or;
  static final not = collql.FilterOperation.not;

  static final eq = collql.FilterOperation.eq;
  static final gt = collql.FilterOperation.gt;
  static final gte = collql.FilterOperation.gte;
  static final lt = collql.FilterOperation.lt;
  static final lte = collql.FilterOperation.lte;
  static final within = collql.FilterOperation.within;
  static final notIn = collql.FilterOperation.notIn;
  static final regex = collql.FilterOperation.regex;

  static final text = FilterOperation(TextFilter('_', '').name);

  FilterOperation(super.name);
}