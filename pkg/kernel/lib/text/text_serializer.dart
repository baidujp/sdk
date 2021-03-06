// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.text_serializer;

import '../ast.dart';

import 'serializer_combinators.dart';

import '../visitor.dart' show ExpressionVisitor;

abstract class Tagger<T extends Node> {
  String tag(T node);
}

class NameTagger implements Tagger<Name> {
  const NameTagger();

  String tag(Name name) => name.isPrivate ? "private" : "public";
}

const TextSerializer<Name> publicName =
    const Wrapped(unwrapPublicName, wrapPublicName, const DartString());

String unwrapPublicName(Name name) => name.name;

Name wrapPublicName(String name) => new Name(name);

const TextSerializer<Name> privateName = const Wrapped(unwrapPrivateName,
    wrapPrivateName, Tuple2Serializer(const DartString(), const DartString()));

Tuple2<String, String> unwrapPrivateName(Name name) {
  return new Tuple2(name.library.importUri.toString(), name.name);
}

Name wrapPrivateName(Tuple2<String, String> tuple) {
  // We need a map from import URI to libraries.  More generally, we will need
  // a way to map any 'named' node to the node's reference.
  throw UnimplementedError('Deserialization of private names.');
}

TextSerializer<Name> nameSerializer = new Case(
    const NameTagger(), {"public": publicName, "private": privateName});

class ExpressionTagger extends ExpressionVisitor<String>
    implements Tagger<Expression> {
  const ExpressionTagger();

  String tag(Expression expression) => expression.accept(this);

  String visitStringLiteral(StringLiteral _) => "string";
  String visitIntLiteral(IntLiteral _) => "int";
  String visitDoubleLiteral(DoubleLiteral _) => "double";
  String visitBoolLiteral(BoolLiteral _) => "bool";
  String visitNullLiteral(NullLiteral _) => "null";
  String visitInvalidExpression(InvalidExpression _) => "invalid";
  String visitNot(Not _) => "not";
  String visitLogicalExpression(LogicalExpression expression) {
    return expression.operator;
  }

  String visitStringConcatenation(StringConcatenation _) => "concat";
  String visitSymbolLiteral(SymbolLiteral _) => "symbol";
  String visitThisExpression(ThisExpression _) => "this";
  String visitRethrow(Rethrow _) => "rethrow";
  String visitThrow(Throw _) => "throw";
  String visitAwaitExpression(AwaitExpression _) => "await";
  String visitConditionalExpression(ConditionalExpression _) => "cond";
  String visitIsExpression(IsExpression _) => "is";
  String visitAsExpression(AsExpression _) => "as";
  String visitTypeLiteral(TypeLiteral _) => "type";
  String visitListLiteral(ListLiteral expression) {
    return expression.isConst ? "const-list" : "list";
  }

  String visitSetLiteral(SetLiteral expression) {
    return expression.isConst ? "const-set" : "set";
  }

  String visitMapLiteral(MapLiteral expression) {
    return expression.isConst ? "const-map" : "map";
  }

  String visitLet(Let _) => "let";

  String visitPropertyGet(PropertyGet _) => "get-prop";
  String visitPropertySet(PropertySet _) => "set-prop";
  String visitSuperPropertyGet(SuperPropertyGet _) => "get-super";
  String visitSuperPropertySet(SuperPropertySet _) => "set-super";
  String visitMethodInvocation(MethodInvocation _) => "invoke-method";
  String visitSuperMethodInvocation(SuperMethodInvocation _) => "invoke-super";

  String visitVariableGet(VariableGet _) => "get-var";
  String visitVariableSet(VariableSet _) => "set-var";
  String visitStaticGet(StaticGet _) => "get-static";
  String visitStaticSet(StaticSet _) => "set-static";
  String visitDirectPropertyGet(DirectPropertyGet _) => "get-direct-prop";
  String visitDirectPropertySet(DirectPropertySet _) => "set-direct-prop";
  String visitStaticInvocation(StaticInvocation expression) {
    return expression.isConst ? "invoke-const-static" : "invoke-static";
  }

  String visitDirectMethodInvocation(DirectMethodInvocation _) {
    return "invoke-direct-method";
  }

  String visitConstructorInvocation(ConstructorInvocation expression) {
    return expression.isConst
        ? "invoke-const-constructor"
        : "invoke-constructor";
  }

  String visitFunctionExpression(FunctionExpression _) => "fun";
  String visitListConcatenation(ListConcatenation _) => "lists";
  String visitSetConcatenation(SetConcatenation _) => "sets";
  String visitMapConcatenation(MapConcatenation _) => "maps";
  String visitBlockExpression(BlockExpression _) => "let-block";
  String visitInstantiation(Instantiation _) => "apply";
  String visitNullCheck(NullCheck _) => "not-null";
  String visitFileUriExpression(FileUriExpression _) => "with-uri";
  String visitCheckLibraryIsLoaded(CheckLibraryIsLoaded _) => "is-loaded";
  String visitLoadLibrary(LoadLibrary _) => "load";
  String visitConstantExpression(ConstantExpression _) => "const";
  String visitInstanceCreation(InstanceCreation _) => "object";
}

const TextSerializer<InvalidExpression> invalidExpressionSerializer =
    const Wrapped(
        unwrapInvalidExpression, wrapInvalidExpression, const DartString());

String unwrapInvalidExpression(InvalidExpression expression) {
  return expression.message;
}

InvalidExpression wrapInvalidExpression(String message) {
  return new InvalidExpression(message);
}

TextSerializer<Not> notSerializer =
    new Wrapped(unwrapNot, wrapNot, expressionSerializer);

Expression unwrapNot(Not expression) => expression.operand;

Not wrapNot(Expression operand) => new Not(operand);

TextSerializer<LogicalExpression> logicalAndSerializer = new Wrapped(
    unwrapLogicalExpression,
    wrapLogicalAnd,
    new Tuple2Serializer(expressionSerializer, expressionSerializer));

Tuple2<Expression, Expression> unwrapLogicalExpression(
    LogicalExpression expression) {
  return new Tuple2(expression.left, expression.right);
}

LogicalExpression wrapLogicalAnd(Tuple2<Expression, Expression> tuple) {
  return new LogicalExpression(tuple.first, '&&', tuple.second);
}

TextSerializer<LogicalExpression> logicalOrSerializer = new Wrapped(
    unwrapLogicalExpression,
    wrapLogicalOr,
    new Tuple2Serializer(expressionSerializer, expressionSerializer));

LogicalExpression wrapLogicalOr(Tuple2<Expression, Expression> tuple) {
  return new LogicalExpression(tuple.first, '||', tuple.second);
}

TextSerializer<StringConcatenation> stringConcatenationSerializer = new Wrapped(
    unwrapStringConcatenation,
    wrapStringConcatenation,
    new ListSerializer(expressionSerializer));

List<Expression> unwrapStringConcatenation(StringConcatenation expression) {
  return expression.expressions;
}

StringConcatenation wrapStringConcatenation(List<Expression> expressions) {
  return new StringConcatenation(expressions);
}

const TextSerializer<StringLiteral> stringLiteralSerializer =
    const Wrapped(unwrapStringLiteral, wrapStringLiteral, const DartString());

String unwrapStringLiteral(StringLiteral literal) => literal.value;

StringLiteral wrapStringLiteral(String value) => new StringLiteral(value);

const TextSerializer<IntLiteral> intLiteralSerializer =
    const Wrapped(unwrapIntLiteral, wrapIntLiteral, const DartInt());

int unwrapIntLiteral(IntLiteral literal) => literal.value;

IntLiteral wrapIntLiteral(int value) => new IntLiteral(value);

const TextSerializer<DoubleLiteral> doubleLiteralSerializer =
    const Wrapped(unwrapDoubleLiteral, wrapDoubleLiteral, const DartDouble());

double unwrapDoubleLiteral(DoubleLiteral literal) => literal.value;

DoubleLiteral wrapDoubleLiteral(double value) => new DoubleLiteral(value);

const TextSerializer<BoolLiteral> boolLiteralSerializer =
    const Wrapped(unwrapBoolLiteral, wrapBoolLiteral, const DartBool());

bool unwrapBoolLiteral(BoolLiteral literal) => literal.value;

BoolLiteral wrapBoolLiteral(bool value) => new BoolLiteral(value);

const TextSerializer<NullLiteral> nullLiteralSerializer =
    const Wrapped(unwrapNullLiteral, wrapNullLiteral, const Nothing());

void unwrapNullLiteral(NullLiteral literal) {}

NullLiteral wrapNullLiteral(void ignored) => new NullLiteral();

const TextSerializer<SymbolLiteral> symbolLiteralSerializer =
    const Wrapped(unwrapSymbolLiteral, wrapSymbolLiteral, const DartString());

String unwrapSymbolLiteral(SymbolLiteral expression) => expression.value;

SymbolLiteral wrapSymbolLiteral(String value) => new SymbolLiteral(value);

const TextSerializer<ThisExpression> thisExpressionSerializer =
    const Wrapped(unwrapThisExpression, wrapThisExpression, const Nothing());

void unwrapThisExpression(ThisExpression expression) {}

ThisExpression wrapThisExpression(void ignored) => new ThisExpression();

