import 'package:collql/collql.dart';

class TextFilter extends FieldBasedFilter {

  TextFilter(super.field, String super.value);

  @override
  bool apply(Document doc) {
    throw FilterException("Text filter can not be applied on non indexed field $field");
  }
}