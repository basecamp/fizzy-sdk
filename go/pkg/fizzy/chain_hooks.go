package fizzy

import (
	"context"
	"time"
)

// ChainHooks combines multiple Hooks implementations.
// Start events are called in order, end events are called in reverse order.
// This allows proper nesting of spans/traces.
type ChainHooks struct {
	hooks []Hooks
}

// NewChainHooks creates a ChainHooks from the given hooks.
// Nil hooks are filtered out. If all hooks are nil, returns NoopHooks.
func NewChainHooks(hooks ...Hooks) Hooks {
	filtered := make([]Hooks, 0, len(hooks))
	for _, h := range hooks {
		if h != nil {
			if _, isNoop := h.(NoopHooks); !isNoop {
				filtered = append(filtered, h)
			}
		}
	}
	if len(filtered) == 0 {
		return NoopHooks{}
	}
	if len(filtered) == 1 {
		return filtered[0]
	}
	return &ChainHooks{hooks: filtered}
}

// OnOperationStart calls all hooks in order.
func (c *ChainHooks) OnOperationStart(ctx context.Context, op OperationInfo) context.Context {
	for _, h := range c.hooks {
		ctx = h.OnOperationStart(ctx, op)
	}
	return ctx
}

// OnOperationEnd calls all hooks in reverse order.
func (c *ChainHooks) OnOperationEnd(ctx context.Context, op OperationInfo, err error, duration time.Duration) {
	for i := len(c.hooks) - 1; i >= 0; i-- {
		c.hooks[i].OnOperationEnd(ctx, op, err, duration)
	}
}

// OnRequestStart calls all hooks in order.
func (c *ChainHooks) OnRequestStart(ctx context.Context, info RequestInfo) context.Context {
	for _, h := range c.hooks {
		ctx = h.OnRequestStart(ctx, info)
	}
	return ctx
}

// OnRequestEnd calls all hooks in reverse order.
func (c *ChainHooks) OnRequestEnd(ctx context.Context, info RequestInfo, result RequestResult) {
	for i := len(c.hooks) - 1; i >= 0; i-- {
		c.hooks[i].OnRequestEnd(ctx, info, result)
	}
}

// OnRetry calls all hooks in order.
func (c *ChainHooks) OnRetry(ctx context.Context, info RequestInfo, attempt int, err error) {
	for _, h := range c.hooks {
		h.OnRetry(ctx, info, attempt, err)
	}
}

// OnOperationGate calls the first GatingHooks implementation in the chain.
func (c *ChainHooks) OnOperationGate(ctx context.Context, op OperationInfo) (context.Context, error) {
	for _, h := range c.hooks {
		if gater, ok := h.(GatingHooks); ok {
			return gater.OnOperationGate(ctx, op)
		}
	}
	return ctx, nil
}

// WithHooks sets the observability hooks for the client.
// Pass nil to disable hooks (uses NoopHooks).
func WithHooks(hooks Hooks) ClientOption {
	return func(c *Client) {
		if hooks == nil {
			c.hooks = NoopHooks{}
		} else {
			c.hooks = hooks
		}
	}
}