const TextSerializer<Rethrow> rethrowSerializer =
    const Wrapped(unwrapRethrow, wrapRethrow, const Nothing());

void unwrapRethrow(Rethrow expression) {}

Rethrow wrapRethrow(void ignored) => new Rethrow();

TextSerializer<Throw> throwSerializer =
    new Wrapped(unwrapThrow, wrapThrow, expressionSerializer);

Expression unwrapThrow(Throw expression) => expression.expression;

Throw wrapThrow(Expression expression) => new Throw(expression);

TextSerializer<AwaitExpression> awaitExpressionSerializer = new Wrapped(
    unwrapAwaitExpression, wrapAwaitExpression, expressionSerializer);

Expression unwrapAwaitExpression(AwaitExpression expression) =>
    expression.operand;

AwaitExpression wrapAwaitExpression(Expression operand) =>
    new AwaitExpression(operand);

TextSerializer<ConditionalExpression> conditionalExpressionSerializer =
    new Wrapped(
        unwrapConditionalExpression,
        wrapConditionalExpression,
        new Tuple4Serializer(expressionSerializer, dartTypeSerializer,
            expressionSerializer, expressionSerializer));

Tuple4<Expression, DartType, Expression, Expression>
    unwrapConditionalExpression(ConditionalExpression expression) {
  return new Tuple4(expression.condition, expression.staticType,
      expression.then, expression.otherwise);
}

ConditionalExpression wrapConditionalExpression(
    Tuple4<Expression, DartType, Expression, Expression> tuple) {
  return new ConditionalExpression(
      tuple.first, tuple.third, tuple.fourth, tuple.second);
}

TextSerializer<IsExpression> isExpressionSerializer = new Wrapped(
    unwrapIsExpression,
    wrapIsExpression,
    new Tuple2Serializer(expressionSerializer, dartTypeSerializer));

Tuple2<Expression, DartType> unwrapIsExpression(IsExpression expression) {
  return new Tuple2(expression.operand, expression.type);
}

IsExpression wrapIsExpression(Tuple2<Expression, DartType> tuple) {
  return new IsExpression(tuple.first, tuple.second);
}

TextSerializer<AsExpression> asExpressionSerializer = new Wrapped(
    unwrapAsExpression,
    wrapAsExpression,
    new Tuple2Serializer(expressionSerializer, dartTypeSerializer));

Tuple2<Expression, DartType> unwrapAsExpression(AsExpression expression) {
  return new Tuple2(expression.operand, expression.type);
}

AsExpression wrapAsExpression(Tuple2<Expression, DartType> tuple) {
  return new AsExpression(tuple.first, tuple.second);
}

TextSerializer<TypeLiteral> typeLiteralSerializer =
    new Wrapped(unwrapTypeLiteral, wrapTypeLiteral, dartTypeSerializer);

DartType unwrapTypeLiteral(TypeLiteral expression) => expression.type;

TypeLiteral wrapTypeLiteral(DartType type) => new TypeLiteral(type);

TextSerializer<ListLiteral> listLiteralSerializer = new Wrapped(
    unwrapListLiteral,
    wrapListLiteral,
    new Tuple2Serializer(
        dartTypeSerializer, new ListSerializer(expressionSerializer)));

Tuple2<DartType, List<Expression>> unwrapListLiteral(ListLiteral expression) {
  return new Tuple2(expression.typeArgument, expression.expressions);
}

ListLiteral wrapListLiteral(Tuple2<DartType, List<Expression>> tuple) {
  return new ListLiteral(tuple.second,
      typeArgument: tuple.first, isConst: false);
}

TextSerializer<ListLiteral> constListLiteralSerializer = new Wrapped(
    unwrapListLiteral,
    wrapConstListLiteral,
    new Tuple2Serializer(
        dartTypeSerializer, new ListSerializer(expressionSerializer)));

ListLiteral wrapConstListLiteral(Tuple2<DartType, List<Expression>> tuple) {
  return new ListLiteral(tuple.second,
      typeArgument: tuple.first, isConst: true);
}

TextSerializer<SetLiteral> setLiteralSerializer = new Wrapped(
    unwrapSetLiteral,
    wrapSetLiteral,
    new Tuple2Serializer(
        dartTypeSerializer, new ListSerializer(expressionSerializer)));

Tuple2<DartType, List<Expression>> unwrapSetLiteral(SetLiteral expression) {
  return new Tuple2(expression.typeArgument, expression.expressions);
}

SetLiteral wrapSetLiteral(Tuple2<DartType, List<Expression>> tuple) {
  return new SetLiteral(tuple.second,
      typeArgument: tuple.first, isConst: false);
}

TextSerializer<SetLiteral> constSetLiteralSerializer = new Wrapped(
    unwrapSetLiteral,
    wrapConstSetLiteral,
    new Tuple2Serializer(
        dartTypeSerializer, new ListSerializer(expressionSerializer)));

SetLiteral wrapConstSetLiteral(Tuple2<DartType, List<Expression>> tuple) {
  return new SetLiteral(tuple.second, typeArgument: tuple.first, isConst: true);
}

TextSerializer<MapLiteral> mapLiteralSerializer = new Wrapped(
    unwrapMapLiteral,
    wrapMapLiteral,
    new Tuple3Serializer(dartTypeSerializer, dartTypeSerializer,
        new ListSerializer(expressionSerializer)));

Tuple3<DartType, DartType, List<Expression>> unwrapMapLiteral(
    MapLiteral expression) {
  List<Expression> entries = new List(2 * expression.entries.length);
  for (int from = 0, to = 0; from < expression.entries.length; ++from) {
    MapEntry entry = expression.entries[from];
    entries[to++] = entry.key;
    entries[to++] = entry.value;
  }
  return new Tuple3(expression.keyType, expression.valueType, entries);
}

MapLiteral wrapMapLiteral(Tuple3<DartType, DartType, List<Expression>> tuple) {
  List<MapEntry> entries = new List(tuple.third.length ~/ 2);
  for (int from = 0, to = 0; to < entries.length; ++to) {
    entries[to] = new MapEntry(tuple.third[from++], tuple.third[from++]);
  }
  return new MapLiteral(entries,
      keyType: tuple.first, valueType: tuple.second, isConst: false);
}

TextSerializer<MapLiteral> constMapLiteralSerializer = new Wrapped(
    unwrapMapLiteral,
    wrapConstMapLiteral,
    new Tuple3Serializer(dartTypeSerializer, dartTypeSerializer,
        new ListSerializer(expressionSerializer)));

MapLiteral wrapConstMapLiteral(
    Tuple3<DartType, DartType, List<Expression>> tuple) {
  List<MapEntry> entries = new List(tuple.third.length ~/ 2);
  for (int from = 0, to = 0; to < entries.length; ++to) {
    entries[to] = new MapEntry(tuple.third[from++], tuple.third[from++]);
  }
  return new MapLiteral(entries,
      keyType: tuple.first, valueType: tuple.second, isConst: true);
}

TextSerializer<Let> letSerializer = new Wrapped(unwrapLet, wrapLet,
    new Bind(variableDeclarationSerializer, expressionSerializer));

Tuple2<VariableDeclaration, Expression> unwrapLet(Let expression) {
  return new Tuple2(expression.variable, expression.body);
}

Let wrapLet(Tuple2<VariableDeclaration, Expression> tuple) {
  return new Let(tuple.first, tuple.second);
}

TextSerializer<PropertyGet> propertyGetSerializer = new Wrapped(
    unwrapPropertyGet,
    wrapPropertyGet,
    new Tuple2Serializer(expressionSerializer, nameSerializer));

Tuple2<Expression, Name> unwrapPropertyGet(PropertyGet expression) {
  return new Tuple2(expression.receiver, expression.name);
}

PropertyGet wrapPropertyGet(Tuple2<Expression, Name> tuple) {
  return new PropertyGet(tuple.first, tuple.second);
}

TextSerializer<PropertySet> propertySetSerializer = new Wrapped(
    unwrapPropertySet,
    wrapPropertySet,
    new Tuple3Serializer(
        expressionSerializer, nameSerializer, expressionSerializer));

Tuple3<Expression, Name, Expression> unwrapPropertySet(PropertySet expression) {
  return new Tuple3(expression.receiver, expression.name, expression.value);
}

PropertySet wrapPropertySet(Tuple3<Expression, Name, Expression> tuple) {
  return new PropertySet(tuple.first, tuple.second, tuple.third);
}

TextSerializer<SuperPropertyGet> superPropertyGetSerializer =
    new Wrapped(unwrapSuperPropertyGet, wrapSuperPropertyGet, nameSerializer);

Name unwrapSuperPropertyGet(SuperPropertyGet expression) {
  return expression.name;
}

SuperPropertyGet wrapSuperPropertyGet(Name name) {
  return new SuperPropertyGet(name);
}

TextSerializer<SuperPropertySet> superPropertySetSerializer = new Wrapped(
    unwrapSuperPropertySet,
    wrapSuperPropertySet,
    new Tuple2Serializer(nameSerializer, expressionSerializer));

Tuple2<Name, Expression> unwrapSuperPropertySet(SuperPropertySet expression) {
  return new Tuple2(expression.name, expression.value);
}

SuperPropertySet wrapSuperPropertySet(Tuple2<Name, Expression> tuple) {
  return new SuperPropertySet(tuple.first, tuple.second, null);
}

