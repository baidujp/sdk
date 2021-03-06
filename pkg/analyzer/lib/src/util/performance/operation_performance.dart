// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// The performance of an operation.
abstract class OperationPerformance {
  /// The child operations, might be empty.
  List<OperationPerformance> get children;

  /// The duration of this operation, including its children.
  Duration get elapsed;

  /// The duration of this operation, excluding its children.
  Duration get elapsedSelf;

  /// The name of the operation.
  String get name;

  OperationPerformance getChild(String name);

  /// Write this operation and its children into the [buffer].
  void write({
    @required StringBuffer buffer,
    String indent = '',
  });
}

class OperationPerformanceImpl implements OperationPerformance {
  @override
  final String name;

  final Stopwatch _timer = Stopwatch();
  final List<OperationPerformance> _children = [];

  OperationPerformanceImpl(this.name);

  @override
  List<OperationPerformance> get children {
    return _children;
  }

  @override
  Duration get elapsed {
    return _timer.elapsed;
  }

  @override
  Duration get elapsedSelf {
    return elapsed - _elapsedChildren;
  }

  Duration get _elapsedChildren {
    return children.fold<Duration>(
      Duration.zero,
      (sum, child) => sum + child.elapsed,
    );
  }

  @override
  OperationPerformance getChild(String name) {
    return children.firstWhere(
      (child) => child.name == name,
      orElse: () => null,
    );
  }

  /// Run the [operation] as a child with the given [name].
  ///
  /// If there is no such child, a new one is created, with a new timer.
  ///
  /// If there is already a child with that name, its timer will resume and
  /// then stop. So, it will accumulate time across all runs.
  T run<T>(
    String name,
    T Function(OperationPerformanceImpl) operation,
  ) {
    OperationPerformanceImpl child = _existingOrNewChild(name);
    child._timer.start();

    try {
      return operation(child);
    } finally {
      child._timer.stop();
    }
  }

  /// Run the [operation] as a child with the given [name].
  ///
  /// If there is no such child, a new one is created, with a new timer.
  ///
  /// If there is already a child with that name, its timer will resume and
  /// then stop. So, it will accumulate time across all runs.
  Future<T> runAsync<T>(
    String name,
    Future<T> Function(OperationPerformanceImpl) operation,
  ) async {
    var child = _existingOrNewChild(name);
    child._timer.start();

    try {
      return await operation(child);
    } finally {
      child._timer.stop();
    }
  }

  @override
  String toString() {
    return '(name: $name, elapsed: $elapsed, elapsedSelf: $elapsedSelf)';
  }

  @override
  void write({StringBuffer buffer, String indent = ''}) {
    buffer.writeln('$indent${toString()}');

    var childIndent = '$indent  ';
    for (var child in children) {
      child.write(buffer: buffer, indent: childIndent);
    }
  }

  OperationPerformanceImpl _existingOrNewChild(String name) {
    var child = getChild(name);
    if (child == null) {
      child = OperationPerformanceImpl(name);
      _children.add(child);
    }
    return child;
  }
}
