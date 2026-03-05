package fizzy

import (
	"context"
	"time"
)

// NoopHooks is a no-op implementation of Hooks.
// All methods are empty and designed to be inlined by the compiler,
// resulting in zero overhead when no observability is needed.
type NoopHooks struct{}

// Ensure NoopHooks implements Hooks at compile time.
var _ Hooks = NoopHooks{}

// OnOperationStart does nothing and returns the context unchanged.
func (NoopHooks) OnOperationStart(ctx context.Context, _ OperationInfo) context.Context { return ctx }

// OnOperationEnd does nothing.
func (NoopHooks) OnOperationEnd(context.Context, OperationInfo, error, time.Duration) {}

// OnRequestStart does nothing and returns the context unchanged.
func (NoopHooks) OnRequestStart(ctx context.Context, _ RequestInfo) context.Context { return ctx }

// OnRequestEnd does nothing.
func (NoopHooks) OnRequestEnd(context.Context, RequestInfo, RequestResult) {}

// OnRetry does nothing.
func (NoopHooks) OnRetry(context.Context, RequestInfo, int, error) {}
