import 'package:abstractdb/abstractions/types.dart';
import 'package:abstractdb/implementations/cursor.dart';
import 'package:abstractdb/utils/types.dart';

abstract class ReactivityAdapter<I, E> {
  ReactivityDecorator create();
}

abstract class ReactivityDecorator<I, E> extends Cursor<I, E> {
  dynamic _listenable;

  ReactivityDecorator(super.positions, super.getter, super.transformOut, {
    super.filter,
    super.options,
  });
  get listenable => _listenable;

  void notifyReactivity(Changeset changes);

  void onDisposeCursor(VoidCallback fn);
}