TextSerializer<MethodInvocation> methodInvocationSerializer = new Wrapped(
    unwrapMethodInvocation,
    wrapMethodInvocation,
    new Tuple3Serializer(
        expressionSerializer, nameSerializer, argumentsSerializer));

Tuple3<Expression, Name, Arguments> unwrapMethodInvocation(
    MethodInvocation expression) {
  return new Tuple3(expression.receiver, expression.name, expression.arguments);
}

MethodInvocation wrapMethodInvocation(
    Tuple3<Expression, Name, Arguments> tuple) {
  return new MethodInvocation(tuple.first, tuple.second, tuple.third);
}

TextSerializer<SuperMethodInvocation> superMethodInvocationSerializer =
    new Wrapped(unwrapSuperMethodInvocation, wrapSuperMethodInvocation,
        new Tuple2Serializer(nameSerializer, argumentsSerializer));

Tuple2<Name, Arguments> unwrapSuperMethodInvocation(
    SuperMethodInvocation expression) {
  return new Tuple2(expression.name, expression.arguments);
}

SuperMethodInvocation wrapSuperMethodInvocation(Tuple2<Name, Arguments> tuple) {
  return new SuperMethodInvocation(tuple.first, tuple.second);
}

TextSerializer<VariableGet> variableGetSerializer = new Wrapped(
    unwrapVariableGet,
    wrapVariableGet,
    new Tuple2Serializer(const ScopedUse<VariableDeclaration>(),
        new Optional(dartTypeSerializer)));

Tuple2<VariableDeclaration, DartType> unwrapVariableGet(VariableGet node) {
  return new Tuple2<VariableDeclaration, DartType>(
      node.variable, node.promotedType);
}

VariableGet wrapVariableGet(Tuple2<VariableDeclaration, DartType> tuple) {
  return new VariableGet(tuple.first, tuple.second);
}

TextSerializer<VariableSet> variableSetSerializer = new Wrapped(
    unwrapVariableSet,
    wrapVariableSet,
    new Tuple2Serializer(
        const ScopedUse<VariableDeclaration>(), expressionSerializer));

Tuple2<VariableDeclaration, Expression> unwrapVariableSet(VariableSet node) {
  return new Tuple2<VariableDeclaration, Expression>(node.variable, node.value);
}

VariableSet wrapVariableSet(Tuple2<VariableDeclaration, Expression> tuple) {
  return new VariableSet(tuple.first, tuple.second);
}

class CanonicalNameSerializer extends TextSerializer<CanonicalName> {
  static const String delimiter = "::";

  const CanonicalNameSerializer();

  static void writeName(CanonicalName name, StringBuffer buffer) {
    if (!name.isRoot) {
      if (!name.parent.isRoot) {
        writeName(name.parent, buffer);
        buffer.write(delimiter);
      }
      buffer.write(name.name);
    }
  }

  CanonicalName readFrom(Iterator<Object> stream, DeserializationState state) {
    String string = const DartString().readFrom(stream, state);
    CanonicalName name = state.nameRoot;
    for (String s in string.split(delimiter)) {
      name = name.getChild(s);
    }
    return name;
  }

  void writeTo(
      StringBuffer buffer, CanonicalName name, SerializationState state) {
    StringBuffer sb = new StringBuffer();
    writeName(name, sb);
    const DartString().writeTo(buffer, sb.toString(), state);
  }
}

const TextSerializer<StaticGet> staticGetSerializer = const Wrapped(
    unwrapStaticGet, wrapStaticGet, const CanonicalNameSerializer());

CanonicalName unwrapStaticGet(StaticGet expression) {
  return expression.targetReference.canonicalName;
}

StaticGet wrapStaticGet(CanonicalName name) {
  return new StaticGet.byReference(name.getReference());
}

TextSerializer<StaticSet> staticSetSerializer = new Wrapped(
    unwrapStaticSet,
    wrapStaticSet,
    new Tuple2Serializer(
        const CanonicalNameSerializer(), expressionSerializer));

Tuple2<CanonicalName, Expression> unwrapStaticSet(StaticSet expression) {
  return new Tuple2(expression.targetReference.canonicalName, expression.value);
}

StaticSet wrapStaticSet(Tuple2<CanonicalName, Expression> tuple) {
  return new StaticSet.byReference(tuple.first.getReference(), tuple.second);
}

TextSerializer<DirectPropertyGet> directPropertyGetSerializer = new Wrapped(
    unwrapDirectPropertyGet,
    wrapDirectPropertyGet,
    new Tuple2Serializer(
        expressionSerializer, const CanonicalNameSerializer()));

Tuple2<Expression, CanonicalName> unwrapDirectPropertyGet(
    DirectPropertyGet expression) {
  return new Tuple2(
      expression.receiver, expression.targetReference.canonicalName);
}

DirectPropertyGet wrapDirectPropertyGet(
    Tuple2<Expression, CanonicalName> tuple) {
  return new DirectPropertyGet.byReference(
      tuple.first, tuple.second.getReference());
}

TextSerializer<DirectPropertySet> directPropertySetSerializer = new Wrapped(
    unwrapDirectPropertySet,
    wrapDirectPropertySet,
    new Tuple3Serializer(expressionSerializer, const CanonicalNameSerializer(),
        expressionSerializer));

Tuple3<Expression, CanonicalName, Expression> unwrapDirectPropertySet(
    DirectPropertySet expression) {
  return new Tuple3(expression.receiver,
      expression.targetReference.canonicalName, expression.value);
}

DirectPropertySet wrapDirectPropertySet(
    Tuple3<Expression, CanonicalName, Expression> tuple) {
  return new DirectPropertySet.byReference(
      tuple.first, tuple.second.getReference(), tuple.third);
}

TextSerializer<StaticInvocation> staticInvocationSerializer = new Wrapped(
    unwrapStaticInvocation,
    wrapStaticInvocation,
    new Tuple2Serializer(const CanonicalNameSerializer(), argumentsSerializer));

Tuple2<CanonicalName, Arguments> unwrapStaticInvocation(
    StaticInvocation expression) {
  return new Tuple2(
      expression.targetReference.canonicalName, expression.arguments);
}

StaticInvocation wrapStaticInvocation(Tuple2<CanonicalName, Arguments> tuple) {
  return new StaticInvocation.byReference(
      tuple.first.getReference(), tuple.second,
      isConst: false);
}

TextSerializer<StaticInvocation> constStaticInvocationSerializer = new Wrapped(
    unwrapStaticInvocation,
    wrapConstStaticInvocation,
    new Tuple2Serializer(const CanonicalNameSerializer(), argumentsSerializer));

StaticInvocation wrapConstStaticInvocation(
    Tuple2<CanonicalName, Arguments> tuple) {
  return new StaticInvocation.byReference(
      tuple.first.getReference(), tuple.second,
      isConst: true);
}

TextSerializer<DirectMethodInvocation> directMethodInvocationSerializer =
    new Wrapped(
        unwrapDirectMethodInvocation,
        wrapDirectMethodInvocation,
        new Tuple3Serializer(expressionSerializer,
            const CanonicalNameSerializer(), argumentsSerializer));

Tuple3<Expression, CanonicalName, Arguments> unwrapDirectMethodInvocation(
    DirectMethodInvocation expression) {
  return new Tuple3(expression.receiver,
      expression.targetReference.canonicalName, expression.arguments);
}

DirectMethodInvocation wrapDirectMethodInvocation(
    Tuple3<Expression, CanonicalName, Arguments> tuple) {
  return new DirectMethodInvocation.byReference(
      tuple.first, tuple.second.getReference(), tuple.third);
}

TextSerializer<ConstructorInvocation> constructorInvocationSerializer =
    new Wrapped(
        unwrapConstructorInvocation,
        wrapConstructorInvocation,
        new Tuple2Serializer(
            const CanonicalNameSerializer(), argumentsSerializer));

Tuple2<CanonicalName, Arguments> unwrapConstructorInvocation(
    ConstructorInvocation expression) {
  return new Tuple2(
      expression.targetReference.canonicalName, expression.arguments);
}

ConstructorInvocation wrapConstructorInvocation(
    Tuple2<CanonicalName, Arguments> tuple) {
  return new ConstructorInvocation.byReference(
      tuple.first.getReference(), tuple.second,
      isConst: false);
}

TextSerializer<ConstructorInvocation> constConstructorInvocationSerializer =
    new Wrapped(unwrapConstructorInvocation, wrapConstConstructorInvocation,
        Tuple2Serializer(const CanonicalNameSerializer(), argumentsSerializer));

ConstructorInvocation wrapConstConstructorInvocation(
    Tuple2<CanonicalName, Arguments> tuple) {
  return new ConstructorInvocation.byReference(
      tuple.first.getReference(), tuple.second,
      isConst: true);
}

TextSerializer<FunctionExpression> functionExpressionSerializer = new Wrapped(
    unwrapFunctionExpression, wrapFunctionExpression, functionNodeSerializer);

FunctionNode unwrapFunctionExpression(FunctionExpression expression) {
  return expression.function;
}

FunctionExpression wrapFunctionExpression(FunctionNode node) {
  return new FunctionExpression(node);
}

