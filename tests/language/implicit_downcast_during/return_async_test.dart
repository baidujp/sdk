// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class A {}

class B extends A {}

Future<B> f1(A a) async {
  return a as FutureOr<A>;
  //     ^^^^^^^^^^^^^^^^
  // [analyzer] STATIC_TYPE_WARNING.RETURN_OF_INVALID_TYPE
  //       ^
  // [cfe] A value of type 'FutureOr<A>' can't be assigned to a variable of type 'B'.
}

Future<B> f2(A a) async => a as FutureOr<A>;
//                         ^^^^^^^^^^^^^^^^
// [analyzer] STATIC_TYPE_WARNING.RETURN_OF_INVALID_TYPE
//                           ^
// [cfe] A value of type 'FutureOr<A>' can't be assigned to a variable of type 'B'.

main() async {
  Object b;
  A a = new B();
  b = await f1(a);
  b = await f2(a);
  a = new A();
}
