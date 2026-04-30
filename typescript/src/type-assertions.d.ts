// Compile-time assertions for API shapes that have regressed before.
// This file is intentionally included by tsc and emits no runtime code.

import type { Column } from "./generated/services/columns.js";

type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Expect<T extends true> = T;

type _ColumnColorIsStructured = Expect<
  Equal<NonNullable<Column["color"]>, { name: string; value: string }>
>;