TextSerializer<ListConcatenation> listConcatenationSerializer = Wrapped(
    (lc) => Tuple2(lc.typeArgument, lc.lists),
    (t) => ListConcatenation(t.second, typeArgument: t.first),
    Tuple2Serializer(dartTypeSerializer, ListSerializer(expressionSerializer)));

TextSerializer<SetConcatenation> setConcatenationSerializer = Wrapped(
    (sc) => Tuple2(sc.typeArgument, sc.sets),
    (t) => SetConcatenation(t.second, typeArgument: t.first),
    Tuple2Serializer(dartTypeSerializer, ListSerializer(expressionSerializer)));

TextSerializer<MapConcatenation> mapConcatenationSerializer = Wrapped(
    (mc) => Tuple3(mc.keyType, mc.valueType, mc.maps),
    (t) => MapConcatenation(t.third, keyType: t.first, valueType: t.second),
    Tuple3Serializer(dartTypeSerializer, dartTypeSerializer,
        ListSerializer(expressionSerializer)));

TextSerializer<BlockExpression> blockExpressionSerializer = Wrapped(
    (be) => Tuple2(be.body, be.value),
    (t) => BlockExpression(t.first, t.second),
    Tuple2Serializer(blockSerializer, expressionSerializer));

TextSerializer<Instantiation> instantiationSerializer = Wrapped(
    (i) => Tuple2(i.expression, i.typeArguments),
    (t) => Instantiation(t.first, t.second),
    Tuple2Serializer(expressionSerializer, ListSerializer(dartTypeSerializer)));

TextSerializer<NullCheck> nullCheckSerializer =
    Wrapped((nc) => nc.operand, (op) => NullCheck(op), expressionSerializer);

TextSerializer<FileUriExpression> fileUriExpressionSerializer = Wrapped(
    (fue) => Tuple2(fue.expression, fue.fileUri),
    (t) => FileUriExpression(t.first, t.second),
    Tuple2Serializer(expressionSerializer, const UriSerializer()));

TextSerializer<CheckLibraryIsLoaded> checkLibraryIsLoadedSerializer = Wrapped(
    (clil) => clil.import,
    (i) => CheckLibraryIsLoaded(i),
    libraryDependencySerializer);

TextSerializer<LoadLibrary> loadLibrarySerializer = Wrapped(
    (ll) => ll.import, (i) => LoadLibrary(i), libraryDependencySerializer);

TextSerializer<ConstantExpression> constantExpressionSerializer = Wrapped(
    (ce) => Tuple2(ce.constant, ce.type),
    (t) => ConstantExpression(t.first, t.second),
    Tuple2Serializer(constantSerializer, dartTypeSerializer));

TextSerializer<InstanceCreation> instanceCreationSerializer = Wrapped(
    (ic) => Tuple6(
        ic.classReference.canonicalName,
        ic.typeArguments,
        ic.fieldValues.keys.map((r) => r.canonicalName).toList(),
        ic.fieldValues.values.toList(),
        ic.asserts,
        ic.unusedArguments),
    (t) => InstanceCreation(t.first.getReference(), t.second,
        Map.fromIterables(t.third, t.fourth), t.fifth, t.sixth),
    Tuple6Serializer(
        CanonicalNameSerializer(),
        ListSerializer(dartTypeSerializer),
        ListSerializer(CanonicalNameSerializer()),
        ListSerializer(expressionSerializer),
        ListSerializer(assertStatementSerializer),
        ListSerializer(expressionSerializer)));

Case<Expression> expressionSerializer =
    new Case.uninitialized(const ExpressionTagger());

TextSerializer<NamedExpression> namedExpressionSerializer = new Wrapped(
    unwrapNamedExpression,
    wrapNamedExpression,
    new Tuple2Serializer(const DartString(), expressionSerializer));

Tuple2<String, Expression> unwrapNamedExpression(NamedExpression expression) {
  return new Tuple2(expression.name, expression.value);
}

NamedExpression wrapNamedExpression(Tuple2<String, Expression> tuple) {
  return new NamedExpression(tuple.first, tuple.second);
}

TextSerializer<Arguments> argumentsSerializer = new Wrapped(
    unwrapArguments,
    wrapArguments,
    Tuple3Serializer(
        new ListSerializer(dartTypeSerializer),
        new ListSerializer(expressionSerializer),
        new ListSerializer(namedExpressionSerializer)));

Tuple3<List<DartType>, List<Expression>, List<NamedExpression>> unwrapArguments(
    Arguments arguments) {
  return new Tuple3(arguments.types, arguments.positional, arguments.named);
}

Arguments wrapArguments(
    Tuple3<List<DartType>, List<Expression>, List<NamedExpression>> tuple) {
  return new Arguments(tuple.second, types: tuple.first, named: tuple.third);
}

class VariableDeclarationTagger implements Tagger<VariableDeclaration> {
  const VariableDeclarationTagger();

  String tag(VariableDeclaration decl) {
    if (decl.isCovariant) throw UnimplementedError("Covariant declaration.");
    if (decl.isFieldFormal) throw UnimplementedError("Initializing formal.");
    if (decl.isConst) {
      // It's not clear what invariants we assume about const/final.  For now
      // throw if we have both.
      if (decl.isFinal) throw UnimplementedError("const and final");
      return "const";
    }
    if (decl.isFinal) {
      return "final";
    }
    return "var";
  }
}

TextSerializer<VariableDeclaration> varDeclarationSerializer = new Wrapped(
    unwrapVariableDeclaration,
    wrapVarDeclaration,
    Tuple3Serializer(dartTypeSerializer, new Optional(expressionSerializer),
        new ListSerializer(expressionSerializer)));

Tuple3<DartType, Expression, List<Expression>> unwrapVariableDeclaration(
    VariableDeclaration declaration) {
  return new Tuple3(
      declaration.type, declaration.initializer, declaration.annotations);
}

VariableDeclaration wrapVarDeclaration(
    Tuple3<DartType, Expression, List<Expression>> tuple) {
  var result = new VariableDeclaration(null,
      initializer: tuple.second, type: tuple.first);
  for (int i = 0; i < tuple.third.length; ++i) {
    result.addAnnotation(tuple.third[i]);
  }
  return result;
}

TextSerializer<VariableDeclaration> finalDeclarationSerializer = new Wrapped(
    unwrapVariableDeclaration,
    wrapFinalDeclaration,
    Tuple3Serializer(dartTypeSerializer, new Optional(expressionSerializer),
        new ListSerializer(expressionSerializer)));

VariableDeclaration wrapFinalDeclaration(
    Tuple3<DartType, Expression, List<Expression>> tuple) {
  var result = new VariableDeclaration(null,
      initializer: tuple.second, type: tuple.first, isFinal: true);
  for (int i = 0; i < tuple.third.length; ++i) {
    result.addAnnotation(tuple.third[i]);
  }
  return result;
}

TextSerializer<VariableDeclaration> constDeclarationSerializer = new Wrapped(
    unwrapVariableDeclaration,
    wrapConstDeclaration,
    Tuple3Serializer(dartTypeSerializer, new Optional(expressionSerializer),
        new ListSerializer(expressionSerializer)));

VariableDeclaration wrapConstDeclaration(
    Tuple3<DartType, Expression, List<Expression>> tuple) {
  var result = new VariableDeclaration(null,
      initializer: tuple.second, type: tuple.first, isConst: true);
  for (int i = 0; i < tuple.third.length; ++i) {
    result.addAnnotation(tuple.third[i]);
  }
  return result;
}

TextSerializer<VariableDeclaration> variableDeclarationSerializer = Wrapped(
    (v) => Tuple2(v.name, v),
    (t) => t.second..name = t.first,
    Binder(Case(VariableDeclarationTagger(), {
      "var": varDeclarationSerializer,
      "final": finalDeclarationSerializer,
      "const": constDeclarationSerializer,
    })));

TextSerializer<TypeParameter> typeParameterSerializer = Wrapped(
    (p) => Tuple2(p.name, p),
    (t) => t.second..name = t.first,
    Binder(Wrapped((_) => null, (_) => TypeParameter(), const Nothing())));

TextSerializer<List<TypeParameter>> typeParametersSerializer = new Zip(
    new Rebind(
        new Zip(
            new Rebind(new ListSerializer(typeParameterSerializer),
                new ListSerializer(dartTypeSerializer)),
            zipTypeParameterBound,
            unzipTypeParameterBound),
        new ListSerializer(dartTypeSerializer)),
    zipTypeParameterDefaultType,
    unzipTypeParameterDefaultType);

TypeParameter zipTypeParameterBound(TypeParameter node, DartType bound) {
  return node..bound = bound;
}

Tuple2<TypeParameter, DartType> unzipTypeParameterBound(TypeParameter node) {
  return new Tuple2(node, node.bound);
}

TypeParameter zipTypeParameterDefaultType(
    TypeParameter node, DartType defaultType) {
  return node..defaultType = defaultType;
}

Tuple2<TypeParameter, DartType> unzipTypeParameterDefaultType(
    TypeParameter node) {
  return new Tuple2(node, node.defaultType);
}

