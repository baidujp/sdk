// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "helpers/on_object.dart";
import "helpers/on_object.dart" as p2;

void main() {
  Object o = 1;
  Expect.equals("object", o.onObject);
}