class DartTypeTagger extends DartTypeVisitor<String>
    implements Tagger<DartType> {
  const DartTypeTagger();

  String tag(DartType type) => type.accept(this);

  String visitInvalidType(InvalidType _) => "invalid";
  String visitDynamicType(DynamicType _) => "dynamic";
  String visitVoidType(VoidType _) => "void";
  String visitBottomType(BottomType _) => "bottom";
  String visitFunctionType(FunctionType _) => "->";
  String visitTypeParameterType(TypeParameterType _) => "par";
  String visitInterfaceType(InterfaceType _) => "interface";
  String visitNeverType(NeverType _) => "never";
  String visitTypedefType(TypedefType _) => "typedef";
  String visitFutureOrType(FutureOrType _) => "futureor";
}

const TextSerializer<InvalidType> invalidTypeSerializer =
    const Wrapped(unwrapInvalidType, wrapInvalidType, const Nothing());

void unwrapInvalidType(InvalidType type) {}

InvalidType wrapInvalidType(void ignored) => const InvalidType();

const TextSerializer<DynamicType> dynamicTypeSerializer =
    const Wrapped(unwrapDynamicType, wrapDynamicType, const Nothing());

void unwrapDynamicType(DynamicType type) {}

DynamicType wrapDynamicType(void ignored) => const DynamicType();

const TextSerializer<VoidType> voidTypeSerializer =
    const Wrapped(unwrapVoidType, wrapVoidType, const Nothing());

void unwrapVoidType(VoidType type) {}

VoidType wrapVoidType(void ignored) => const VoidType();

const TextSerializer<BottomType> bottomTypeSerializer =
    const Wrapped(unwrapBottomType, wrapBottomType, const Nothing());

void unwrapBottomType(BottomType type) {}

BottomType wrapBottomType(void ignored) => const BottomType();

const TextSerializer<NeverType> neverTypeSerializer =
    const Wrapped(unwrapNeverType, wrapNeverType, const Nothing());

void unwrapNeverType(NeverType type) {}

NeverType wrapNeverType(void ignored) => const NeverType(Nullability.legacy);

// TODO(dmitryas):  Also handle nameParameters, and typedefType.
TextSerializer<FunctionType> functionTypeSerializer = new Wrapped(
    unwrapFunctionType,
    wrapFunctionType,
    new Bind(
        typeParametersSerializer,
        new Tuple4Serializer(
            new ListSerializer(dartTypeSerializer),
            new ListSerializer(dartTypeSerializer),
            new ListSerializer(namedTypeSerializer),
            dartTypeSerializer)));

Tuple2<List<TypeParameter>,
        Tuple4<List<DartType>, List<DartType>, List<NamedType>, DartType>>
    unwrapFunctionType(FunctionType type) {
  return new Tuple2(
      type.typeParameters,
      new Tuple4(
          type.positionalParameters.sublist(0, type.requiredParameterCount),
          type.positionalParameters.sublist(type.requiredParameterCount),
          type.namedParameters,
          type.returnType));
}

FunctionType wrapFunctionType(
    Tuple2<List<TypeParameter>,
            Tuple4<List<DartType>, List<DartType>, List<NamedType>, DartType>>
        tuple) {
  return new FunctionType(tuple.second.first + tuple.second.second,
      tuple.second.fourth, Nullability.legacy,
      requiredParameterCount: tuple.second.first.length,
      typeParameters: tuple.first,
      namedParameters: tuple.second.third);
}

TextSerializer<NamedType> namedTypeSerializer = new Wrapped(unwrapNamedType,
    wrapNamedType, Tuple2Serializer(const DartString(), dartTypeSerializer));

Tuple2<String, DartType> unwrapNamedType(NamedType namedType) {
  return new Tuple2(namedType.name, namedType.type);
}

NamedType wrapNamedType(Tuple2<String, DartType> tuple) {
  return new NamedType(tuple.first, tuple.second);
}

TextSerializer<TypeParameterType> typeParameterTypeSerializer = new Wrapped(
    unwrapTypeParameterType,
    wrapTypeParameterType,
    Tuple2Serializer(
        new ScopedUse<TypeParameter>(), new Optional(dartTypeSerializer)));

Tuple2<TypeParameter, DartType> unwrapTypeParameterType(
    TypeParameterType node) {
  return new Tuple2(node.parameter, node.promotedBound);
}

TypeParameterType wrapTypeParameterType(Tuple2<TypeParameter, DartType> tuple) {
  return new TypeParameterType(tuple.first, Nullability.legacy, tuple.second);
}

TextSerializer<InterfaceType> interfaceTypeSerializer = new Wrapped(
    unwrapInterfaceType,
    wrapInterfaceType,
    Tuple2Serializer(const CanonicalNameSerializer(),
        new ListSerializer(dartTypeSerializer)));

Tuple2<CanonicalName, List<DartType>> unwrapInterfaceType(InterfaceType node) {
  return new Tuple2(node.className.canonicalName, node.typeArguments);
}

InterfaceType wrapInterfaceType(Tuple2<CanonicalName, List<DartType>> tuple) {
  return new InterfaceType.byReference(
      tuple.first.reference, Nullability.legacy, tuple.second);
}

TextSerializer<TypedefType> typedefTypeSerializer = new Wrapped(
    unwrapTypedefType,
    wrapTypedefType,
    Tuple2Serializer(const CanonicalNameSerializer(),
        new ListSerializer(dartTypeSerializer)));

Tuple2<CanonicalName, List<DartType>> unwrapTypedefType(TypedefType node) {
  return new Tuple2(node.typedefReference.canonicalName, node.typeArguments);
}

TypedefType wrapTypedefType(Tuple2<CanonicalName, List<DartType>> tuple) {
  return new TypedefType.byReference(
      tuple.first.reference, Nullability.legacy, tuple.second);
}

TextSerializer<FutureOrType> futureOrTypeSerializer =
    new Wrapped(unwrapFutureOrType, wrapFutureOrType, dartTypeSerializer);

DartType unwrapFutureOrType(FutureOrType node) {
  return node.typeArgument;
}

FutureOrType wrapFutureOrType(DartType typeArgument) {
  return new FutureOrType(typeArgument, Nullability.legacy);
}

Case<DartType> dartTypeSerializer =
    new Case.uninitialized(const DartTypeTagger());

class StatementTagger extends StatementVisitor<String>
    implements Tagger<Statement> {
  const StatementTagger();

  String tag(Statement statement) => statement.accept(this);

  String visitExpressionStatement(ExpressionStatement _) => "expr";
  String visitReturnStatement(ReturnStatement node) {
    return node.expression == null ? "ret-void" : "ret";
  }

  String visitYieldStatement(YieldStatement _) => "yield";
  String visitBlock(Block _) => "block";
  String visitVariableDeclaration(VariableDeclaration _) => "local";
  String visitIfStatement(IfStatement node) {
    return node.otherwise == null ? "if" : "if-else";
  }

  String visitEmptyStatement(EmptyStatement node) => "skip";
  String visitWhileStatement(WhileStatement node) => "while";
  String visitDoStatement(DoStatement node) => "do-while";
  String visitForStatement(ForStatement node) => "for";
  String visitForInStatement(ForInStatement node) {
    return node.isAsync ? "await-for-in" : "for-in";
  }

  String visitAssertStatement(AssertStatement node) => "assert";
  String visitAssertBlock(AssertBlock node) => "assert-block";
  String visitLabeledStatement(LabeledStatement node) => "label";
  String visitBreakStatement(BreakStatement node) => "break";
}

TextSerializer<ExpressionStatement> expressionStatementSerializer = new Wrapped(
    unwrapExpressionStatement, wrapExpressionStatement, expressionSerializer);

Expression unwrapExpressionStatement(ExpressionStatement statement) {
  return statement.expression;
}

ExpressionStatement wrapExpressionStatement(Expression expression) {
  return new ExpressionStatement(expression);
}

TextSerializer<ReturnStatement> returnStatementSerializer = new Wrapped(
    unwrapReturnStatement, wrapReturnStatement, expressionSerializer);

Expression unwrapReturnStatement(ReturnStatement statement) {
  return statement.expression;
}

ReturnStatement wrapReturnStatement(Expression expression) {
  return new ReturnStatement(expression);
}

TextSerializer<ReturnStatement> returnVoidStatementSerializer = new Wrapped(
    unwrapReturnVoidStatement, wrapReturnVoidStatement, const Nothing());

void unwrapReturnVoidStatement(void ignored) {}

ReturnStatement wrapReturnVoidStatement(void ignored) => new ReturnStatement();

TextSerializer<YieldStatement> yieldStatementSerializer =
    new Wrapped(unwrapYieldStatement, wrapYieldStatement, expressionSerializer);

Expression unwrapYieldStatement(YieldStatement node) => node.expression;

YieldStatement wrapYieldStatement(Expression expression) {
  return new YieldStatement(expression);
}

TextSerializer<AssertStatement> assertStatementSerializer = Wrapped(
    (a) => Tuple2(a.condition, a.message),
    (t) => AssertStatement(t.first, message: t.second),
    Tuple2Serializer(expressionSerializer, Optional(expressionSerializer)));

TextSerializer<Block> blockSerializer =
    new Wrapped(unwrapBlock, wrapBlock, const BlockSerializer());

List<Statement> unwrapBlock(Block node) => node.statements;

Block wrapBlock(List<Statement> statements) => new Block(statements);

TextSerializer<AssertBlock> assertBlockSerializer =
    new Wrapped(unwrapAssertBlock, wrapAssertBlock, const BlockSerializer());

List<Statement> unwrapAssertBlock(AssertBlock node) => node.statements;

AssertBlock wrapAssertBlock(List<Statement> statements) =>
    new AssertBlock(statements);

/// Serializer for [Block]s.
///
/// [BlockSerializer] is a combination of [ListSerializer] and [Bind].  As in
/// the case of [ListSerializer], [BlockSerializer] is a sequence of statements.
/// As in the case of [Bind], a statement in a block can be a
/// [VariableDeclaration] introducing binders that are bound in the rest of the
/// statements in the block.  Effectively, [BlockSerializer] could have been
/// expressed in terms of [ListSerializer] and [Bind], but that would transform
/// blocks like {stmt1; stmt2; stmt3;} into {stmt1; {stmt2; {stmt3; {}}}} via
/// the round-trip, and an extra pass will be required to flatten the
/// unnecessary nested blocks.  Instead, [BlockSerializer] is implemented
/// without direct invocations of either [ListSerializer] or [Bind], but with a
/// certain internal correspondence to how they work.
class BlockSerializer extends TextSerializer<List<Statement>> {
  const BlockSerializer();

  List<Statement> readFrom(
      Iterator<Object> stream, DeserializationState state) {
    if (stream.current is! Iterator) {
      throw StateError("Expected a list, found an atom: '${stream.current}'.");
    }
    Iterator<Object> list = stream.current;
    list.moveNext();
    List<Statement> result = [];
    DeserializationState currentState = state;
    while (list.current != null) {
      currentState = new DeserializationState(
          new DeserializationEnvironment(currentState.environment),
          currentState.nameRoot);
      result.add(statementSerializer.readFrom(list, currentState));
      currentState.environment.extend();
    }
    stream.moveNext();
    return result;
  }

  void writeTo(StringBuffer buffer, List<Statement> statements,
      SerializationState state) {
    buffer.write('(');
    SerializationState currentState = state;
    for (int i = 0; i < statements.length; ++i) {
      if (i != 0) buffer.write(' ');
      currentState = new SerializationState(
          new SerializationEnvironment(currentState.environment));
      statementSerializer.writeTo(buffer, statements[i], currentState);
      currentState.environment.extend();
    }
    buffer.write(')');
  }
}

TextSerializer<IfStatement> ifStatementSerializer = new Wrapped(
    unwrapIfStatement,
    wrapIfStatement,
    Tuple2Serializer(expressionSerializer, statementSerializer));

Tuple2<Expression, Statement> unwrapIfStatement(IfStatement node) {
  return new Tuple2(node.condition, node.then);
}

IfStatement wrapIfStatement(Tuple2<Expression, Statement> tuple) {
  return new IfStatement(tuple.first, tuple.second, null);
}

TextSerializer<IfStatement> ifElseStatementSerializer = new Wrapped(
    unwrapIfElseStatement,
    wrapIfElseStatement,
    Tuple3Serializer(
        expressionSerializer, statementSerializer, statementSerializer));

Tuple3<Expression, Statement, Statement> unwrapIfElseStatement(
    IfStatement node) {
  return new Tuple3(node.condition, node.then, node.otherwise);
}

IfStatement wrapIfElseStatement(
    Tuple3<Expression, Statement, Statement> tuple) {
  return new IfStatement(tuple.first, tuple.second, tuple.third);
}

TextSerializer<EmptyStatement> emptyStatementSerializer =
    new Wrapped(unwrapEmptyStatement, wrapEmptyStatement, const Nothing());

void unwrapEmptyStatement(EmptyStatement node) {}

EmptyStatement wrapEmptyStatement(void ignored) => new EmptyStatement();

TextSerializer<WhileStatement> whileStatementSerializer = new Wrapped(
    unwrapWhileStatement,
    wrapWhileStatement,
    new Tuple2Serializer(expressionSerializer, statementSerializer));

Tuple2<Expression, Statement> unwrapWhileStatement(WhileStatement node) {
  return new Tuple2(node.condition, node.body);
}

WhileStatement wrapWhileStatement(Tuple2<Expression, Statement> tuple) {
  return new WhileStatement(tuple.first, tuple.second);
}

TextSerializer<DoStatement> doStatementSerializer = new Wrapped(
    unwrapDoStatement,
    wrapDoStatement,
    new Tuple2Serializer(statementSerializer, expressionSerializer));

Tuple2<Statement, Expression> unwrapDoStatement(DoStatement node) {
  return new Tuple2(node.body, node.condition);
}

DoStatement wrapDoStatement(Tuple2<Statement, Expression> tuple) {
  return new DoStatement(tuple.first, tuple.second);
}

TextSerializer<ForStatement> forStatementSerializer = new Wrapped(
    unwrapForStatement,
    wrapForStatement,
    new Bind(
        ListSerializer(variableDeclarationSerializer),
        new Tuple3Serializer(expressionSerializer,
            new ListSerializer(expressionSerializer), statementSerializer)));

Tuple2<List<VariableDeclaration>,
        Tuple3<Expression, List<Expression>, Statement>>
    unwrapForStatement(ForStatement node) {
  return new Tuple2(
      node.variables, new Tuple3(node.condition, node.updates, node.body));
}

ForStatement wrapForStatement(
    Tuple2<List<VariableDeclaration>,
            Tuple3<Expression, List<Expression>, Statement>>
        tuple) {
  return new ForStatement(
      tuple.first, tuple.second.first, tuple.second.second, tuple.second.third);
}

TextSerializer<ForInStatement> forInStatementSerializer = new Wrapped(
    unwrapForInStatement,
    wrapForInStatement,
    new Tuple2Serializer(expressionSerializer,
        new Bind(variableDeclarationSerializer, statementSerializer)));

Tuple2<Expression, Tuple2<VariableDeclaration, Statement>> unwrapForInStatement(
    ForInStatement node) {
  return new Tuple2(node.iterable, new Tuple2(node.variable, node.body));
}

ForInStatement wrapForInStatement(
    Tuple2<Expression, Tuple2<VariableDeclaration, Statement>> tuple) {
  return new ForInStatement(
      tuple.second.first, tuple.first, tuple.second.second);
}

TextSerializer<ForInStatement> awaitForInStatementSerializer = new Wrapped(
    unwrapForInStatement,
    wrapAwaitForInStatement,
    new Tuple2Serializer(expressionSerializer,
        new Bind(variableDeclarationSerializer, statementSerializer)));

ForInStatement wrapAwaitForInStatement(
    Tuple2<Expression, Tuple2<VariableDeclaration, Statement>> tuple) {
  return new ForInStatement(
      tuple.second.first, tuple.first, tuple.second.second,
      isAsync: true);
}

TextSerializer<LabeledStatement> labeledStatementSerializer =
    Wrapped<Tuple2<LabeledStatement, Statement>, LabeledStatement>(
        (ls) => Tuple2(ls, ls.body),
        (t) => t.first..body = t.second,
        Bind(
            Wrapped(
                (ls) => Tuple2("L", ls),
                (t) => t.second,
                Binder(Wrapped(
                    (_) => null, (_) => LabeledStatement(null), Nothing()))),
            statementSerializer));

TextSerializer<BreakStatement> breakSerializer = new Wrapped(
    unwrapBreakStatement,
    wrapBreakStatement,
    const ScopedUse<LabeledStatement>());

LabeledStatement unwrapBreakStatement(BreakStatement node) {
  return node.target;
}

BreakStatement wrapBreakStatement(LabeledStatement node) {
  return new BreakStatement(node);
}

Case<Statement> statementSerializer =
    new Case.uninitialized(const StatementTagger());

class FunctionNodeTagger implements Tagger<FunctionNode> {
  const FunctionNodeTagger();

  String tag(FunctionNode node) {
    switch (node.asyncMarker) {
      case AsyncMarker.Async:
        return "async";
      case AsyncMarker.Sync:
        return "sync";
      case AsyncMarker.AsyncStar:
        return "async-star";
      case AsyncMarker.SyncStar:
        return "sync-star";
      case AsyncMarker.SyncYielding:
        return "sync-yielding";
    }
    throw new UnsupportedError("${node.asyncMarker}");
  }
}

TextSerializer<FunctionNode> syncFunctionNodeSerializer = new Wrapped(
    unwrapFunctionNode,
    wrapSyncFunctionNode,
    new Bind(
        new Rebind(
            typeParametersSerializer,
            new Tuple3Serializer(
                new ListSerializer(variableDeclarationSerializer),
                new ListSerializer(variableDeclarationSerializer),
                new ListSerializer(variableDeclarationSerializer))),
        new Tuple2Serializer(dartTypeSerializer, statementSerializer)));

Tuple2<
    Tuple2<
        List<TypeParameter>,
        Tuple3<List<VariableDeclaration>, List<VariableDeclaration>,
            List<VariableDeclaration>>>,
    Tuple2<DartType, Statement>> unwrapFunctionNode(FunctionNode node) {
  return new Tuple2(
      new Tuple2(
          node.typeParameters,
          new Tuple3(
              node.positionalParameters.sublist(0, node.requiredParameterCount),
              node.positionalParameters.sublist(node.requiredParameterCount),
              node.namedParameters)),
      new Tuple2(node.returnType, node.body));
}

FunctionNode wrapSyncFunctionNode(
    Tuple2<
            Tuple2<
                List<TypeParameter>,
                Tuple3<List<VariableDeclaration>, List<VariableDeclaration>,
                    List<VariableDeclaration>>>,
            Tuple2<DartType, Statement>>
        tuple) {
  return new FunctionNode(tuple.second.second,
      typeParameters: tuple.first.first,
      positionalParameters:
          tuple.first.second.first + tuple.first.second.second,
      namedParameters: tuple.first.second.third,
      requiredParameterCount: tuple.first.second.first.length,
      returnType: tuple.second.first,
      asyncMarker: AsyncMarker.Sync);
}

TextSerializer<FunctionNode> asyncFunctionNodeSerializer = new Wrapped(
    unwrapFunctionNode,
    wrapAsyncFunctionNode,
    new Bind(
        new Rebind(
            typeParametersSerializer,
            new Tuple3Serializer(
                new ListSerializer(variableDeclarationSerializer),
                new ListSerializer(variableDeclarationSerializer),
                new ListSerializer(variableDeclarationSerializer))),
        new Tuple2Serializer(dartTypeSerializer, statementSerializer)));

FunctionNode wrapAsyncFunctionNode(
    Tuple2<
            Tuple2<
                List<TypeParameter>,
                Tuple3<List<VariableDeclaration>, List<VariableDeclaration>,
                    List<VariableDeclaration>>>,
            Tuple2<DartType, Statement>>
        tuple) {
  return new FunctionNode(tuple.second.second,
      typeParameters: tuple.first.first,
      positionalParameters:
          tuple.first.second.first + tuple.first.second.second,
      namedParameters: tuple.first.second.third,
      requiredParameterCount: tuple.first.second.first.length,
      returnType: tuple.second.first,
      asyncMarker: AsyncMarker.Async);
}

TextSerializer<FunctionNode> syncStarFunctionNodeSerializer = new Wrapped(
    unwrapFunctionNode,
    wrapSyncStarFunctionNode,
    new Bind(
        new Rebind(
            typeParametersSerializer,
            new Tuple3Serializer(
                new ListSerializer(variableDeclarationSerializer),
                new ListSerializer(variableDeclarationSerializer),
                new ListSerializer(variableDeclarationSerializer))),
        new Tuple2Serializer(dartTypeSerializer, statementSerializer)));

FunctionNode wrapSyncStarFunctionNode(
    Tuple2<
            Tuple2<
                List<TypeParameter>,
                Tuple3<List<VariableDeclaration>, List<VariableDeclaration>,
                    List<VariableDeclaration>>>,
            Tuple2<DartType, Statement>>
        tuple) {
  return new FunctionNode(tuple.second.second,
      typeParameters: tuple.first.first,
      positionalParameters:
          tuple.first.second.first + tuple.first.second.second,
      namedParameters: tuple.first.second.third,
      requiredParameterCount: tuple.first.second.first.length,
      returnType: tuple.second.first,
      asyncMarker: AsyncMarker.SyncStar);
}

TextSerializer<FunctionNode> asyncStarFunctionNodeSerializer = new Wrapped(
    unwrapFunctionNode,
    wrapAsyncStarFunctionNode,
    new Bind(
        new Rebind(
            typeParametersSerializer,
            new Tuple3Serializer(
                new ListSerializer(variableDeclarationSerializer),
                new ListSerializer(variableDeclarationSerializer),
                new ListSerializer(variableDeclarationSerializer))),
        new Tuple2Serializer(dartTypeSerializer, statementSerializer)));

FunctionNode wrapAsyncStarFunctionNode(
    Tuple2<
            Tuple2<
                List<TypeParameter>,
                Tuple3<List<VariableDeclaration>, List<VariableDeclaration>,
                    List<VariableDeclaration>>>,
            Tuple2<DartType, Statement>>
        tuple) {
  return new FunctionNode(tuple.second.second,
      typeParameters: tuple.first.first,
      positionalParameters:
          tuple.first.second.first + tuple.first.second.second,
      namedParameters: tuple.first.second.third,
      requiredParameterCount: tuple.first.second.first.length,
      returnType: tuple.second.first,
      asyncMarker: AsyncMarker.AsyncStar);
}

TextSerializer<FunctionNode> syncYieldingStarFunctionNodeSerializer =
    new Wrapped(
        unwrapFunctionNode,
        wrapSyncYieldingFunctionNode,
        new Bind(
            new Rebind(
                typeParametersSerializer,
                new Tuple3Serializer(
                    new ListSerializer(variableDeclarationSerializer),
                    new ListSerializer(variableDeclarationSerializer),
                    new ListSerializer(variableDeclarationSerializer))),
            new Tuple2Serializer(dartTypeSerializer, statementSerializer)));

FunctionNode wrapSyncYieldingFunctionNode(
    Tuple2<
            Tuple2<
                List<TypeParameter>,
                Tuple3<List<VariableDeclaration>, List<VariableDeclaration>,
                    List<VariableDeclaration>>>,
            Tuple2<DartType, Statement>>
        tuple) {
  return new FunctionNode(tuple.second.second,
      typeParameters: tuple.first.first,
      positionalParameters:
          tuple.first.second.first + tuple.first.second.second,
      namedParameters: tuple.first.second.third,
      requiredParameterCount: tuple.first.second.first.length,
      returnType: tuple.second.first,
      asyncMarker: AsyncMarker.SyncYielding);
}

Case<FunctionNode> functionNodeSerializer =
    new Case.uninitialized(const FunctionNodeTagger());

class ProcedureTagger implements Tagger<Procedure> {
  const ProcedureTagger();

  String tag(Procedure node) {
    String prefix = node.isStatic ? "static-" : "";
    switch (node.kind) {
      case ProcedureKind.Method:
        return "${prefix}method";
      default:
        throw new UnsupportedError("${node.kind}");
    }
  }
}

TextSerializer<Procedure> staticMethodSerializer = new Wrapped(
    unwrapStaticMethod,
    wrapStaticMethod,
    new Tuple2Serializer(nameSerializer, functionNodeSerializer));

Tuple2<Name, FunctionNode> unwrapStaticMethod(Procedure procedure) {
  return new Tuple2(procedure.name, procedure.function);
}

Procedure wrapStaticMethod(Tuple2<Name, FunctionNode> tuple) {
  return new Procedure(tuple.first, ProcedureKind.Method, tuple.second,
      isStatic: true);
}

Case<Procedure> procedureSerializer =
    new Case.uninitialized(const ProcedureTagger());

class LibraryTagger implements Tagger<Library> {
  const LibraryTagger();

  String tag(Library node) {
    return node.isNonNullableByDefault ? "null-safe" : "legacy";
  }
}

TextSerializer<Library> libraryContentsSerializer = new Wrapped(
  unwrapLibraryNode,
  wrapLibraryNode,
  new Tuple2Serializer(
      const UriSerializer(), new ListSerializer(procedureSerializer)),
);

Tuple2<Uri, List<Procedure>> unwrapLibraryNode(Library library) {
  return new Tuple2(library.importUri, library.procedures);
}

Library wrapLibraryNode(Tuple2<Uri, List<Procedure>> tuple) {
  return new Library(tuple.first, procedures: tuple.second);
}

Case<Library> librarySerializer = new Case.uninitialized(const LibraryTagger());

class ShowHideTagger implements Tagger<Combinator> {
  String tag(Combinator node) => node.isShow ? "show" : "hide";
}

TextSerializer<Combinator> showSerializer = Wrapped(
    (c) => c.names, (ns) => Combinator(true, ns), ListSerializer(DartString()));

TextSerializer<Combinator> hideSerializer = Wrapped((c) => c.names,
    (ns) => Combinator(false, ns), ListSerializer(DartString()));

Case<Combinator> showHideSerializer = new Case(ShowHideTagger(), {
  "show": showSerializer,
  "hide": hideSerializer,
});

TextSerializer<LibraryDependency> libraryDependencySerializer = Wrapped(
    (ld) => Tuple5(ld.importedLibraryReference.canonicalName, ld.name,
        ld.combinators, ld.flags, ld.annotations),
    (t) => LibraryDependency.byReference(
        t.fourth, t.fifth, t.first.getReference(), t.second, t.third),
    Tuple5Serializer(
        CanonicalNameSerializer(),
        Optional(DartString()),
        ListSerializer(showHideSerializer),
        DartInt(),
        ListSerializer(expressionSerializer)));

class ConstantTagger extends ConstantVisitor<String>
    implements Tagger<Constant> {
  const ConstantTagger();

  String tag(Constant node) => node.accept(this);

  String visitBoolConstant(BoolConstant node) => "const-bool";
  String visitDoubleConstant(DoubleConstant node) => "const-double";
  String visitInstanceConstant(InstanceConstant node) => "const-object";
  String visitIntConstant(IntConstant node) => "const-int";
  String visitListConstant(ListConstant node) => "const-list";
  String visitMapConstant(MapConstant node) => "const-map";
  String visitNullConstant(NullConstant node) => "const-null";
  String visitPartialInstantiationConstant(PartialInstantiationConstant node) =>
      "const-apply";
  String visitSetConstant(SetConstant node) => "const-set";
  String visitStringConstant(StringConstant node) => "const-string";
  String visitSymbolConstant(SymbolConstant node) => "const-symbol";
  String visitTearOffConstant(TearOffConstant node) => "const-tearoff";
  String visitTypeLiteralConstant(TypeLiteralConstant node) => "const-type";
  String visitUnevaluatedConstant(UnevaluatedConstant node) => "const-expr";
}

TextSerializer<BoolConstant> boolConstantSerializer =
    Wrapped((w) => w.value, (u) => BoolConstant(u), DartBool());

TextSerializer<DoubleConstant> doubleConstantSerializer =
    Wrapped((w) => w.value, (u) => DoubleConstant(u), DartDouble());

TextSerializer<IntConstant> intConstantSerializer =
    Wrapped((w) => w.value, (u) => IntConstant(u), DartInt());

TextSerializer<ListConstant> listConstantSerializer = Wrapped(
    (w) => Tuple2(w.typeArgument, w.entries),
    (u) => ListConstant(u.first, u.second),
    Tuple2Serializer(dartTypeSerializer, ListSerializer(constantSerializer)));

TextSerializer<MapConstant> mapConstantSerializer = Wrapped(
    (w) => Tuple3(w.keyType, w.valueType, w.entries),
    (u) => MapConstant(u.first, u.second, u.third),
    Tuple3Serializer(
        dartTypeSerializer,
        dartTypeSerializer,
        Zip(
            Tuple2Serializer(ListSerializer(constantSerializer),
                ListSerializer(constantSerializer)),
            (k, v) => ConstantMapEntry(k, v),
            (z) => Tuple2(z.key, z.value))));

TextSerializer<NullConstant> nullConstantSerializer =
    Wrapped((w) => null, (u) => NullConstant(), Nothing());

TextSerializer<PartialInstantiationConstant>
    partialInstantiationConstantSerializer = Wrapped(
        (w) => Tuple2(w.tearOffConstant, w.types),
        (u) => PartialInstantiationConstant(u.first, u.second),
        Tuple2Serializer(
            tearOffConstantSerializer, ListSerializer(dartTypeSerializer)));

TextSerializer<SetConstant> setConstantSerializer = Wrapped(
    (w) => Tuple2(w.typeArgument, w.entries),
    (u) => SetConstant(u.first, u.second),
    Tuple2Serializer(dartTypeSerializer, ListSerializer(constantSerializer)));

TextSerializer<StringConstant> stringConstantSerializer =
    Wrapped((w) => w.value, (u) => StringConstant(u), DartString());

TextSerializer<SymbolConstant> symbolConstantSerializer = Wrapped(
    (w) => Tuple2(w.name, w.libraryReference?.canonicalName),
    (u) => SymbolConstant(u.first, u.second?.getReference()),
    Tuple2Serializer(DartString(), Optional(CanonicalNameSerializer())));

TextSerializer<TearOffConstant> tearOffConstantSerializer = Wrapped(
    (w) => w.procedureReference.canonicalName,
    (u) => TearOffConstant.byReference(u.getReference()),
    CanonicalNameSerializer());

TextSerializer<TypeLiteralConstant> typeLiteralConstantSerializer =
    Wrapped((w) => w.type, (u) => TypeLiteralConstant(u), dartTypeSerializer);

TextSerializer<UnevaluatedConstant> unevaluatedConstantSerializer = Wrapped(
    (w) => w.expression, (u) => UnevaluatedConstant(u), expressionSerializer);

TextSerializer<InstanceConstant> instanceConstantSerializer =
    Wrapped<
            Tuple4<CanonicalName, List<DartType>, List<CanonicalName>,
                List<Constant>>,
            InstanceConstant>(
        (w) => Tuple4(
            w.classReference.canonicalName,
            w.typeArguments,
            w.fieldValues.keys.map((r) => r.canonicalName).toList(),
            w.fieldValues.values.toList()),
        (u) => InstanceConstant(u.first.getReference(), u.second,
            Map.fromIterables(u.third.map((c) => c.getReference()), u.fourth)),
        Tuple4Serializer(
            CanonicalNameSerializer(),
            ListSerializer(dartTypeSerializer),
            ListSerializer(CanonicalNameSerializer()),
            ListSerializer(constantSerializer)));

Case<Constant> constantSerializer = Case.uninitialized(ConstantTagger());

void initializeSerializers() {
  expressionSerializer.registerTags({
    "string": stringLiteralSerializer,
    "int": intLiteralSerializer,
    "double": doubleLiteralSerializer,
    "bool": boolLiteralSerializer,
    "null": nullLiteralSerializer,
    "invalid": invalidExpressionSerializer,
    "not": notSerializer,
    "&&": logicalAndSerializer,
    "||": logicalOrSerializer,
    "concat": stringConcatenationSerializer,
    "symbol": symbolLiteralSerializer,
    "this": thisExpressionSerializer,
    "rethrow": rethrowSerializer,
    "throw": throwSerializer,
    "await": awaitExpressionSerializer,
    "cond": conditionalExpressionSerializer,
    "is": isExpressionSerializer,
    "as": asExpressionSerializer,
    "type": typeLiteralSerializer,
    "list": listLiteralSerializer,
    "const-list": constListLiteralSerializer,
    "set": setLiteralSerializer,
    "const-set": constSetLiteralSerializer,
    "map": mapLiteralSerializer,
    "const-map": constMapLiteralSerializer,
    "let": letSerializer,
    "get-prop": propertyGetSerializer,
    "set-prop": propertySetSerializer,
    "get-super": superPropertyGetSerializer,
    "set-super": superPropertySetSerializer,
    "invoke-method": methodInvocationSerializer,
    "invoke-super": superMethodInvocationSerializer,
    "get-var": variableGetSerializer,
    "set-var": variableSetSerializer,
    "get-static": staticGetSerializer,
    "set-static": staticSetSerializer,
    "get-direct-prop": directPropertyGetSerializer,
    "set-direct-prop": directPropertySetSerializer,
    "invoke-static": staticInvocationSerializer,
    "invoke-const-static": constStaticInvocationSerializer,
    "invoke-direct-method": directMethodInvocationSerializer,
    "invoke-constructor": constructorInvocationSerializer,
    "invoke-const-constructor": constConstructorInvocationSerializer,
    "fun": functionExpressionSerializer,
    "lists": listConcatenationSerializer,
    "sets": setConcatenationSerializer,
    "maps": mapConcatenationSerializer,
    "let-block": blockExpressionSerializer,
    "apply": instantiationSerializer,
    "not-null": nullCheckSerializer,
    "with-uri": fileUriExpressionSerializer,
    "is-loaded": checkLibraryIsLoadedSerializer,
    "load": loadLibrarySerializer,
    "const": constantExpressionSerializer,
    "object": instanceCreationSerializer,
  });
  dartTypeSerializer.registerTags({
    "invalid": invalidTypeSerializer,
    "dynamic": dynamicTypeSerializer,
    "void": voidTypeSerializer,
    "bottom": bottomTypeSerializer,
    "->": functionTypeSerializer,
    "par": typeParameterTypeSerializer,
    "interface": interfaceTypeSerializer,
    "never": neverTypeSerializer,
    "typedef": typedefTypeSerializer,
    "futureor": futureOrTypeSerializer,
  });
  statementSerializer.registerTags({
    "expr": expressionStatementSerializer,
    "ret": returnStatementSerializer,
    "ret-void": returnVoidStatementSerializer,
    "yield": yieldStatementSerializer,
    "block": blockSerializer,
    "local": variableDeclarationSerializer,
    "if": ifStatementSerializer,
    "if-else": ifElseStatementSerializer,
    "skip": emptyStatementSerializer,
    "while": whileStatementSerializer,
    "do-while": doStatementSerializer,
    "for": forStatementSerializer,
    "for-in": forInStatementSerializer,
    "await-for-in": awaitForInStatementSerializer,
    "assert": assertStatementSerializer,
    "assert-block": assertBlockSerializer,
    "label": labeledStatementSerializer,
    "break": breakSerializer,
  });
  functionNodeSerializer.registerTags({
    "sync": syncFunctionNodeSerializer,
    "async": asyncFunctionNodeSerializer,
    "sync-star": syncStarFunctionNodeSerializer,
    "async-star": asyncStarFunctionNodeSerializer,
    "sync-yielding": syncYieldingStarFunctionNodeSerializer,
  });
  procedureSerializer.registerTags({"static-method": staticMethodSerializer});
  librarySerializer.registerTags({
    "legacy": libraryContentsSerializer,
    "null-safe": libraryContentsSerializer,
  });
  constantSerializer.registerTags({
    "const-bool": boolConstantSerializer,
    "const-double": doubleConstantSerializer,
    "const-int": intConstantSerializer,
    "const-list": listConstantSerializer,
    "const-map": mapConstantSerializer,
    "const-null": nullConstantSerializer,
    "const-apply": partialInstantiationConstantSerializer,
    "const-set": setConstantSerializer,
    "const-string": stringConstantSerializer,
    "const-symbol": symbolConstantSerializer,
    "const-tearoff": tearOffConstantSerializer,
    "const-type": typeLiteralConstantSerializer,
    "const-expr": unevaluatedConstantSerializer,
    "const-object": instanceConstantSerializer,
  });
}
